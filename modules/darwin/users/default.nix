{
  self,
  pkgs,
  lib,
  config,
  ...
}:
let
  inherit (lib) mkDefault;
  inherit (config.env) username;
in
{
  # users.users.${username} = {
  #   home = mkDefault "/Users/${username}";
  #   openssh.authorizedKeys.keys = builtins.attrValues self.lib.keys.users.${username};
  # };
}
