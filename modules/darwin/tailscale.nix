{ config, lib, ... }: {
  options.localMesh.magicDnsDomains = lib.mkOption {
    type = lib.types.listOf (lib.types.addCheck lib.types.str
      (domain: builtins.match "[A-Za-z0-9][A-Za-z0-9.-]*[A-Za-z0-9]" domain != null
        && builtins.stringLength domain <= 253));
    default = [ ];
    description = "Custom mesh DNS domains supplied by ignored private.local.nix; never credentials.";
  };
  config = {
    services.tailscale.enable = true;
    launchd.daemons.tailscaled.serviceConfig.KeepAlive = true;
    environment.etc = lib.listToAttrs (map (domain:
      lib.nameValuePair "resolver/${domain}" { text = "nameserver 100.100.100.100\n"; }
    ) config.localMesh.magicDnsDomains);
  };
}
