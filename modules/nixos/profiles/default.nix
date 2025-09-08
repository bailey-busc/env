{
  lib,
  self,
  ...
}:
let
  inherit (lib) mkEnableOption;
  inherit (self.lib.modules) mkEnabledOpt;
in
{
  options.env.profiles = {
    graphical.enable = mkEnabledOpt "atticd and configuration";

    server = {
      attic.enable = mkEnableOption "atticd and configuration";
      open-webui.enable = mkEnableOption "open-webui and configuration";
      vscode-server.enable = mkEnableOption "openvscode-server and configuration";
    };
  };
}
