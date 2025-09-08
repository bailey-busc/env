{
  config,
  lib,
  pkgs,
  inputs',
  ...
}:
let
  isGlimpse = config.networking.hostName == "orchid";
in
{
  config = lib.mkIf isGlimpse {
    users = {
      users.github = {
        isSystemUser = true;
        group = config.users.groups.github.name;
      };
      groups.github = { };
    };
    nix.settings = {
      allowed-users = [ config.users.users.github.name ];
      trusted-users = [ config.users.users.github.name ];
    };
    services.github-runners.${config.networking.hostName} = {
      enable = true;
      tokenFile = config.age.secrets.github_runner_token.path;
      noDefaultLabels = true;
      extraLabels = [
        "nixos"
        config.networking.hostName
      ];
      user = config.users.users.github.name;
      group = config.users.groups.github.name;
      replace = true;
      url = "https://github.com/glimpse-engineering";
      extraPackages = with pkgs; [
        config.nix.package
        inputs'.fh.packages.default # fh
        inputs'.determinate.packages.default # determinate-nixd
        git
        git-lfs
        xz
      ];
    };
  };
}
