{ self, ... }:
{
  perSystem =
    {
      pkgs,
      ...
    }:
    {
      packages = {
        auto = pkgs.callPackage "${self}/packages/auto" { };
        code2prompt = pkgs.callPackage "${self}/packages/code2prompt" { };
        efs-utils = pkgs.callPackage "${self}/packages/efs-utils" {
          python = pkgs.python3;
        };
        gopro-as-webcam = pkgs.callPackage "${self}/packages/gopro-as-webcam" { };
        nixos-rollback-tui = pkgs.callPackage "${self}/packages/nixos-rollback-tui" { };
        pyfa = pkgs.callPackage "${self}/packages/pyfa" { };
        hyprdrop = pkgs.callPackage "${self}/packages/hyprdrop" { };
        rofi-monitor-toggle = pkgs.callPackage "${self}/packages/rofi-monitor-toggle" { };
        libonnxruntime-neuralnote = pkgs.callPackage "${self}/packages/libonnxruntime-neuralnote" { };
        ultimate-vocal-remover-gui =
          pkgs.python3.pkgs.callPackage "${self}/packages/ultimate-vocal-remover-gui"
            { };
        whitesur-firefox = pkgs.callPackage "${self}/packages/whitesur-firefox" { };
        notion-enhanced = pkgs.callPackage "${self}/packages/notion-enhanced" { };
      };
    };
}
