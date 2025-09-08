{
  config,
  lib,
  pkgs,
  ...
}:

{
  programs.zsh.shellAliases = {
    tsip =
      (pkgs.writeShellScript "tsip" ''
        ${lib.getExe pkgs.tailscale} status --json | ${lib.getExe pkgs.jq} "([.Self] + [(.Peer | to_entries | map(.value))[]]) | map({( .DNSName | split(\".\")[0] ): .TailscaleIPs[0]}) | add"
      '').outPath;
  };
}
