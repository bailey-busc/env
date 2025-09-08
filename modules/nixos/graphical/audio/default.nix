{
  lib,
  config,
  pkgs,
  inputs,
  inputs',
  ...
}:
{
  imports = [
    inputs.audio.nixosModules.yabridgemgr
  ];
  modules.audio-nix.yabridgemgr = {
    enable = true;
    user = config.env.username;
    plugins = with inputs'.audio.packages; [
      wine-valhalla
      wine-midichordanalyzer
    ];
  };

  services.pipewire = {
    enable = true;
    socketActivation = true;
    systemWide = false;
    audio.enable = true;
    wireplumber = {
      enable = true;
      extraConfig = {
        "monitor.bluez.properties" = lib.mkIf config.hardware.bluetooth.enable {
          "bluez5.enable-sbc-xq" = true;
          "bluez5.enable-msbc" = true;
          "bluez5.enable-hw-volume" = true;
          "bluez5.roles" = [
            "hsp_hs"
            "hsp_ag"
            "hfp_hf"
            "hfp_ag"
          ];
        };
      };
      configPackages = [
        (pkgs.writeTextDir "share/wireplumber/main.lua.d/99-alsa-lowlatency.lua" ''
          alsa_monitor.rules = {
            {
              matches = {{{ "node.name", "matches", "*_*put.*" }}};
              apply_properties = {
                ["audio.format"] = "S16LE",
                ["audio.rate"] = 48000,
                -- api.alsa.headroom: defaults to 0
                ["api.alsa.headroom"] = 128,
                -- api.alsa.period-num: defaults to 2
                ["api.alsa.period-num"] = 2,
                -- api.alsa.period-size: defaults to 1024, tweak by trial-and-error
                ["api.alsa.period-size"] = 512,
                -- api.alsa.disable-batch: USB audio interface typically use the batch mode
                ["api.alsa.disable-batch"] = false,
                ["resample.quality"] = 4,
                ["resample.disable"] = false,
                ["session.suspend-timeout-seconds"] = 0,
              },
            },
          }
        '')
      ];
    };
    alsa.enable = true;
    jack.enable = true;
    pulse.enable = true;
  };
}
