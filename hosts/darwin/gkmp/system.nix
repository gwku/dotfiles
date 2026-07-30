{ user, ... }: {
  networking = {
    hostName = "gkmp";
    computerName = "${user.fullName}'s MacBook Pro";
    localHostName = "GKMP";
  };

  nixpkgs.hostPlatform = "aarch64-darwin";
}
