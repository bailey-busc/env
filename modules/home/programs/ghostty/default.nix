{
  config,
  lib,
  osConfig,
  ...
}:
let
  inherit (lib) mkIf mkForce;
  inherit (config.env) profiles;
  inherit (osConfig.env) theme;
in
mkIf profiles.graphical.enable {
  programs.ghostty = {
    enable = true;
    enableZshIntegration = true;
    clearDefaultKeybinds = true;
    settings = {
      font-family = theme.fonts.terminal.name;
      font-style = "Light";
      font-style-italic = "Light Italic";
      font-style-bold-italic = "SemiBold Italic";
      font-style-bold = "SemiBold";
      auto-update = "off";
      macos-titlebar-style = "hidden";
      background = config.scheme.base01;
      foreground = config.scheme.base04;
      selection-background = config.scheme.base00;
      selection-foreground = config.scheme.base06;
      cursor-style = mkForce "bar";
      cursor-color = config.scheme.base07;
      cursor-click-to-move = true;
      desktop-notifications = true;
      keybind = [
        "ctrl+shift+c=copy_to_clipboard"
        "ctrl+shift+v=paste_from_clipboard"
      ];
    };
  };
}
