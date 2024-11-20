# ~/.zshrc

check_venv_ancestor() {
  local check_dir="$1"
  local venv_path="$VIRTUAL_ENV"
  
  # If no virtual environment is active, return 1
  [[ -z "$venv_path" ]] && return 1
  
  while [[ "$check_dir" != "/" ]]; do
    if [[ "$check_dir" == "$venv_path" ]]; then
      return 0
    fi
    check_dir="$(dirname "$check_dir")"
  done
  return 1
}

# Define the function to handle virtual environment management
auto_venv() {
  # Define the path where the virtual environment should be created (e.g., .venv in the project root)
  VENV_DIR=".venv"

  # Deactivate any existing virtual environment if active
  if [[ -n "$VIRTUAL_ENV" ]]; then
    if ! check_venv_ancestor "$(pwd)"; then
      echo "Deactivating virtual environment from $(dirname "$VIRTUAL_ENV")..."
      deactivate
    fi
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

