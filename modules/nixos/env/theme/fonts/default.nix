{
  config,
  lib,
  ...
}:
let
  cfg = config.env.theme.fonts;
  getAttrFromDotPath = path: lib.getAttrFromPath (lib.splitString "." path);
in
{
  fonts = {
    enableDefaultPackages = true;
    fontDir.enable = true;
    packages =
      cfg.extraFontPackages
      ++ map (name: getAttrFromDotPath "${name}.package" cfg) [
        "serif"
        "sans"
        "mono"
        "emoji"
        "terminal"
        "widgets"
        "statusBar"
        "editor.ui"
        "editor.buffer"
      ];
    fontconfig = {
      defaultFonts = {
        serif = [
          cfg.serif.name
          "DejaVu Serif"
        ];
        sansSerif = [
          cfg.sans.name
          "DejaVu Sans"
        ];
        monospace = [
          cfg.mono.name
          "DejaVu Sans Mono"
        ];
        emoji = [
          cfg.emoji.name
          "Noto Color Emoji"
        ];
      };
      hinting.enable = true;
      antialias = true;
      subpixel.lcdfilter = "default";
    };
  };
}
