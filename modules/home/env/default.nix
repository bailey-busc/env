{
  lib,
  osConfig,
  ...
}:
let
  inherit (lib)
    mkEnableOption
    mkOption
    types
    ;
in
{
  options.env = {
    username = mkOption {
      type = types.str;
      default = osConfig.env.username;
      description = "Username for the environment";
    };
    profiles = {
      base.enable = mkEnableOption "non-essential basic utilities";
      dev = {
        enable = mkEnableOption "development utilities";
        ai.enable = mkEnableOption "AI tooling";
        cloud.enable = mkEnableOption "cloud tools";
        haskell.enable = mkEnableOption "haskell tools";
        purescript.enable = mkEnableOption "purescript tools";
        python.enable = mkEnableOption "python tools";
        rust.enable = mkEnableOption "rust tools";
        nix.enable = mkEnableOption "nix tools";
        elisp.enable = mkEnableOption "elisp tools";
        remote.enable = mkEnableOption "remote tools";
      };
      graphical.enable = mkEnableOption "graphical environment";
      personal.enable = mkEnableOption "things you probably don't need for work";
      games.enable = mkEnableOption "gaming related utilities";
      cuda.enable = mkEnableOption "CUDA and utilities";
      server.ollama.enable = mkEnableOption "ollama server and configuration";
    };
  };
}
