{
  lib,
  fetchFromGitHub,
  rustPlatform,
  pkg-config,
  stdenv,
}:

rustPlatform.buildRustPackage rec {
  pname = "nixos-rollback-tui";
  version = "0.1.0";

  src = ./.;

  cargoLock.lockFile = ./Cargo.lock;

  nativeBuildInputs = [
    pkg-config
  ];

  meta = {
    description = "A TUI for rolling back to different NixOS generations";
    homepage = "https://github.com/your-username/nixos-rollback-tui";
    license = lib.licenses.mit;
    maintainers = [ ];
    mainProgram = "nixos-rollback-tui";
  };
}
