{ lib, config, ... }:
let
  inherit (lib)
    mkIf
    mkEnableOption
    getAttr
    flip
    genAttrs
    ;
  inherit (builtins) ;
  hostKeys = config.services.openssh.hostKeys |> map (getAttr "path");
in
{
  options.env.networking.initrd-ssh.enable = mkEnableOption "ssh in initrd via wireguard";
  config = mkIf (!config.env.deploy.fresh && config.boot.loader.supportsInitrdSecrets) {
    boot.initrd = {
      systemd.enable = true;
      secrets = genAttrs hostKeys (_: null);
      network = {
        enable = true;
        ssh =
          let
            inherit (config.users.users.${config.env.username}.openssh.authorizedKeys) keys keyFiles;
          in
          {
            enable = true;
            port = 22;
            authorizedKeys = keys;
            authorizedKeyFiles = keyFiles;
            inherit hostKeys;
          };
      };
    };
  };
}
