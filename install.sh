#!/usr/bin/env bash

set -euo pipefail
source ./scripts/requirements.sh
source ./scripts/bitwarden.sh
source ./scripts/validation.sh

# Load environment variables from the specified env file, ignoring comments
export $(grep -v '^#' "$env_file" | xargs)

# Detect OS
if [[ -f /etc/os-release ]]; then
    . /etc/os-release
else
    echo "Unable to detect OS."
    exit 1
fi

# Define the sudoers rule for yay and pacman
SUDOERS_RULE="$(whoami) ALL=(ALL) NOPASSWD: /usr/bin/yay, /usr/bin/pacman"
SUDOERS_FILE="/etc/sudoers.d/temp_yay_sudo"

# Check if the rule already exists
if ! sudo grep -Fxq "$SUDOERS_RULE" "$SUDOERS_FILE"; then
    # Add NOPASSWD sudoers rule for Yay and Pacman
    echo "Adding sudoers rule NOPASSWD for Yay and Pacman"
    echo "$SUDOERS_RULE" | sudo tee -a "$SUDOERS_FILE" > /dev/null
else
    echo "Sudoers rule for Yay and Pacman already exists."
fi

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

echo "Removing sudoers rule NOPASSWD for Yay and Pacman"
sudo rm -f /etc/sudoers.d/temp_yay_sudo

echo "Everything installed successfully."
