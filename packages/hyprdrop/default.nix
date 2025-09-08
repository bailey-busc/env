{
  lib,
  rustPlatform,
  fetchFromGitHub,
}:

rustPlatform.buildRustPackage rec {
  pname = "hyprdrop";
  version = "unstable-2025-07-31";

  src = fetchFromGitHub {
    owner = "bailey-busc";
    repo = "hyprdrop";
    rev = "58c72058c45c3523f09c08bd1ff7000833e84afe";
    hash = "sha256-E2XOnPCdsq8C8kjkThtiF/GY/v5hxfysqgGl/BDWSTI=";
  };

  cargoLock = {
    lockFile = "${src}/Cargo.lock";
    outputHashes = {
      "hyprland-0.4.0-beta.2" = "sha256-qz1j+LNVpnaThvoR0z3cdCWHs/mL4IbY88MLUKKN7dg=";
    };
  };

  meta = with lib; {
    description = "Rust implementation of Hdrop";
    homepage = "https://github.com/bailey-busc/hyprdrop";
    license = licenses.mit;
    maintainers = with maintainers; [ ];
    mainProgram = "hyprdrop";
  };
}
