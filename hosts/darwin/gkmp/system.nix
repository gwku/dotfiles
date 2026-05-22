{ user, ... }: {
  networking.hostName = "gkmp";
  networking.computerName = "${user.fullName}'s MacBook Pro";
  networking.localHostName = "GKMP";

  nixpkgs.hostPlatform = "aarch64-darwin";
}
