{ pkgs, ... }:
{
  home.packages = with pkgs; [
    kubernix
  ];
}
