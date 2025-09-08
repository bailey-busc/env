# https://zed.dev/docs/snippets
{
  self,
  lib,
  pkgs,
  config,
  osConfig,
  ...
}:
let
  cfg = config.programs.zed-editor.context-servers;
  inherit (lib)
    mkEnableOption
    mkIf
    mapAttrsToList
    concatStringsSep
    getExe
    getExe'
    ;
  inherit (self.lib) filterNullAttrs;

  # Binaries
  nix' = getExe osConfig.nix.package;
  npx' = getExe' pkgs.nodejs "npx";
  podman' = getExe config.services.podman.package;
  cat' = getExe' pkgs.coreutils "cat";
in
{
  options.programs.zed-editor.context-servers.enable =
    mkEnableOption "managment of context server configuration for Zed";

  config = mkIf cfg.enable {
    programs.zed-editor.userSettings.context_servers =
      let
        mkContextServer =
          {
            cmd,
            args ? [ ],
            env ? { },
            unsafeEnv ? { },
          }:
          let
            envCmdPrefix =
              unsafeEnv
              |> filterNullAttrs
              |> mapAttrsToList (name: val: "${name}=${val}")
              |> concatStringsSep " ";
            command = if unsafeEnv != { } then "${envCmdPrefix} ${cmd}" else cmd;
          in
          {
            inherit args command;
            source = "custom";
            env = filterNullAttrs env;
          };
      in
      {
        github = mkContextServer {
          cmd = podman';
          args = [
            "run"
            "-i"
            "--rm"
            "-e"
            "GITHUB_PERSONAL_ACCESS_TOKEN=$(${cat'} ${osConfig.age.secrets.gh_token.path})"
            "-e"
            "GITHUB_DYNAMIC_TOOLSETS=1"
            "-e"
            "GITHUB_READ_ONLY=1"
            "ghcr.io/github/github-mcp-server"
          ];
        };
        nixos = mkContextServer {
          cmd = nix';
          args = [
            "run"
            "github:utensils/mcp-nixos"
            "--"
          ];
        };
        context7 = mkContextServer {
          cmd = npx';
          args = [
            "-y"
            "@upstash/context7-mcp"
          ];
        };
        playwright = mkContextServer {
          cmd = npx';
          args = [
            "-y"
            "@playwright/mcp@latest"
            "--executable-path"
            (lib.getExe pkgs.chromium)
            "--isolated"
          ];
        };
      };
  };
}
