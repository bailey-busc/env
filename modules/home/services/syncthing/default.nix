{
  config,
  osConfig,
  lib,

  ...
}:
let
  inherit (lib) mkIf;
  inherit (osConfig.networking) hostName;
in
{
  services.syncthing = mkIf (hostName == "orchid") {
    enable = true;
    guiAddress = "127.0.0.1:8384";
    settings = {
      options.urAccepted = -1;
      folders = {
        "/data/media/music/Music Production" = {
          label = "Music Production";
          id = "music-production";
        };
      };
    };
  };
}
