{
  inputs,
  ...
}:

{
  flake =
    let
      extraSpecialArgs = rec {
        inherit inputs;
        inherit (inputs) self;
      };
      sharedModules = (builtins.attrValues inputs.self.homeModules) ++ [
        inputs.nix-doom-emacs-unstraightened.homeModule
        inputs.ignis.homeManagerModules.default
        (
          { osConfig, ... }:
          {
            imports = [
              inputs.base16.homeManagerModule
            ];
            inherit (osConfig) scheme;
          }
        )

      ];
    in
    {
      nixosModules.home =
        _nixos@{
          config,
          packages,
          inputs',
          self',
          ...
        }:
        {
          imports = [
            inputs.home-manager.nixosModules.home-manager
            {
              home-manager = {
                inherit sharedModules;
                extraSpecialArgs = extraSpecialArgs // {
                  inherit packages inputs' self';
                  osConfig = config;
                };
                useGlobalPkgs = true;
                useUserPackages = true;
                users.${config.env.username} = import "${inputs.self}/homes/${config.env.username}";
                backupFileExtension = "bak";
              };
            }
          ];
        };

      darwinModules.home =
        {
          config,
          packages,
          inputs',
          inputs,
          self',
          ...
        }:
        {
          imports = [
            inputs.home-manager.darwinModules.home-manager
            {
              home-manager = {
                inherit sharedModules;
                extraSpecialArgs = extraSpecialArgs // {
                  inherit packages inputs' self';
                  osConfig = config;
                };
                useGlobalPkgs = true;
                useUserPackages = true;
                users.${config.env.username} = import "${inputs.self}/homes/${config.env.username}";
                backupFileExtension = "bak";
              };
            }
          ];
        };

      # homeConfigurations =
      #   let
      #     mkHomeConfig =
      #       system:
      #       inputs.home-manager.lib.homeManagerConfiguration {
      #         inherit extraSpecialArgs;
      #         pkgs = inputs.nixpkgs.legacyPackages.${system};
      #         modules = sharedModules;
      #       };
      #   in
      #   {
      #     linux = mkHomeConfig "x86_64-linux";
      #     macos = mkHomeConfig "aarch64-darwin";
      #   };
    };
}
