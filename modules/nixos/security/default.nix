{
  pkgs,
  lib,
  config,
  ...
}:
let
  inherit (config.env) profiles;
  inherit (lib) mkIf mkMerge;
in
{
  programs = mkMerge [
    {
      gnupg.agent.enable = lib.mkForce false;
    }
    (mkIf profiles.graphical.enable {
      seahorse.enable = true;
      ssh.enableAskPassword = true;
    })
  ];

  hardware.gpgSmartcards.enable = true;
  services = {
    pcscd.enable = true;
    dbus.packages = [ pkgs.gcr ];
    udev.packages = with pkgs; [
      libu2f-host
    ];
  };
  security = {
    protectKernelImage = lib.mkForce true;
    rtkit.enable = true;
    polkit.enable = true;
    tpm2 = {
      enable = lib.mkForce true;
      pkcs11.enable = true;
      tctiEnvironment.enable = true;
    };
  };
}
