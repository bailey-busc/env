{
  pkgs,
  config,
  osConfig,
  lib,
  ...
}:
let
  inherit (lib) mkIf;
in
mkIf config.env.profiles.games.enable {
  programs = {
    lutris = {
      enable = true;
      steamPackage = osConfig.programs.steam.package;
      protonPackages = with pkgs; [ proton-ge-bin ];
      extraPackages = with pkgs; [
        config.programs.mangohud.package
        winetricks
        gamescope
        gamemode
        umu-launcher
      ];
      winePackages = with pkgs; [ wineWow64Packages.full ];
      runners = {
        cemu.package = pkgs.cemu;
        pcsx2.package = pkgs.pcsx2;
        ryubing.package = pkgs.ryubing;
      };
    };
    mangohud = {
      enable = true;
      enableSessionWide = false;
      settings = {
        media_player = false;
        position = "top-right";
        cpu_mhz = true;
        cpu_temp = true;
        cpu_power = true;
        font_size = 16;
        gpu_temp = true;
        gpu_mem_temp = true;
        gpu_power = true;
        gpu_core_clock = true;
        gpu_mem_clock = true;
        io_read = true;
        io_write = true;
        procmem = true;
        ram = true;
        vram = true;
        fps_limit = [
          0
          60
          80
          100
          120
        ];
        toggle_logging = "Shift_L+F10";
        toggle_fps_limit = "Shift_L+F11";
        toggle_hud = "Shift_L+F12";
      };
    };
  };
  home.packages = with pkgs; [
    #minecraft
    (factorio.override {
      username = "bbuscarino";
      token = "d21a5f55dec70dd832f136aadd9df3";
    })
    bottles

    # winetricks (all versions)
    winetricks

    # native wayland support (unstable)
    wineWowPackages.waylandFull

    #pkgs.env.pyfa

    dxvk
    protonup-qt
    protonplus
  ];
}
