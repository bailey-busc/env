{
  config,
  inputs,
  self,
  ...
}:
{
  perSystem =
    {
      pkgs,
      inputs',
      system,
      lib,
      self',
      ...
    }:
    {
      devShells = {
        default =
          let
            ignis = self.nixosConfigurations.iris.config.home-manager.users.bailey.programs.ignis.finalPackage;
          in
          pkgs.mkShell {
            venvDir = "./modules/home/graphical/wayland/ignis/config/.venv";
            inputsFrom = [
              ignis
            ];
            packages = with pkgs; [
              inputs'.nil.packages.nil
              inputs'.deploy-rs.packages.deploy-rs

              # Ignis
              python3Packages.venvShellHook
              (python3.withPackages (
                ps: with ps; [
                  python
                  ruff
                ]
              ))

              gnome-bluetooth
              gpu-screen-recorder
              inputs'.ignis-gvc.packages.ignis-gvc
              networkmanager
              dart-sass

            ];
            postVenvCreation = ''
              pip install -r ${inputs.ignis}/dev.txt
              pip install -e git+https://github.com/ignis-sh/ignis.git#egg=ignis
            '';
            GI_TYPELIB_PATH = "${inputs'.ignis-gvc.packages.ignis-gvc}/lib/ignis-gvc";
            LD_LIBRARY_PATH = pkgs.lib.makeLibraryPath (
              with pkgs;
              [
                gtk4-layer-shell
              ]
            );
          };
      };
    };
}
