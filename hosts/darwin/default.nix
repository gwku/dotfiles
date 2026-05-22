{ username, ... }: {
  # Shared across every Darwin host.
  system.stateVersion = 5;
  system.primaryUser = username;

  # nix-darwin only manages users listed in knownUsers. Without this,
  # attributes like users.users.<name>.shell are silently ignored —
  # so fish wouldn't become the login shell on switch.
  users.knownUsers = [ username ];

  users.users.${username} = {
    name = username;
    home = "/Users/${username}";
    # uid intentionally unset — manage whatever the existing local
    # user account's UID happens to be (501 on a typical Mac, varies
    # in VMs and migrated machines).
  };
}
