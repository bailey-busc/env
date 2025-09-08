{
  pkgs,
  lib,
  config,
  inputs',
  ...
}:
let
  inherit (lib)
    mkForce
    mkIf
    mkMerge
    ;
in
{
  boot = {
    kernelModules = [ "tcp_bbr" ];
    kernel.sysctl = {
      # Network performance
      "net.ipv4.tcp_congestion_control" = "bbr";
      "net.core.rmem_max" = 67108864;
      "net.core.wmem_max" = 67108864;
    };
  };
  services = {
    dnsmasq.enable = mkForce false;
    unbound = {
      enable = true;
      settings = {
        server = {
          include = [
            "\"${inputs'.adblock-unbound.packages.unbound-adblockStevenBlack}\""
          ];
          interface = "127.0.0.1";
          port = 53;
          do-ip4 = "yes";
          do-ip6 = "yes";
          do-udp = "yes";
          do-tcp = "yes";
          access-control = [
            "127.0.0.0/8 allow"
            "::1 allow"
          ];
          hide-identity = true;
          hide-version = true;
          prefetch = true;
          tls-cert-bundle = "${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt";
          cache-max-ttl = 14400;
          cache-min-ttl = 1200;

          # Performance settings
          num-threads = 2;
          msg-cache-slabs = 4;
          rrset-cache-slabs = 4;
          infra-cache-slabs = 4;
          key-cache-slabs = 4;
        };
        forward-zone = [
          {
            name = ".";
            forward-addr = mkMerge [
              (mkIf config.services.tailscale.enable [
                "100.100.100.100@53#tailscale"
              ])
              [
                "1.1.1.1@53#one.one.one.one"
                "1.0.0.1@53#one.one.one.one"
                "8.8.8.8@53#dns.google"
                "8.8.4.4@53#dns.google"
              ]
            ];
          }
        ];
      };
    };
  };
}
