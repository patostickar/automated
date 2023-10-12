#!/bin/bash

# Function to process .env.example and create/update .env file
inject_secrets() {
  local dot_env_example="$1"
  local dot_env=".env"

  # Create .env file
  cp "$dot_env_example" "$dot_env"
  # Replace 1Password secrets
  op inject --in-file "$dot_env_example" --out-file "$dot_env" -f
}

# Find all .env.example files in the current directory and its subdirectories
while IFS= read -r -d '' dot_env_example; do
  inject_secrets "$dot_env_example"
done < <(find . -type f -name ".env.example" -print0)
