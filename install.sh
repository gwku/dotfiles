#!/usr/bin/env bash
set -euo pipefail

# Initialize variables
remove_env_file=true

# Define the options using getopt
OPTIONS=$(getopt -o k --long keep-env -n "$0" -- "$@")
if [ $? -ne 0 ]; then
    echo "Usage: $0 [--keep-env] path_to_env_file"
    exit 1
fi


# Parse the options
eval set -- "$OPTIONS"
while true; do
    case "$1" in
        -k | --keep-env)
            remove_env_file=false
            shift
            ;;
        --)
            shift
            break
            ;;
        *)
            echo "Unexpected option: $1"
            exit 1
            ;;
    esac
done

# Check if an env file is provided
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 [--keep-env] path_to_env_file"
    exit 1
fi

env_file="$1"

if [ ! -f "$env_file" ]; then
    echo "Provided env file does not exist"
    exit 1
fi

# Check if the script is run with sudo
if [ "$EUID" -ne 0 ]; then
    echo "Please run this script with sudo:"
    echo "sudo $0"
    exit 1
fi

# Load environment variables from the specified env file, ignoring comments
export $(grep -v '^#' "$env_file" | xargs)

# Initialize Ansible
source ./scripts/ansible.sh
initialize_ansible

# Initialize oathtool
source ./scripts/oathtool.sh
initialize_oathtool

# Initialize bitwarden
source ./scripts/bitwarden.sh
initialize_bitwarden

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

echo "Ansible playbook executed successfully."
