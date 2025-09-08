{
  self,
  osConfig,
  lib,
  pkgs,
  config,
  ...
}:
let
  inherit (self.lib.modules) enabled;
  inherit (pkgs.stdenv) isDarwin;
  inherit (lib) mkDefault;
in
{
  home = {
    username = mkDefault osConfig.env.username;
    homeDirectory = mkDefault "/${if isDarwin then "Users" else "home"}/${config.home.username}";
  };
  news.display = "silent";
  env = {
    username = "bailey";
    profiles = {
      base = enabled;
      dev = {
        enable = true;
        nix = enabled;
        rust = enabled;
        ai = enabled;
        cloud = enabled;
        remote = enabled;
      };
      graphical = enabled;
      personal = enabled;
      games.enable = osConfig.networking.hostName != "orchid";
    };
  };
}
