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

# Add NOPASSWD sudoers rule for Yay and Pacman, to install all packages without password
echo "Adding sudoers rule NOPASSWD for Yay and Pacman"
SUDOERS_RULE="$(whoami) ALL=(ALL) NOPASSWD: /usr/bin/yay, /usr/bin/pacman"
echo "$SUDOERS_RULE" | sudo tee -a /etc/sudoers.d/temp_yay_sudo > /dev/null

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

echo "Removing sudoers rule NOPASSWD for Yay and Pacman"
sudo rm -f /etc/sudoers.d/temp_yay_sudo

echo "Everything installed successfully."
