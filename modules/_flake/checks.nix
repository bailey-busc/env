{
  inputs,
  self,
  lib,
  ...
}:
{
  perSystem =
    {
      config,
      self',
      inputs',
      pkgs,
      system,
      ...
    }:
    {
      checks =
        let
          deployChecks = inputs.deploy-rs.lib.${system}.deployChecks self.deploy;
          hyprlandChecks = pkgs.callPackage "${self}/checks/hyprland" { inherit inputs; };
          waybarChecks = pkgs.callPackage "${self}/checks/waybar" { inherit inputs; };
          rofiChecks = pkgs.callPackage "${self}/checks/rofi" { inherit inputs; };
        in
        [
          deployChecks
          hyprlandChecks
          waybarChecks
          rofiChecks
        ]
        |> lib.mergeAttrsList
        |> lib.flip removeAttrs [
          "override"
          "overrideDerivation"
        ];
    };
}
