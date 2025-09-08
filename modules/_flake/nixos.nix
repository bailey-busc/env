{
  withSystem,
  inputs,
  self,
  lib,
  ...
}:
let
  inherit (lib) genAttrs optional flatten;

  modulesFromInputs = with inputs; [
    lanzaboote.nixosModules.lanzaboote # Secure boot
    disko.nixosModules.default # Disk partitioning
    vscode-server.nixosModules.default # VSCode server
    determinate.nixosModules.default # determinate-nixd
    hyprland.nixosModules.default
    {
      imports = [
        base16.nixosModule
      ];
      scheme = "${self}/data/theme.yaml";
    }

    (
      { lib, config, ... }:
      let
        hostPubkey = self.lib.keys.hosts.${config.networking.hostName};
      in
      {
        imports = with inputs; [
          agenix.nixosModules.default
          agenix-rekey.nixosModules.default
        ];
        environment.sessionVariables = {
          # AGENIX_REKEY_PRIMARY_IDENTITY_ONLY = "true";
          # AGENIX_REKEY_PRIMARY_IDENTITY = hostPubkey;
        };
        age.rekey.hostPubkey = lib.mkDefault hostPubkey;
      }
    )
  ];

  nixosSystem =
    {
      name,
      extraModules ? [ ],
      system ? "x86_64-linux",
    }:
    withSystem system (
      {
        config,
        pkgs,
        inputs',
        self',
        ...
      }:
      inputs.nixpkgs.lib.nixosSystem {
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
        modules =
          let
            systemModule = "${self}/systems/${name}/default.nix";
            hardwareScanReport = "${self}/systems/${name}/hardware.json";
          in
          flatten [
            (
              { self, lib, ... }:
              {
                networking = {
                  hostName = lib.mkDefault name;
                  domain = lib.mkDefault "t4t.sh";
                };
              }
            )
            modulesFromInputs
            (builtins.attrValues inputs.self.nixosModules)
            (optional (builtins.pathExists systemModule) (import systemModule))
            (optional (builtins.pathExists hardwareScanReport) {
              imports = [ inputs.nixos-facter-modules.nixosModules.facter ];
              facter.reportPath = hardwareScanReport;
            })
            extraModules
          ];
      }
    );
in
{
  flake.nixosConfigurations = genAttrs [
    "iris"
    "azalea"
    "orchid"
  ] (name: nixosSystem { inherit name; });
}
