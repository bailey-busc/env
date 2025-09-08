{
  config,
  lib,
  pkgs,
  ...
}:

{
  services.minecraft-server = {
    enable = true;
    openFirewall = true;
    #declarative = true;
    eula = true;
  };
}
