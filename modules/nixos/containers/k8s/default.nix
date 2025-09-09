{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    kubernix
  ];
}
