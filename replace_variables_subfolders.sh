#!/bin/bash

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
