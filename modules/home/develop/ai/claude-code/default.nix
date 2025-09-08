{
  pkgs,
  lib,
  self,
  config,
  osConfig,
  ...
}:
let
  inherit (builtins)
    map
    readFile
    filter
    ;
  inherit (lib)
    getExe
    getExe'
    flatten
    ;

  inherit (lib.cli) toGNUCommandLine;
  inherit (self.lib.fs) getFiles;
  inherit (self.lib.path) getFileNameWithoutExtension hasFileExtension;

  # Binaries
  cat' = getExe' pkgs.coreutils "cat";
  nix' = getExe osConfig.nix.package;
  npx' = getExe' pkgs.nodejs "npx";
  podman' = getExe config.services.podman.package;
  uvx' = getExe' pkgs.uv "uvx";
  notify-send' = getExe' pkgs.libnotify "notify-send";
in
{
  programs.claude-code = {
    enable = true;
    commands = { };
    agents =
      getFiles "${self}/data/prompts/"
      |> filter (hasFileExtension "xml")
      |> map (path: rec {
        name = getFileNameWithoutExtension path;
        value = ''
          ---
          name: ${name}
          description: Prompt Format: XML - Role: ${name}
          tools: Read, Edit, Grep
          ---

          ${readFile path}
        '';
      })
      |> builtins.listToAttrs;
    mcpServers = {
      nixos = {
        command = nix';
        args = [
          "run"
          "github:utensils/mcp-nixos"
          "--"
        ];
      };
      github = {
        command = podman';
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
      context7 = {
        command = npx';
        args = [
          "-y"
          "@upstash/context7-mcp"
        ];
      };
      playwright = {
        command = npx';
        args = [
          "-y"
          "@playwright/mcp@latest"
          "--executable-path"
          (getExe config.programs.chromium.package)
          "--isolated"
        ];
      };
    };
    settings = {
      enableAllProjectMcpServers = true;
      includeCoAuthoredBy = false;
      statusLine = {
        type = "command";
        command = "${npx'} -y ccstatusline@latest";
        padding = 0;
      };
      permissions = {
        defaultMode = "plan";
        allow = flatten [
          (map (command: "Bash(${command}:*)") [
            "nix develop"
            "nix build"
            "rg"
          ])
          # Basic permissions
          "Write"
          "MultiEdit"
          "Edit"
          "WebFetch"
          # MCP
          "mcp__context7__resolve-library-id"
          "mcp__context7__get-library-docs"
          "context7:*"
        ];
        deny = [ ];
      };
      hooks = {
        Notification = [
          {
            hooks = [
              {
                matcher = "";
                type = "command";
                command =
                  pkgs.writeShellApplication' "claude-code-notif-hook"
                    (with pkgs; [
                      libnotify
                      jq
                    ])
                    ''
                      message="$(jq .message)"
                      notify-send ${
                        builtins.concatStringsSep " "
                        <| toGNUCommandLine { } {
                          urgency = "low";
                          app-name = "Claude Code";
                        }
                      } "Claude Code" "''${message}"
                    '';
              }
            ];
          }
        ];
        Stop = [
          {
            hooks = [
              {
                matcher = "";
                type = "command";
                command = "jj show";
              }
            ];
          }
        ];
      };
    };
  };
}
