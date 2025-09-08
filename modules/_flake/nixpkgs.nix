{ inputs, self, ... }:
{
  perSystem =
    { system, ... }:
    {
      # Adjust the internal nixpkgs we use to use all overlays and private-ish stuff
      _module.args.pkgs = import "${self}/modules/_flake/_nixpkgs.nix" {
        inherit system;
        inherit (inputs) nixpkgs;
        overlays = builtins.attrValues inputs.self.overlays;
      };
    };
}
