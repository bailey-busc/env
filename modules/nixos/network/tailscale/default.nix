{
  config,
  lib,
  self,
  ...
}:
let
  inherit (lib) mkIf mkDefault;
  inherit (self.lib) ips;
  inherit (config.services) tailscale;
  hasTailscaleKey = config.age.secrets ? tailscale_key;
  tailscaleEnabled = tailscale.enable;
  tailscaleInterface = tailscale.interfaceName;
  tailscalePorts = [
    tailscale.port
    3478
  ];
in
{
  services = {
    tailscale = {
      enable = true;
      authKeyFile = mkIf hasTailscaleKey config.age.secrets.tailscale_key.path;
    };
    unbound.settings.server =
      let
        tailnetSuffix = "tail687fd.ts.net";
      in
      {
        local-zone = lib.flatten (
          map (hostName: [
            ''"${hostName}" redirect''
            ''"${hostName}.${tailnetSuffix}" redirect''
          ]) (builtins.attrNames ips)
        );
        local-data = lib.flatten (
          lib.mapAttrsToList (hostName: ip: [
            ''"${hostName} A ${ip}"''
            ''"${hostName}.${tailnetSuffix} A ${ip}"''
          ]) ips
        );
      };
  };
  networking.firewall = mkIf tailscaleEnabled {
    allowedUDPPorts = tailscalePorts;
    allowedTCPPorts = tailscalePorts;
    trustedInterfaces = [ tailscaleInterface ];
    checkReversePath = mkDefault "loose";
  };
}
