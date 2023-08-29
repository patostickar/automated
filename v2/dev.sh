#!/bin/bash

get_help() {
  echo "setup: install all the required dependencies in order to work with the dev environment"
  echo "make-env: to initialize a project as a dev environment"
  echo "refresh: to refresh your environment variables from the .env.example files"
  echo "help: to show this help"
}

setup() {
  echo "Checking if everything is set up to start building amazing features.."

  check_or_install_devbox
  check_or_install_direnv

  echo "All the dependencies are installed!"
}

make() {
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

refresh() {
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
      sed -i "s/^$variable_name=.*/$variable_name=$variable_value/" "$env_file"
    done < <(op run --env-file="$env_example_file" --no-masking -- printenv)
  }


  # Find all .env.example files in the current directory and its subdirectories
  while IFS= read -r -d '' env_example_file; do
    process_env_example "$env_example_file"
  done < <(find . -type f -name ".env.example" -print0)
}

check_or_install_devbox() {
    if ! devbox >/dev/null 2>&1; then
      echo "Devbox is currently not installed. Installing it.."
      curl -fsSL https://get.jetpack.io/devbox | bash
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
            echo 'eval "$(direnv hook bash)"' >> ~/.bashrc
            ;;
        "zsh")
            echo "Hooking direnv into zsh"
            echo 'eval "$(direnv hook zsh)"' >> ~/.zshrc
            ;;
        "fish")
            echo 'direnv hook fish | source' >> ~/.config/fish/config.fish
            ;;
        *)
            echo "Failed to hook direnv into shell: Unknown shell $current_shell"
            exit 1
            ;;
    esac
  fi
}

create_envrc_files() {
  # Function to create the file in the subfolder
  create() {
      local subfolder="$1"
      local file_content="# Automatically sets up your devbox environment whenever you cd into this
  # directory via our direnv integration:

  eval \"\$(devbox generate direnv --print-envrc)\"

  # check out https://www.jetpack.io/devbox/docs/ide_configuration/direnv/
  # for more details
  dotenv
  "

      echo "$file_content" > "$subfolder/.envrc"
      echo "Created '.envrc' in '$subfolder'"
  }

  # Find all subfolders containing .env.example and create the .envrc file
  find . -type f -name ".env.example" -printf '%h\n' | while read -r subfolder; do
      create "$subfolder"
  done

  # Create .envrc in the current folder
  current_folder="$(pwd)"
  create "$current_folder"
}

whitelist() {
  # Get the absolute path of the current directory
  current_dir="$(pwd)"

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
      echo "prefix = [ \"$current_dir\" ]" >> "$toml_file"
    fi
  else
    # Create the file with the new prefix
    echo "[whitelist]" >> "$toml_file"
    echo "prefix = [ \"$current_dir\" ]" >> "$toml_file"
  fi

  echo "direnv.toml file updated at ${toml_file}"
}

# Check the first argument to determine which command to run
case "$1" in
    "setup")
        setup
        ;;
    "make-env")
        make
        ;;
    "refresh")
        refresh
        ;;
    "help")
        get_help
        ;;
    *)
        echo "Unknown command: '$1'. You can type 'dev help' to read all the available commands"
        ;;
esac
