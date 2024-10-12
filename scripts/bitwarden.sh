#!/usr/bin/env bash
set -euo pipefail

# Function to log in to Bitwarden
_login_to_bitwarden() {
    local attempt=1
    local max_attempts=2 # use two attempts, since the totp token could just be rotated.

    while [ "$attempt" -le "$max_attempts" ]; do
        echo "Attempting to log into Bitwarden (Attempt $attempt)..."
        TOTP=$(oathtool --totp -b "$BITWARDEN_SECRET")
        bw login "$BITWARDEN_EMAIL" "$BITWARDEN_PASSWORD" --method 0 --code "$TOTP"

        # Check if the login was successful
        if [ "$(bw status | jq -r '.status')" != "unauthenticated" ]; then
            echo "Logged into Bitwarden successfully."
            return 0
        fi

        attempt=$((attempt + 1))
    done

    echo "Login failed after $max_attempts attempts. Exiting."
    exit 1
}

# Function to unlock the Bitwarden vault
_unlock_bitwarden() {
    echo "Unlocking Bitwarden vault..."
    export BW_SESSION=$(bw unlock "$BITWARDEN_PASSWORD" --raw)
    echo "Bitwarden vault unlocked."
}

# Function to lock the Bitwarden vault
lock_bitwarden() {
    echo "Locking Bitwarden vault..."
    bw lock
    echo "Bitwarden vault is locked."
}

# Function to check Bitwarden status and handle login
_check_bitwarden_status() {
    if [ "$(bw status | jq -r '.status')" == "unauthenticated" ]; then
        login_to_bitwarden
    else
        echo "Already logged into Bitwarden."
    fi
}

# Function to ensure Bitwarden CLI installation
_ensure_bitwarden_installation() {
    # Check if Bitwarden CLI is installed
    if ! command -v bw &> /dev/null; then
        echo "Bitwarden CLI is not installed. Installing..."

        # Download Bitwarden CLI Archive
        local temp_zip="/tmp/bitwarden-cli.zip"
        local extract_dir="/tmp/bitwarden-cli"

        curl -Lo "$temp_zip" "https://vault.bitwarden.com/download/?app=cli&platform=linux"        
        mkdir -p "$extract_dir"
        unzip -o "$temp_zip" -d "$extract_dir"
        sudo mv "$extract_dir/bw" /usr/local/bin/bw
        sudo chmod +x /usr/local/bin/bw

        # Clean up downloaded files
        rm -f "$temp_zip"
        rm -rf "$extract_dir"

        echo "Bitwarden CLI installed successfully."
    else
        echo "Bitwarden CLI is already installed."
    fi
}

initialize_bitwarden(){
    _ensure_bitwarden_installation
    _check_bitwarden_status
    _unlock_bitwarden
}
