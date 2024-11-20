# ~/.zshrc

VENV_DIR=".venv"

is_python_project() {
  [[ -f "requirements.txt" ]] || [[ -d "src" && -f "src/**/*.py"(N) ]] || [[ -f "*.py"(N) ]]
}

check_venv_ancestor() {
  local check_dir="$1"
  local venv_path="$VIRTUAL_ENV"
  
  [[ -z "$venv_path" ]] && return 1
  
  while [[ "$check_dir" != "/" ]]; do
    if [[ "$check_dir" == "$venv_path" ]]; then
      return 0
    fi
    check_dir="$(dirname "$check_dir")"
  done
  return 1
}

is_venv_active() {
  [[ -n "$VIRTUAL_ENV" ]]
}

install_deps() {
  if is_venv_active; then  # Fixed function call
    flag_file="$VIRTUAL_ENV/.requirements_installed"
    if [[ -f $flag_file ]]; then
      return
    fi

    if [[ -f "requirements.txt" ]]; then
      read -q "REPLY?requirements.txt detected. Do you want to install dependencies from requirements.txt? (y/n) "
      echo

      if [[ "$REPLY" == "y" || "$REPLY" == "Y" ]]; then
        echo "Installing dependencies from requirements.txt..."
        pip install -r requirements.txt
        echo "done" > $flag_file
      else
        echo "Skipping dependencies installation."
      fi
    fi
  fi
}

create_venv() {
  if [[ ! -d "$VENV_DIR" ]]; then
    read -q "REPLY?Virtual Environment not found. Do you want to create a virtual environment in $VENV_DIR? (y/n) "
    echo

    if [[ "$REPLY" == "y" || "$REPLY" == "Y" ]]; then
      echo "Creating virtual environment in $VENV_DIR..."
      python3 -m venv "$VENV_DIR"
    fi
  fi
}

activate_venv() {
  if [[ -d "$VENV_DIR" ]]; then
    echo "Activating virtual environment in .venv..."
    source $VENV_DIR/bin/activate
    export PYTHONPATH="$(pwd):$(pwd)/src:$(pwd)/tests:${PYTHONPATH:+:$PYTHONPATH}"
    export PYTHONPATH="$(find $VIRTUAL_ENV -type d -name "site-packages" -printf "%p:")$PYTHONPATH"
  fi
}

deactivate_venv() {
  if is_venv_active && ! check_venv_ancestor "$(pwd)"; then
    echo "Deactivating virtual environment from $(dirname "$VIRTUAL_ENV")..."
    deactivate
    export PYTHONPATH=""
  fi
}

auto_venv() {
  deactivate_venv
  if is_python_project; then
    create_venv
    activate_venv
    install_deps
  fi
}

autoload -U add-zsh-hook
add-zsh-hook chpwd auto_venv

auto_venv
