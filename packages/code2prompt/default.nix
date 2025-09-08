{
  lib,
  fetchFromGitHub,
  rustPlatform,
  pkg-config,
  perl,
  openssl,
  stdenv,
  darwin,
}:

rustPlatform.buildRustPackage rec {
  pname = "code2prompt";
  version = "2.1.0";

  src = fetchFromGitHub {
    owner = "mufeedvh";
    repo = "code2prompt";
    rev = "v${version}";
    hash = "sha256-CR6IUuL40Y/smsqAUnHCGRhUPe7YGQ+jlOPkDDJscMo=";
  };

  cargoLock.lockFile = "${src}/Cargo.lock";

  nativeBuildInputs = [
    pkg-config
    perl
  ];

  buildInputs = [
    openssl
  ]
  ++ lib.optionals stdenv.hostPlatform.isDarwin [
    darwin.apple_sdk.frameworks.Security
    darwin.apple_sdk.frameworks.AppKit
  ];

  meta = {
    description = "A CLI tool that converts your codebase into a single LLM prompt with a source tree, prompt templating, and token counting";
    homepage = "https://github.com/mufeedvh/code2prompt";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [ heisfer ];
    mainProgram = "code2prompt";
  };
}
