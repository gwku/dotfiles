#!/usr/bin/env bash

# Detect OS
if [[ -f /etc/os-release ]]; then
    . /etc/os-release
else
    echo "Unable to detect OS."
    exit 1
fi

# Function to install missing packages
_install_packages() {
    local packages="$1"
    if [[ "$ID" == "debian" || "$ID_LIKE" == "debian" ]]; then
        sudo apt update && sudo apt install -y $packages
    elif [[ "$ID" == "arch" || "$ID_LIKE" == "arch" ]]; then
        sudo pacman -Sy --noconfirm $packages
    else
        echo "Unsupported OS: $ID"
        exit 1
    fi
}

# Function to install binary from a zip
_install_binary_from_zip() {
    local name="$1"
    local url="$2"
    local temp_zip="/tmp/$name.zip"
    local extract_dir="/tmp/$name"

    echo "Downloading $name from $url"
    curl -Lo "$temp_zip" "$url"
    mkdir -p "$extract_dir"
    unzip -o "$temp_zip" -d "$extract_dir"
    sudo mv "$extract_dir/$name" /usr/local/bin/$name
    sudo chmod +x /usr/local/bin/$name

    # Cleanup
    rm -f "$temp_zip" && rm -rf "$extract_dir"
    echo "$name installed successfully."
}

# Process and install requirements
install_requirements() {
    local requirements_file="$1"
    
    # Check if the file exists and is readable
    if [[ ! -f "$requirements_file" || ! -r "$requirements_file" ]]; then
        echo "Error: '$requirements_file' not found or is not readable."
        exit 1
    fi

    local missing_packages=()

    while IFS= read -r entry; do
        # Ignore empty lines and comments
        [[ -z "$entry" || "$entry" =~ ^# ]] && continue

        bin=$(echo $entry | cut -d '|' -f 1)
        debian_pkg=$(echo $entry | cut -d '|' -f 2)
        arch_pkg=$(echo $entry | cut -d '|' -f 3)

        if ! command -v "$bin" &> /dev/null; then
            pkg=""
            if [[ "$ID" == "debian" || "$ID_LIKE" == "debian" ]]; then
                pkg=$debian_pkg
            elif [[ "$ID" == "arch" || "$ID_LIKE" == "arch" ]]; then
                pkg=$arch_pkg
            fi

            if [[ "$pkg" == zip* ]]; then
                url="${pkg#zip:}"
                _install_binary_from_zip "$bin" "$url"
            else
                missing_packages+=("$pkg")
            fi
        else
            echo "$bin is already installed."
        fi
    done < "$requirements_file"

    # Install all missing packages
    if [ ${#missing_packages[@]} -gt 0 ]; then
        _install_packages "${missing_packages[*]}"
    else
        echo "All specified requirements are already installed."
    fi
}