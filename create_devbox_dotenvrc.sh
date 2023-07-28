#!/bin/bash

# Function to create the file in the subfolder
create_envrc_in_subfolder() {
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
    create_envrc_in_subfolder "$subfolder"
done

# Create .envrc in the current folder
current_folder="$(pwd)"
create_envrc_in_subfolder "$current_folder"
