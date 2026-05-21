{ ... }: {
  networking.hostName = "gkmp";
  networking.computerName = "Gerwin's MacBook Pro";
  networking.localHostName = "GKMP";

  nixpkgs.hostPlatform = "aarch64-darwin";
}
