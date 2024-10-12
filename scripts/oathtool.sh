#!/usr/bin/env bash

# Function to install oathtool based on the detected OS
_install_oath() {
    echo "Updating package list..."
    if [[ -f /etc/os-release ]]; then
        . /etc/os-release
        case "$ID" in
            debian|ubuntu|lmde)
                sudo apt update && sudo apt install -y oathtool
                ;;
            arch)
                sudo pacman -Sy --noconfirm oath-toolkit
                ;;
            *)
                case "$ID_LIKE" in
                    debian*) sudo apt update && sudo apt install -y oathtool ;;
                    arch) sudo pacman -Sy --noconfirm oath-toolkit ;;
                    *) echo "Unsupported OS: $ID"; exit 1 ;;
                esac
                ;;
        esac
        echo "oathtool installed successfully."
    else
        echo "Unable to detect OS."
        exit 1
    fi
}

initialize_oathtool(){
    # Check if oathtool is installed, if not, install it
    if ! command -v oathtool &> /dev/null; then
        _install_oath
    else
        echo "oathtool is already installed."
    fi
}

