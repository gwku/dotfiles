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

_sync_bitwarden() {
    echo "Syncing Bitwarden vault..."
    bw sync
    echo "Bitwarden vault synced."
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
        _login_to_bitwarden
    else
        echo "Already logged into Bitwarden."
    fi
}

initialize_bitwarden(){
    _check_bitwarden_status
    _unlock_bitwarden
    _sync_bitwarden
}
