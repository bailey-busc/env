{
  self,
  pkgs,
  lib,
  config,
  inputs',
  ...
}:

lib.mkIf config.env.profiles.graphical.enable {

}
