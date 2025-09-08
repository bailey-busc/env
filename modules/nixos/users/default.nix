{
  pkgs,
  config,
  lib,
  self,
  ...
}:
let
  inherit (lib)
    optional
    mkMerge
    mkIf
    mkDefault
    ;
  inherit (config.networking) hostName;
  uidmap = {
    iris = 1001;
    orchid = 1000;
  };
  inherit (config.env) username;
  inherit (pkgs.stdenv) isDarwin;
in
{
  users = {
    mutableUsers = lib.mkForce false;
    defaultUserShell = pkgs.zsh;
    groups = {
      storage.gid = 2000;
      glimpse.gid = 2001;
      keys = { };
    };
    users = {
      ${username} = {
        uid = uidmap.${hostName} or 1000;
        home = mkDefault "/${if isDarwin then "Users" else "home"}/${username}";
        openssh.authorizedKeys.keys = builtins.attrValues self.lib.keys.users.${username};
        # mkpasswd -m sha-512 hunter1
        hashedPassword = "$6$nqY1Nzvj$v0yCNlBxCh1yywz3d3k9CkPVVP6jn7B1yyxSOeCW8XxRJT6Y60KsjAvDvPGEgSnu.B0MNls/qOoPFAshdYn.q0";
        isNormalUser = true;
        extraGroups = lib.flatten [
          "wheel"
          "video"
          "plugdev"
          config.users.groups.keys.name
          config.users.groups.glimpse.name
          config.users.groups.storage.name
          (optional config.security.tpm2.enable "tss")
          (optional config.services.udisks2.enable "disk")
          (optional config.virtualisation.libvirtd.enable "libvirtd")
          (optional config.virtualisation.docker.enable "docker")
          (optional config.virtualisation.podman.enable "podman")
          (optional config.networking.networkmanager.enable "networkmanager")
          (optional config.services.pipewire.enable "audio")
          (optional config.services.atticd.enable config.services.atticd.group)
          (optional config.services.openvscode-server.enable config.services.openvscode-server.group)
        ];
      };
      root = {
        inherit (config.users.users.${username}) hashedPassword openssh;
      };
    };
  };
}
