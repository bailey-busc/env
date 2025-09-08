{ config, lib, ... }:
with lib;
with builtins;
let
  inherit (config.networking) hostName;
in
{
  nix.buildMachines = filter (a: a ? hostName) [
    #   (optionalAttrs (hostName != "iris") {
    #     hostName = "iris";
    #     sshUser = "bailey";
    #     sshKey = "/home/bailey/.ssh/id_ed25519";
    #     systems = [ "x86_64-linux" ];
    #     maxJobs = 8;
    #     supportedFeatures = [ "nixos-test" "benchmark" "big-parallel" "kvm" ];
    #   })
    #   (optionalAttrs (hostName != "ivy-greentown") {
    #     hostName = "ivy-greentown";
    #     sshUser = "bailey";
    #     sshKey = "/home/bailey/.ssh/id_ed25519";
    #     systems = [ "x86_64-linux" ];
    #     maxJobs = 8;
    #     supportedFeatures = [ "nixos-test" "benchmark" "big-parallel" "kvm" ];
    #   })
  ];
  #nix.distributedBuilds = true;
}
