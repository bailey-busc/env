{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkDefault mkIf;
in
{
  environment.systemPackages = with pkgs; [
    # moonlander
    keymapp
    kontroll
  ];

  # Enable unfree firmware
  hardware.enableRedistributableFirmware = mkDefault true;

  services = {
    thermald.enable = true;
    logind.lidSwitchExternalPower = "ignore";
    hardware.openrgb = {
      enable = !config.env.hardware.laptop.enable;
      motherboard = "amd";
      package = pkgs.openrgb-with-all-plugins;
    };
    tlp = {
      enable = config.env.hardware.laptop.enable;
      settings = {
        CPU_BOOST_ON_AC = 1;
        CPU_BOOST_ON_BAT = 0;
        CPU_SCALING_GOVERNOR_ON_AC = "performance";
        CPU_SCALING_GOVERNOR_ON_BAT = "powersave";
        START_CHARGE_THRESH_BAT0 = 90;
        STOP_CHARGE_THRESH_BAT0 = 97;
        RUNTIME_PM_ON_BAT = "auto";
      };
    };
  };
  location.provider = mkIf config.env.hardware.laptop.enable "geoclue2";

  boot.kernelModules = [
    "i2c-dev"
    "i2c-piix4"

  ];
}
