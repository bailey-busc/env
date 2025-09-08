{
  pkgs,
  config,
  ...
}:
let
  inherit (pkgs.stdenv) isx86_64 isDarwin;
  inherit (pkgs.lib) mkIf mkMerge;
  inherit (config.env) profiles;
in
{
  home.packages =
    mkIf profiles.graphical.enable
    <| mkMerge (
      with pkgs;
      [
        (mkIf isx86_64 [ slack ])
        (mkIf (isx86_64 && profiles.personal.enable) [
          legcord
          dissent
          signal-desktop
          fractal
        ])
        (mkIf isDarwin [ teams ])
      ]
    );
}
