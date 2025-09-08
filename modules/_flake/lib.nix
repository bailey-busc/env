{ inputs, self, ... }@args:
{
  flake.lib =
    import "${self}/lib" {
      inherit inputs;
      inherit (inputs) self;
      inherit (inputs.lib) lib;
    }
    // import "${self}/lib/private.nix" {
      inherit inputs;
      inherit (inputs) self;
      inherit (inputs.lib) lib;
    };
}
