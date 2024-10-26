#!/usr/bin/env bash

set -euo pipefail
source ./scripts/requirements.sh
source ./scripts/bitwarden.sh
source ./scripts/validation.sh
source ./scripts/sudoers_rule.sh

# Load environment variables from the specified env file, ignoring comments
export $(grep -v '^#' "$env_file" | xargs)

# Detect OS
if [[ -f /etc/os-release ]]; then
    . /etc/os-release
else
    echo "Unable to detect OS."
    exit 1
fi

add_sudoers_rule
install_requirements requirements.txt

# Initialize Bitwarden if the skip flag is not set
if ! $skip_bitwarden; then
    initialize_bitwarden
fi

# Run the Ansible playbook with become password as variable
if ansible-playbook main.yml --extra-vars "ansible_become_password=$BECOME_PASSWORD"; then
    echo "Ansible playbook executed successfully."
else
    echo "Ansible playbook execution failed. Executing post install tasks."
fi

# Lock the Bitwarden vault after playbook execution
lock_bitwarden

# Remove env file if the flag is not set
if $remove_env_file; then
    rm "$env_file"
    echo "Removed env file: $env_file"
else
    echo "Kept env file: $env_file"
fi

remove_sudoers_rule

echo "Install script complete."
