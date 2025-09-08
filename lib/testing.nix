{ inputs, ... }:
let
  inherit (inputs.self.lib.flake)
    collectHmModules
    collectNixOSModules
    ;
in
{
  mkNixosTest =
    nixpkgs:
    {
      name,
      machine,
      modules,
      testScript,
      includeInputModules ? true,
      setupHomeManager ? true,
      hmModules ? [ ],
      hmUsername ? "bailey",
      ...
    }:
    nixpkgs.testers.runNixOSTest (
      { ... }: # Args from nixpkgs callPackage
      {
        inherit name testScript;
        nodes.${machine} =
          { lib, ... }:
          let
            inherit (lib) optionals flatten;
            hmNixosModules = (
              optionals setupHomeManager [
                inputs.home-manager.nixosModules.home-manager
                ({
                  home-manager.users.${hmUsername} = {
                    imports =
                      hmModules
                      ++ [ { home.stateVersion = "23.05"; } ]
                      ++ (
                        optionals includeInputModules
                        <| collectHmModules [
                          "nix-colors"
                        ]
                      );

                  };
                })
              ]
            );
            inputModules = (
              optionals includeInputModules
              <| collectNixOSModules [
                "home-manager"
                "agenix"
                "agenix-rekey"
                "lanzaboote"
                "auto-cpufreq"
                "disko"
                "vscode-server"
                "determinate"
              ]
            );
          in
          {
            imports = flatten [
              modules
              hmNixosModules
              inputModules
            ];
          };
      }
    );
}
