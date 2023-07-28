#!/bin/bash

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