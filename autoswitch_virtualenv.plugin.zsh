# ~/.zshrc

typeset -g VENV_DIR=".venv"

is_python_project() {
  [[ -f "requirements.txt" ]] || 
  [[ -d "src" && -f "src/**/*.py"(N) ]] ||
  [[ -f "*.py"(N) ]]
}

check_venv_ancestor() {
    local check_dir=${1:a}  # :a flag expands to absolute path
    local venv_dir=${VIRTUAL_ENV:a}
    local project_dir=${venv_dir:h}  # :h removes last path component

    [[ -z $venv_dir ]] && return 1
    [[ $check_dir/ = $project_dir/* || $check_dir = $project_dir ]] && return 0
    return 1
}

is_venv_active() {
  [[ -n "$VIRTUAL_ENV" ]]
}

install_deps() {
    local flag_file requirements_file reply
    
    is_venv_active || return 1
    
    flag_file="${VIRTUAL_ENV}/.requirements_installed"
    requirements_file="requirements.txt"
    
    [[ -f $flag_file ]] && return 0
    [[ ! -f $requirements_file ]] && return 0
    
    read -q "reply?${requirements_file} detected. Install dependencies? [y/N] "
    echo
    [[ $reply != [yY] ]] && return 1

    print "Installing dependencies from ${requirements_file}..."
    if pip install -r $requirements_file; then
        print "done" >| $flag_file
    else
        print "Failed to install dependencies" >&2
        return 1
    fi
}

create_venv() {
    local reply

    [[ -d $VENV_DIR ]] && return 0
    read -q "reply?Create virtual environment in ${VENV_DIR}? [y/N] "
    echo
    [[ $reply != [yY] ]] && return 1

    print "Creating virtual environment in ${VENV_DIR}..."
    python3 -m venv $VENV_DIR || return 1
}

activate_venv() {
    local site_packages_path

    [[ $VIRTUAL_ENV == ${VENV_DIR:a} ]] && return 0
    [[ ! -d $VENV_DIR ]] && return 1

    print "Activating virtual environment in ${VENV_DIR}..."
    source $VENV_DIR/bin/activate || return 1

    local paths=(
        $PWD
        $PWD/src
        $PWD/tests
    )
    
    if [[ -n $PYTHONPATH ]]; then
        paths+=("${(@s/:/)PYTHONPATH}")
    fi

    site_packages_path=$(find $VIRTUAL_ENV -type d -name "site-packages" -print -quit)
    if [[ -n $site_packages_path ]]; then
        paths=($site_packages_path $paths)
    fi

    export PYTHONPATH="${(j.:.)paths}"
}

deactivate_venv() {
  is_venv_active && ! check_venv_ancestor $PWD || return 0

  print "Deactivating virtual environment from ${VIRTUAL_ENV:h}..."
  deactivate
  unset PYTHONPATH
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
