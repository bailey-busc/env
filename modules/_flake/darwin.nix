{
  withSystem,
  inputs,
  lib,
  self,
  ...
}:
let
  # Cheap instantiation of nixpkgs lib
  inherit (lib) genAttrs optional flatten;

  modulesFromInputs = [
    {
      imports = [
        inputs.base16.nixosModule
      ];
      scheme = "${self}/data/theme.yaml";
    }
    {
      # determinate-nixd
      imports = [
        inputs.determinate.darwinModules.default
      ];
      determinate-nix.customSettings = { };
    }
    (
      { lib, config, ... }:
      let
        hostname = config.networking.hostName;
        hostKeys = self.lib.keys.hosts;
        hasHostKey = hostKeys ? ${hostname};
        hostKey = hostKeys.${hostname};
      in
      {
        imports = [
          inputs.agenix.darwinModules.default
          inputs.agenix-rekey.nixosModules.default
        ];
        age.rekey.hostPubkey = lib.mkIf hasHostKey <| lib.mkDefault hostKey;
      }
    )
  ];

  darwinSystem =
    {
      name,
      extraModules ? [ ],
      system ? "aarch64-darwin",
    }:
    withSystem system (
      ctx@{
        config,
        pkgs,
        inputs',
        self',
        ...
      }:
      inputs.nix-darwin.lib.darwinSystem {
        inherit system pkgs;
        specialArgs = {
          inherit (config) packages;
          inherit
            inputs
            inputs'
            self'
            ;
          inherit (inputs) self;
        };
        enableNixpkgsReleaseCheck = false;
        modules = flatten [
          modulesFromInputs
          extraModules
          (builtins.attrValues inputs.self.darwinModules)
          (
            let
              systemModule = "${self}/systems/${name}";
            in
            (optional (builtins.pathExists systemModule) systemModule)
          )
        ];
      }
    );
in
{
  flake.darwinConfigurations = genAttrs [
    "oleander"
  ] (name: darwinSystem { inherit name; });
}
