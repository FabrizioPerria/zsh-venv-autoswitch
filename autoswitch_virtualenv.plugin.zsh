# ~/.zshrc

typeset -g VENV_DIR=".venv"
typeset -g USE_POETRY=0

is_python_project() {
  [[ -f "pyproject.toml" ]] ||
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
    if [[ -f pyproject.toml && -n $(grep '\[tool.poetry\]' pyproject.toml) ]]; then
        USE_POETRY=1
        if [[ -z $(poetry env info --path 2>/dev/null) ]]; then
            read -q "reply?Create poetry virtual environment? [y/N] "
            echo
            [[ $reply != [yY] ]] && return 1
            print "Creating poetry virtual environment..."
            poetry env use python3 || return 1
        fi
        return 0
    fi

    [[ -d $VENV_DIR ]] && return 0
    read -q "reply?Create virtual environment in ${VENV_DIR}? [y/N] "
    echo
    [[ $reply != [yY] ]] && return 1

    print "Creating virtual environment in ${VENV_DIR}..."
    python3 -m venv $VENV_DIR || return 1
}

activate_venv() {
    local site_packages_path venv_path

    # neotest's python adapter looks for these files when discovering tests
    if [[ ! -f pytest.ini && ! -f pyproject.toml && ! -f setup.cfg && ! -f mypy.ini && ! -f setup.py ]]; then
        touch pytest.ini
    fi

    if [[ $USE_POETRY -eq 1 ]]; then
        venv_path=$(poetry env info -p 2>/dev/null)
        [[ -z $venv_path ]] && return 1
        if [[ $VIRTUAL_ENV != $venv_path ]]; then
            print "Activating poetry virtual environment..."
            source "$venv_path/bin/activate" || return 1
        fi
    else
        [[ $VIRTUAL_ENV == ${VENV_DIR:a} ]] && return 0
        [[ ! -d $VENV_DIR ]] && return 1

        print "Activating virtual environment in ${VENV_DIR}..."
        source $VENV_DIR/bin/activate || return 1
    fi

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
  USE_POETRY=0
}

auto_venv() {
  deactivate_venv
  if is_python_project; then
    create_venv
    activate_venv
    install_deps
  fi
}

add-root-dir() {
    is_venv_active || { print "No active virtual environment."; return 1; }

    local dir reply site_packages project_pth
    vared -p "Which directory do you want to add to this virtual environment? " dir
    [[ -z $dir || ! -d $dir ]] && { print "Invalid directory."; return 1; }

    site_packages=$(find "$VIRTUAL_ENV/lib" -type d -name "site-packages" -print -quit)
    [[ -z $site_packages ]] && { print "Could not find site-packages directory."; return 1; }

    project_pth="$site_packages/project.pth"
    print -r -- "$dir" >> "$project_pth"
    print "Added $dir to $project_pth"
}

autoload -U add-zsh-hook
add-zsh-hook chpwd auto_venv

auto_venv
