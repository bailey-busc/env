{
  lib,
  config,
  pkgs,
  ...
}:
let
  inherit (lib) mkIf mkMerge;
  inherit (pkgs.stdenv) isDarwin isLinux;
in
{
  home.packages = with pkgs; [
    _1password-cli
    bitwarden-cli
  ];
  programs.rbw = {
    enable = true;
    settings = mkMerge [
      {
        email = "${config.env.username}@busc.dev";
        lock_timeout = 3600;
        sync_interval = 3600;
      }
      (mkIf isLinux {
        pinentry = pkgs.pinentry.gnome3;
      })
      (mkIf isDarwin {
        pinentry = pkgs.pinentry_mac;
      })
    ];
  };
}
