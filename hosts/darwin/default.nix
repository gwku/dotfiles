{ username, ... }: {
  # Shared across every Darwin host.
  system.stateVersion = 5;
  system.primaryUser = username;

  users.users.${username} = {
    name = username;
    home = "/Users/${username}";
  };
}
