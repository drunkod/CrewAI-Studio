{
  description = "A dev shell with Python 3 and pip";

  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";

  outputs = { self, nixpkgs }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs { inherit system; };
    in
    {
      devShells.${system}.default = pkgs.mkShell {
        buildInputs = with pkgs; [
          gcc  
          libgcc
          python312Full
          python312Packages.pip
        ];

        shellHook = ''
          export LD_LIBRARY_PATH=${pkgs.stdenv.cc.cc.lib}/lib:$LD_LIBRARY_PATH
          echo "LD_LIBRARY_PATH set to include libstdc++.so.6: $LD_LIBRARY_PATH"
          
          # Get the current directory
          SCRIPT_DIR="$PWD"
          # cd "$SCRIPT_DIR" || exit

          # Function to prompt for yes/no
          prompt_yes_no() {
            while true; do
              read -p "$1 (y/n): " yn
              case $yn in
                [Yy]* ) return 0;;
                [Nn]* ) return 1;;
                * ) echo "Please answer yes (y) or no (n).";;
              esac
            done
          }

          # Check if venv exists
          if [ -d ".venv" ]; then
            if prompt_yes_no "The virtual environment '.venv' already exists. Do you want to reinstall it?"; then
              echo "Removing existing virtual environment..."
              rm -rf .venv || { echo "Failed to remove existing venv"; exit 1; }
            else
              echo "Using existing virtual environment..."
              source .venv/bin/activate
            fi
          fi

          # Create and activate virtual environment
          echo "Setting up Python virtual environment..."
          
          python -m venv .venv || { echo "Failed to create venv"; exit 1; }
          source .venv/bin/activate

          # Prompt for cache usage
          USE_CACHE="--no-cache"
          if prompt_yes_no "Do you want to use the cache for pip installation?"; then
            USE_CACHE=""
          fi

          # Install requirements
          # pip install --upgrade pip
          pip install -r requirements.txt $USE_CACHE || { echo "Failed to install requirements"; exit 1; }
          
          pip install git+https://github.com/drunkod/crewAI-tools@main $USE_CACHE

          # Prompt for agentops installation
          if prompt_yes_no "Do you want to install agentops?"; then
            echo "Installing agentops..."
            pip install agentops || { echo "Failed to install agentops"; }
          fi

          # Check and setup .env file
          if [ ! -f "$SCRIPT_DIR/.env" ]; then
            echo ".env file does not exist. Copying .env_example to .env..."
            cp "$SCRIPT_DIR/.env_example" "$SCRIPT_DIR/.env" || { echo "Failed to create .env file"; }
          fi

          echo "Python environment is ready. Use 'deactivate' to exit the virtualenv."
          echo "Don't forget to update the .env file with your credentials."
          echo "streamlit run ./app/app.py --server.headless true"
        '';
      };
    };
}