#!/usr/bin/env bash

set -euo pipefail
source ./scripts/requirements.sh
source ./scripts/bitwarden.sh
source ./scripts/validation.sh

# Load environment variables from the specified env file, ignoring comments
export $(grep -v '^#' "$env_file" | xargs)

install_requirements requirements.txt

# Initialize Bitwarden if the skip flag is not set
if ! $skip_bitwarden; then
    initialize_bitwarden
fi

# Run the Ansible playbook with become password as variable
ansible-playbook main.yml --extra-vars "ansible_become_password=$BECOME_PASSWORD"

# Lock the Bitwarden vault after playbook execution
lock_bitwarden

# Remove env file if the flag is not set
if $remove_env_file; then
    rm "$env_file"
    echo "Removed env file: $env_file"
else
    echo "Kept env file: $env_file"
fi

echo "Everything installed successfully."
