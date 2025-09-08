{
  lib,
  config,
  osConfig,
  pkgs,
  ...
}:
let
  inherit (config.env) profiles;
  inherit (lib) mkIf;
  inherit (pkgs.stdenv) isLinux;
  opacity = 0.85;
  opacityHex = opacity * 255 |> builtins.ceil |> lib.toHexString;
in
mkIf (profiles.graphical.enable && isLinux) {
  services.mako = {
    # enable = true;
    settings = {
      # Behavior
      actions = true;
      icons = true;
      ignore-timeout = false;
      markup = true;
      default-timeout = 5000;
      sort = "-time";
      format = "<b>%s</b>\\n%b";

      # Positioning
      anchor = "top-right";
      layer = "overlay";

      # Size
      margin = 10;
      border-radius = 6;
      border-size = 2;
      width = 300;
      height = 100;

      # Styling
      background-color = config.scheme.withHashtag.base01 + opacityHex;
      border-color = config.scheme.withHashtag.base06 + opacityHex;
      font = "${osConfig.env.theme.fonts.widgets.name} 16";
      text-color = config.scheme.withHashtag.base04;

      "actionable=true".anchor = "top-left";
      "urgency=low".border-color = config.scheme.withHashtag.bright-blue + opacityHex;
      # "urgency=normal".border-color = config.scheme.withHashtag.bright-blue + opacityHex;
      "urgency=high" = {
        border-color = config.scheme.withHashtag.bright-red + opacityHex;
        default-timeout = 0;
      };

    };
  };
}
