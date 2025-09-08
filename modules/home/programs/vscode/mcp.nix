{ lib, pkgs, ... }:
let
  inherit (lib)
    optionalAttrs
    getExe'
    ;
in
lib.filterAttrs (_: v: v != { }) {
  "mcpServers" = optionalAttrs true {
    "nixos" = {
      "command" = getExe' pkgs.uv "uvx";
      "args" = [ "mcp-nixos" ];
    };
    "desktop-commander" = optionalAttrs false {
      "command" = getExe' pkgs.nodejs "npx";
      "args" = [
        "-y"
        "@wonderwhy-er/desktop-commander"
      ];
    };
    "sequential-thinking" = optionalAttrs false {
      "command" = getExe' pkgs.nodejs "npx";
      "args" = [
        "-y"
        "@modelcontextprotocol/server-sequential-thinking"
      ];
      "transportType" = "stdio";
    };
    "context7" = optionalAttrs true {
      "timeout" = 20;
      "command" = getExe' pkgs.nodejs "npx";
      "args" = [
        "-y"
        "@upstash/context7-mcp"
      ];
      "transportType" = "stdio";
    };
    "memory" = optionalAttrs true {
      "timeout" = 20;
      "command" = getExe' pkgs.nodejs "npx";
      "args" = [
        "-y"
        "mcp-knowledge-graph"
        "--memory-path"
        "/home/bailey/.memory.jsonl"
      ];
      "transportType" = "stdio";
    };
  };
}
