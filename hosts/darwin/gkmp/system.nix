{ ... }: {
  networking = {
    hostName = "gmbp16";
    computerName = "GMBP16";
    localHostName = "GMBP16";
  };

  nixpkgs.hostPlatform = "aarch64-darwin";
}
