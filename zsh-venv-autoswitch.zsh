# ~/.zshrc

# Define the function to handle virtual environment management
auto_venv() {
  # Define the path where the virtual environment should be created (e.g., .venv in the project root)
  VENV_DIR=".venv"

  # Deactivate any existing virtual environment if active
  if [[ -n "$VIRTUAL_ENV" && "$VIRTUAL_ENV" != "$(pwd)/$VENV_DIR" ]]; then
    echo "Deactivating current virtual environment..."
    deactivate  # Deactivate the current environment
  fi

    # Check if a requirements.txt file exists
  if [[ -f "requirements.txt" ]]; then
    # If .venv does not exist, ask the user if they want to create it
    if [[ ! -d "$VENV_DIR" ]]; then
      read -q "REPLY?requirements.txt detected. Do you want to create a virtual environment in $VENV_DIR and install dependencies? (y/n) "
      echo  # Newline after the prompt for better formatting

      if [[ "$REPLY" == "y" || "$REPLY" == "Y" ]]; then
        echo "Creating virtual environment in $VENV_DIR..."
        python3 -m venv "$VENV_DIR"
        source "$VENV_DIR/bin/activate"
        echo "Installing dependencies from requirements.txt..."
        pip install -r requirements.txt
      else
        echo "Skipping virtual environment creation."
      fi
    else
      # If .venv exists, activate it
      echo "Activating virtual environment in $VENV_DIR..."
      source "$VENV_DIR/bin/activate"
    fi
  elif [[ -d "$VENV_DIR" ]]; then
    # If requirements.txt does not exist but .venv does, simply activate it
    echo "Activating virtual environment in $VENV_DIR..."
    source "$VENV_DIR/bin/activate"
  fi
}

# Automatically call auto_venv function on directory change
autoload -U add-zsh-hook
add-zsh-hook chpwd auto_venv

# Initialize auto_venv on startup if in a project directory
auto_venv

