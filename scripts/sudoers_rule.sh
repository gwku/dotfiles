add_sudoers_rule() {
    if [[ "$ID" == "arch" || "$ID_LIKE" == "arch" ]]; then
        # Define the sudoers rule for yay and pacman
        SUDOERS_RULE="$(whoami) ALL=(ALL) NOPASSWD: /usr/bin/yay, /usr/bin/pacman"
        SUDOERS_FILE="/etc/sudoers.d/temp_yay_sudo"

        # Check if the rule already exists
        if ! sudo grep -Fxq "$SUDOERS_RULE" "$SUDOERS_FILE"; then
            # Add NOPASSWD sudoers rule for Yay and Pacman
            echo "Adding sudoers rule NOPASSWD for Yay and Pacman"
            echo "$SUDOERS_RULE" | sudo tee -a "$SUDOERS_FILE" >/dev/null
        else
            echo "Sudoers rule for Yay and Pacman already exists."
        fi
    fi
}
