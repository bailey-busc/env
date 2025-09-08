{
  lib,
  pkgs,
  config,
  osConfig,
  ...
}:
let
  inherit (lib) getExe mkIf mkMerge;
  inherit (builtins) readFile;
in
{
  programs = {
    starship = {
      enable = true;
      enableNushellIntegration = true;
      enableZshIntegration = false;
    };
    nushell = {
      enable = true;
      envFile.text = readFile ./env.nu;
      configFile.text = readFile ./config.nu;
      loginFile.text = readFile ./login.nu;
      plugins = mkMerge (
        with pkgs.nushellPlugins;
        [
          [
            formats
            highlight
            # net # Broken?
            polars
            query
            semver
            # units
          ]
          (mkIf config.programs.skim.enable [
            skim
          ])
          (mkIf osConfig.services.dbus.enable [
            # dbus
          ])
          (mkIf config.programs.git.enable [
            gstat
          ])
        ]
      );
      extraConfig = mkIf config.programs.carapace.enable ''
        $env.CARAPACE_BRIDGES = 'zsh,fish,bash,inshellisense'
        source ${
          pkgs.runCommand "carapace-nushell-config.nu" { } ''
            ${lib.getExe config.programs.carapace.package} _carapace nushell | sed 's|"/homeless-shelter|$"($env.HOME)|g' >> "$out"
          ''
        }
      '';
      shellAliases.myip = "${getExe pkgs.dig} +short myip.opendns.com @208.67.222.222 out+err>";
    };
  };
}
