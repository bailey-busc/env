{
  config,
  pkgs,
  lib,

  ...
}:
let
  inherit (lib) mkIf;
  inherit (config.env.network) wireguard;
  inherit (config.services.atticd) settings user group;
  cfg = config.env.profiles.server.attic;
in
{
  config = mkIf cfg.enable {
    systemd.tmpfiles.rules = mkIf (settings ? storage.path) [
      "d ${settings.storage.path} ${user} ${group}"
    ];
    services.atticd = {
      enable = true;
      environmentFile = config.age.secrets.atticd_env.path;
      settings = {
        listen = "${wireguard.self.ip}:8080";
        allowed-hosts = [ ];
        api-endpoint = "http://${wireguard.self.dnsName}:8080";
        storage = {
          type = "local";
          path = "/var/lib/attic";
        };
        garbage-collection = {
          interval = "12 hours";
          default-retention-period = "3 months";
        };
      };
    };
    systemd.services.atticd.after = lib.mkIf wireguard.enable [
      "wireguard-${wireguard.interfaceName}.service"
    ];
  };
}
