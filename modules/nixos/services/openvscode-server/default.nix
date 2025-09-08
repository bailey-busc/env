{
  config,
  pkgs,
  lib,

  self,
  ...
}:
let
  inherit (lib) mkIf;
  inherit (self.lib) ips;
  inherit (config.env.network) wireguard;
  inherit (config.networking) hostName;
  cfg = config.env.profiles.server.vscode-server;
  userConf = config.home-manager.users.bailey;
  serverConf = config.services.openvscode-server;

  userExtensions = userConf.programs.vscode.profiles.default.extensions;
  serverExtensions = pkgs.symlinkJoin {
    name = "openvscode-server-extensons";
    paths = userExtensions ++ [
      (pkgs.writeTextDir "share/vscode/extensions/extensions.json" (
        pkgs.vscode-utils.toExtensionJson userExtensions
      ))
    ];
  };
in
{
  config = mkIf cfg.enable {
    services = {
      openvscode-server = {
        enable = true;
        host = if wireguard.enable then wireguard.self.ip else ips.${hostName};
        withoutConnectionToken = true;
        telemetryLevel = "off";
        serverDataDir = "/var/lib/openvscode-server";
        extensionsDir = "${serverConf.serverDataDir}/extensions";
        user = "bailey";
      };
    };

    systemd.tmpfiles.rules = [
      "d ${serverConf.serverDataDir} 770 ${serverConf.user} ${serverConf.group}"
      "Z ${serverConf.serverDataDir} 770 ${serverConf.user} ${serverConf.group}"
      "L+ ${serverConf.extensionsDir} - - - - ${serverExtensions}/share/vscode/extensions"
    ];
  };
}
