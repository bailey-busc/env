{
  inputs',
  config,
  pkgs,
  lib,
  ...
}:
let
  inherit (lib) mkIf;
  inherit (pkgs.stdenv) isLinux;
in
{
  programs = mkIf (config.env.profiles.graphical.enable && isLinux) {
    quickshell = {
      enable = true;
      package = inputs'.quickshell.packages.default.override {
        withX11 = false;
        withI3 = false;
      };
      systemd = {
        enable = true;
        target = "hyprland-session.target";
      };
    };
  };
}
