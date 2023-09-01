#!/bin/bash

# Define color escape codes
RESET='\e[0m'
BOLD_TEXT='\e[1m'
COLOR_GREEN='\e[32m'
COLOR_MOVEAX='\e[34m'

 echo -e "${BOLD_TEXT}Welcome to ${COLOR_MOVEAX}Moveax${RESET}${BOLD_TEXT} Software Factory${RESET}"

declare -A options=(
  ["setup"]="Install Devbox and Direnv"
  ["init"]="Initialize a project as a dev environment"
  ["install"]="Install project dev dependencies"
  ["refresh"]="Refresh environment variables from .env.example files"
  ["help"]="Show this help"
  ["exit"]="Exit"
)

option_order=("setup" "init" "install" "refresh" "help" "exit")

display_menu() {
  echo "Please choose from one of the following options:"
  for option in "${option_order[@]}"; do
    printf "${BOLD_TEXT}${COLOR_GREEN}%-8s->${RESET} %s\n" "$option" "${options[$option]}"
  done
}

execute_option() {
  echo
  case $1 in
  "setup")
    setup
    ;;
  "init")
    init
    ;;
  "install")
    install
    ;;
  "refresh")
    refresh
    ;;
  "help")
    display_menu
    ;;
  "exit")
    echo "Exiting..."
    exit 0
    ;;
  *)
    echo "Invalid option: '$1'"
    ;;
  esac
}

setup() {
  echo "Checking if everything is set up to start building amazing features.."

  check_or_install_devbox
  check_or_install_direnv

  echo "All the required packages are installed!"
}

init() {
  echo "Initializing project as a dev environment..."
  if [ -f "./devbox.json" ]; then
    echo "Skipping make: the project is already a devbox environment"
    return
  fi

  check_or_install_devbox
  check_or_install_direnv

  devbox init

  create_envrc_files
  whitelist

  refresh
}

install() {
  echo "Installing project devbox packages"
  devbox install
}

refresh() {
  echo "Refreshing environment variables from .env.example files..."
  eval $(op signin)

  # Flag to track if any .env.example files were found
  found_env_examples=false

  # Function to process .env.example and create/update .env file
  process_env_example() {
    local env_example_file="$1"
    local env_file="${env_example_file%.example}"

    # Create .env file
    cp "$env_example_file" "$env_file"

    # Run the command and capture its output directly in the loop
    while IFS= read -r line; do
      # Extract the variable name and value from each line
      variable_name=$(echo "$line" | cut -d '=' -f 1)
      variable_value=$(echo "$line" | cut -d '=' -f 2-)

      # Update the value of the corresponding variable in the .env file
      sed -i 's%^'"$variable_name"'.*%'"$variable_name=$variable_value"'%' "$env_file"
    done < <(op run --env-file="$env_example_file" --no-masking -- printenv)
  }

  # Find all .env.example files in the current directory and its subdirectories
  while IFS= read -r -d '' env_example_file; do
    found_env_examples=true
    process_env_example "$env_example_file"
  done < <(find . -type f -name ".env.example" -print0)

  # Check if any .env.example files were found and processed
  if [ "$found_env_examples" = true ]; then
    echo "Environment variables refreshed from .env.example files."
  else
    echo "No .env.example files were found."
  fi
}

check_or_install_devbox() {
  if ! devbox >/dev/null 2>&1; then
    echo "Devbox is currently not installed. Installing it.."
    curl -fsSL https://get.jetpack.io/devbox | bash
  else
    echo "Devbox is already installed."
  fi
}

check_or_install_direnv() {
  if ! direnv >/dev/null 2>&1; then
    echo "Direnv is currently not installed. Installing it.."

    curl -sfL https://direnv.net/install.sh | bash
    current_shell=$(basename "$SHELL")

    case "$current_shell" in
    "bash")
      echo "Hooking direnv into bash"
      echo 'eval "$(direnv hook bash)"' >>~/.bashrc
      ;;
    "zsh")
      echo "Hooking direnv into zsh"
      echo 'eval "$(direnv hook zsh)"' >>~/.zshrc
      ;;
    "fish")
      echo 'direnv hook fish | source' >>~/.config/fish/config.fish
      ;;
    *)
      echo "Failed to hook direnv into shell: Unknown shell $current_shell"
      exit 1
      ;;
    esac
  else
    echo "Direnv is already installed."
  fi
}

create_envrc_files() {
  # Function to create the file in the subfolder
  echo "Creating '.envrc' files in project folders"

  create() {

    local subfolder="$1"
    local file_content="# Automatically sets up your devbox environment whenever you cd into this
  # directory via our direnv integration:

  eval \"\$(devbox generate direnv --print-envrc)\"

  # check out https://www.jetpack.io/devbox/docs/ide_configuration/direnv/
  # for more details
  dotenv
  "

    echo "$file_content" >"$subfolder/.envrc"
    echo "Created '.envrc' in '$subfolder'"
  }

  # Find all subfolders containing .env.example and create the .envrc file
  find . -type f -name ".env.example" -printf '%h\n' | while read -r subfolder; do
    create "$subfolder"
  done

  # Create .envrc in the current folder
  current_folder="$(pwd)"
  create "$current_folder"

  echo "'.envrc' files created"
}

whitelist() {
  # Get the absolute path of the current directory
  current_dir="$(pwd)"

  echo "Adding $current_dir to direnv whitelist"

  # Set the path to the direnv.toml file
  toml_file="${HOME}/.config/direnv/config.toml"

  # Create the direnv directory if it doesn't exist
  mkdir -p "$(dirname "$toml_file")"

  # Check if the file exists
  if [ -f "$toml_file" ]; then
    # Check if the prefix is already present
    if grep -q "prefix = \[" "$toml_file"; then
      # Check if the current directory is already in the list
      if grep -q "\"$current_dir\"" "$toml_file"; then
        echo "Directory already in the prefix list."
        exit 0
      fi

      # Append the new prefix to the existing list
      sed -i "s|\(prefix = \[.*\)\]|\\1, \"$current_dir\"\\]|" "$toml_file"
    else
      # Add the new prefix section
      echo "prefix = [ \"$current_dir\" ]" >>"$toml_file"
    fi
  else
    # Create the file with the new prefix
    echo "[whitelist]" >>"$toml_file"
    echo "prefix = [ \"$current_dir\" ]" >>"$toml_file"
  fi

  echo "direnv.toml file updated at ${toml_file}"
}

main_loop() {
  while true; do
    display_menu
    read -p "Option: " choice
    execute_option "$choice"
    echo
  done
}

main_loop
