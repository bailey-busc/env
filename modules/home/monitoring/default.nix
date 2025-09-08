{ config, pkgs, ... }:
{
  home.packages = with pkgs; [
    glances
    hardinfo2
    lshw
    procs
  ];
  programs = {
    btop = {
      enable = true;
      # TODO: https://github.com/aristocratos/btop#configurability
      settings = { };
      themes = { };
    };
    bottom = {
      enable = true;
      # TODO: https://github.com/ClementTsang/bottom/blob/master/sample_configs/default_config.toml
      settings = { };
    };
  };
}
