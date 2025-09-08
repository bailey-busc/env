{
  config,
  lib,
  pkgs,
  ...
}:
lib.mkIf config.env.profiles.dev.enable {
  home = {
    packages =
      with pkgs;
      #with pkgs.rust.packages.stable;
      [
        cargo
        rustc
        cargo-edit
        cargo-hakari
        cargo-insta
        cargo-mutants
        cargo-outdated
        cargo-nextest
        cargo-watch
        cargo-ui
        cargo-c
        cargo-rr
        cargo-pgo
        cargo-release
        cargo-sort
        cargo-deb
        clippy
        rustfmt
        rust-analyzer
        ra-multiplex
      ];
    sessionPath = [ "$HOME/.cargo/bin" ];
  };
}
