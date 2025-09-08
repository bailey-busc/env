# https://zed.dev/docs/snippets
{
  lib,
  pkgs,
  config,
  ...
}:
{
  options.programs.zed-editor.snippets =
    let
      validLanguages = [
        "bash"
        "c"
        "c++"
        "clojure"
        "css"
        "docker"
        "elisp"
        "elixir"
        "haskell"
        "html"
        "java"
        "javascript"
        "json"
        "kotlin"
        "markdown"
        "plaintext"
        "purescript"
        "nix"
        "python"
        "proto"
        "rust"
        "scala"
        "scss"
        "sql"
        "terraform"
        "typescript"
        "xml"
        "yaml"
      ];
    in
    lib.genAttrs validLanguages (
      language:
      lib.mkOption {
        description = "Snippets for ${language}";
        type = lib.types.attrsOf (
          lib.types.submodule (
            { name, ... }:
            {
              options = {
                prefix = lib.mkOption {
                  type = lib.types.str;
                  default = name;
                  description = "Prefix for ${language} snippet";
                };
                body = lib.mkOption {
                  type = lib.types.listOf lib.types.str;
                  description = "Body for ${language} snippet";
                };
                description = lib.mkOption {
                  type = lib.types.str;
                  default = "No description given";
                  description = "Description for ${language} snippet";
                };
              };
            }
          )
        );
        default = { };
      }
    );
  config = {
    xdg.configFile = {
      "zed/snippets".source =
        # Define snippets as attrsets where the outer name is the json file produced
        config.programs.zed-editor.snippets
        # Map to writeText files
        |> lib.mapAttrs (
          language: snippets: pkgs.writeTextDir "snippets/${language}.json" (builtins.toJSON snippets)
        )
        |> builtins.attrValues
        # symlinkjoin
        |> (
          paths:
          "${
            pkgs.symlinkJoin {
              inherit paths;
              name = "zed-snippets";
            }
          }/snippets"
        );
    };
  };
}
