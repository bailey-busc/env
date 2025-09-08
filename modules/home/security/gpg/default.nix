{
  pkgs,
  lib,
  config,
  ...
}:
let
  inherit (lib) mkIf mkMerge;
  inherit (pkgs.stdenv) isDarwin isLinux;
in
{
  programs.gpg = {
    enable = true;
    publicKeys = [ ];
    settings = { };
    scdaemonSettings = { };
  };

  services.gpg-agent = {
    enable = true;
    enableSshSupport = false;
    enableScDaemon = false;
    pinentry = mkMerge [
      { program = config.services.gpg-agent.pinentry.package.meta.mainProgram; }
      (mkIf isLinux {
        package = pkgs.pinentry.gnome3;
      })
      (mkIf isDarwin {
        package = pkgs.pinentry_mac;
      })
    ];
  };
}
