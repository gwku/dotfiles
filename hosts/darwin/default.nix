{ pkgs, username, ... }: {
  # Shared across every Darwin host.
  # Home Manager's nix-darwin module derives account metadata from
  # users.users. Without knownUsers nix-darwin does not own/create the
  # existing account, so no UID needs to be hard-coded.
  users.users.${username} = {
    name = username;
    home = "/Users/${username}";
  };

  system = {
    stateVersion = 7;
    primaryUser = username;

    # The account is created by macOS Setup Assistant, not nix-darwin.
    # Avoid users.knownUsers here: owning an existing macOS account would
    # require hard-coding its UID and makes VM/migrated-machine testing
    # fragile. Set its login shell idempotently after activation instead.
    activationScripts.postActivation.text = ''
      desiredShell="${pkgs.fish}/bin/fish"
      currentShell="$(/usr/bin/dscl . -read "/Users/${username}" UserShell | /usr/bin/awk '{ print $2 }')"
      if [[ "$currentShell" != "$desiredShell" ]]; then
        echo "setting ${username}'s login shell to $desiredShell" >&2
        /usr/bin/chsh -s "$desiredShell" "${username}"
      fi
    '';
  };
}
