{ inputs, self, ... }@modArgs:
let
  inherit (inputs.lib) lib;
  inherit (lib) composeManyExtensions;
  inherit (builtins) listToAttrs;
  inherit (self.lib.fs) getNonDefaultNixFiles;
  inherit (self.lib.path) getFileNameWithoutExtension;
in
{
  flake.overlays = {
    default = import "${self}/overlays" modArgs;

    # Overlay
    input_packages =
      _: prev:
      let
        ezps = import inputs.easy-purescript-nix {
          pkgs = inputs.nixpkgs-24_05.legacyPackages.${prev.stdenv.hostPlatform.system};
        };
      in
      {
        # Nix language server
        nil = inputs.nil.packages.${prev.stdenv.hostPlatform.system}.default;
        # Zellij status plugin
        zjstatus = inputs.zjstatus.packages.${prev.stdenv.hostPlatform.system}.default;
        # Zed editor
        inherit (inputs.zed-editor.packages.${prev.stdenv.hostPlatform.system})
          zed-editor
          zed-editor-bin
          zed-editor-fhs
          zed-editor-bin-fhs
          zed-editor-preview
          zed-editor-preview-bin
          zed-editor-preview-fhs
          zed-editor-preview-bin-fhs
          ;

        # MkWIndowsApp
        windows-tools = {
          inherit (inputs.erosanix.lib.${prev.stdenv.hostPlatform.system})
            mkWindowsApp
            mkWindowsAppNoCC
            copyDesktopIcons
            makeDesktopIcon
            genericBinWrapper
            mkmupen64plus
            compose
            composeAndApply
            ;
        };
      };
    python = _: prev: {
      pythonPackagesExtensions = prev.pythonPackagesExtensions ++ [
        (
          pyFinal: _:
          getNonDefaultNixFiles "${self}/packages/pythonPackages"
          |> map (pkgPath: {
            name = getFileNameWithoutExtension pkgPath;
            value = pyFinal.callPackage pkgPath { };
          })
          |> listToAttrs
        )
        # (pyFinal: _: {
        # tf-playwright-stealth =
        # pyFinal.callPackage "${self}/packages/pythonPackages/tf-playwright-stealth.nix"
        # { };
        # })
      ];
    };

    # Additional overlays from inputs
    agenix-rekey = inputs.agenix-rekey.overlays.default;
    deploy-rs = inputs.deploy-rs.overlays.default;
    hyprland = composeManyExtensions [
      inputs.hyprland.overlays.default
      (final: prev: {
        hyprland = prev.hyprland.override {
          inherit (inputs.nixpkgs-weekly.legacyPackages.${prev.stdenv.hostPlatform.system}) libinput;
        };
      })
    ];
    hyprland-plugins = inputs.hyprland-plugins.overlays.default;
    hyprhook = inputs.hyprhook.overlays.default;
    nix-vscode-extensions = inputs.nix-vscode-extensions.overlays.default;
    adblock-unbound = inputs.adblock-unbound.overlays.default;
    fh = inputs.fh.overlays.default;
    nixpkgs-terraform = inputs.nixpkgs-terraform.overlays.default;
    # nix-branding = inputs.branding.overlays.default;
  };
}
