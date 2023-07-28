#!/bin/bash

# Create .env file
cp .env.example .env

# Run the command and capture its output directly in the loop
while IFS= read -r line; do
  # Extract the variable name and value from each line
  variable_name=$(echo "$line" | cut -d '=' -f 1)
  variable_value=$(echo "$line" | cut -d '=' -f 2-)

  # Update the value of the corresponding variable in the .env file
  sed -i "s/^$variable_name=.*/$variable_name=$variable_value/" .env
done < <(op run --env-file="./.env.example" --no-masking -- printenv)
