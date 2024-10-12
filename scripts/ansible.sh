#!/usr/bin/env bash

# Function to install Ansible based on the detected OS
_install_ansible() {
    echo "Updating package list..."
    if [[ -f /etc/os-release ]]; then
        . /etc/os-release
        case "$ID" in
            debian|ubuntu|lmde)
                sudo apt update && sudo apt install -y ansible
                ;;
            arch)
                sudo pacman -Sy --noconfirm ansible
                ;;
            *)
                case "$ID_LIKE" in
                    debian*) sudo apt update && sudo apt install -y ansible ;;
                    arch) sudo pacman -Sy --noconfirm ansible ;;
                    *) echo "Unsupported OS: $ID"; exit 1 ;;
                esac
                ;;
        esac
        echo "Ansible installed successfully."
    else
        echo "Unable to detect OS."
        exit 1
    fi
}

initialize_ansible(){
    # Check if Ansible is installed, if not, install it
    if ! command -v ansible &> /dev/null; then
        _install_ansible
    else
        echo "Ansible is already installed."
    fi
}

