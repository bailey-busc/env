{
  config,
  lib,
  pkgs,
  inputs,
  self,
  ...
}:

with lib;

let
  cfg = config.env.network.wireguard;

  # Generate a consistent internal IP based on hostname
  generateInternalIP =
    hostname:
    let
      # Simple hash function to generate consistent IPs
      hash = builtins.hashString "sha256" hostname;
      # Take specific chars and map to valid IP ranges
      char1 = builtins.substring 0 1 hash;
      char2 = builtins.substring 8 1 hash;

      # Map hex chars to numbers 1-254
      charToOctet =
        c:
        if c == "0" then
          100
        else if c == "1" then
          101
        else if c == "2" then
          102
        else if c == "3" then
          103
        else if c == "4" then
          104
        else if c == "5" then
          105
        else if c == "6" then
          106
        else if c == "7" then
          107
        else if c == "8" then
          108
        else if c == "9" then
          109
        else if c == "a" then
          110
        else if c == "b" then
          111
        else if c == "c" then
          112
        else if c == "d" then
          113
        else if c == "e" then
          114
        else if c == "f" then
          115
        else
          100;

      thirdOctet = charToOctet char1;
      fourthOctet = charToOctet char2;
    in
    "10.100.${toString thirdOctet}.${toString fourthOctet}";

  # Magic DNS configuration
  magicDNSConfig = {
    domain = cfg.magicDNS.domain;
    hosts = mapAttrs (name: peer: {
      ip = peer.ip;
      services = peer.services or { };
    }) cfg.peers;
  };

  # Merge automatic and manual peers
  allPeers =
    if cfg.automaticPeerDiscovery then
      automaticPeers // cfg.peers # Manual peers override automatic ones
    else
      cfg.peers;

  # WireGuard configuration
  wgConfig = {
    ips = [ "${cfg.self.ip}/${toString cfg.subnet.prefixLength}" ];
    privateKeyFile = cfg.privateKeyFile;
    listenPort = cfg.listenPort;

    peers = mapAttrsToList (name: peer: {
      inherit (peer) publicKey;
      allowedIPs = peer.allowedIPs or [ "${peer.ip}/32" ];
      endpoint = mkIf (peer.endpoint != null) peer.endpoint;
      persistentKeepalive = peer.keepalive or 25;
    }) allPeers;
  };

  # Service discovery script
  serviceDiscoveryScript = pkgs.writeShellScript "wireguard-service-discovery" ''
    set -euo pipefail

    # Update service registry
    REGISTRY_FILE="/var/lib/wireguard-services/registry.json"
    mkdir -p "$(dirname "$REGISTRY_FILE")"

    # Generate service registry
    cat > "$REGISTRY_FILE" << 'EOF'
    ${builtins.toJSON {
      domain = cfg.magicDNS.domain;
      services = mapAttrs (hostname: peer: peer.services or { }) allPeers;
    }}
    EOF

    # Restart Unbound to pick up new entries
    systemctl reload unbound.service || true
  '';

  # Automatic peer discovery from flake systems
  # Use a simpler approach to avoid circular dependencies
  knownSystems = [
    "iris"
    "orchid"
    "azalea"
  ];

  # Generate automatic peers for known systems (excluding current system)
  automaticPeers = lib.listToAttrs (
    lib.filter (x: x != null) (
      map (
        hostname:
        if hostname != config.networking.hostName then
          {
            name = hostname;
            value = {
              publicKey = lib.strings.trim (builtins.readFile "${self}/data/secrets/wireguard/${hostname}.pub");
              ip = generateInternalIP hostname;
              endpoint = null; # Can be overridden in manual peers
              allowedIPs = [ "${generateInternalIP hostname}/32" ];
              keepalive = 25;
              services = { }; # Services will be discovered via Magic DNS
            };
          }
        else
          null
      ) knownSystems
    )
  );

in
{
  options.env.network.wireguard = {
    enable = mkEnableOption "WireGuard mesh network with magic DNS";

    automaticPeerDiscovery = mkOption {
      type = types.bool;
      default = true;
      description = "Automatically discover and configure peers from flake systems";
    };

    endpoint = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "External endpoint for this node (host:port) - used by other peers to connect";
    };

    interfaceName = mkOption {
      type = types.str;
      default = "wg0";
      description = "Name of the WireGuard interface";
    };

    privateKeyFile = mkOption {
      type = types.path;
      description = "Path to the private key file";
    };

    listenPort = mkOption {
      type = types.port;
      default = 51820;
      description = "UDP port for WireGuard to listen on";
    };

    subnet = {
      network = mkOption {
        type = types.str;
        default = "10.100.0.0";
        description = "Network address for the WireGuard subnet";
      };

      prefixLength = mkOption {
        type = types.int;
        default = 16;
        description = "Prefix length for the WireGuard subnet";
      };
    };

    self = {
      ip = mkOption {
        type = types.str;
        default = generateInternalIP config.networking.hostName;
        description = "IP address for this node in the WireGuard network";
      };

      services = mkOption {
        type = types.attrsOf (
          types.submodule {
            options = {
              port = mkOption {
                type = types.port;
                description = "Port the service listens on";
              };

              protocol = mkOption {
                type = types.enum [
                  "tcp"
                  "udp"
                  "both"
                ];
                default = "tcp";
                description = "Protocol the service uses";
              };

              description = mkOption {
                type = types.str;
                default = "";
                description = "Human-readable description of the service";
              };

              public = mkOption {
                type = types.bool;
                default = false;
                description = "Whether this service should be accessible from outside the WireGuard network";
              };
            };
          }
        );
        default = { };
        description = "Services hosted on this node";
      };
    };

    peers = mkOption {
      type = types.attrsOf (
        types.submodule {
          options = {
            publicKey = mkOption {
              type = types.str;
              description = "Public key of the peer";
            };

            ip = mkOption {
              type = types.str;
              description = "IP address of the peer in the WireGuard network";
            };

            endpoint = mkOption {
              type = types.nullOr types.str;
              default = null;
              description = "Endpoint address for the peer (host:port)";
            };

            allowedIPs = mkOption {
              type = types.listOf types.str;
              default = [ ];
              description = "List of IP addresses/subnets this peer is allowed to send traffic for";
            };

            keepalive = mkOption {
              type = types.nullOr types.int;
              default = 25;
              description = "Persistent keepalive interval in seconds";
            };

            services = mkOption {
              type = types.attrsOf (
                types.submodule {
                  options = {
                    port = mkOption {
                      type = types.port;
                      description = "Port the service listens on";
                    };

                    protocol = mkOption {
                      type = types.enum [
                        "tcp"
                        "udp"
                        "both"
                      ];
                      default = "tcp";
                      description = "Protocol the service uses";
                    };

                    description = mkOption {
                      type = types.str;
                      default = "";
                      description = "Human-readable description of the service";
                    };
                  };
                }
              );
              default = { };
              description = "Services hosted on this peer";
            };
          };
        }
      );
      default = { };
      description = "WireGuard peers in the mesh network";
    };

    magicDNS = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Enable magic DNS for service discovery";
      };

      domain = mkOption {
        type = types.str;
        default = "mesh.local";
        description = "Domain suffix for magic DNS";
      };

      upstreamDNS = mkOption {
        type = types.listOf types.str;
        default = [
          "1.1.1.1"
          "8.8.8.8"
        ];
        description = "Upstream DNS servers for non-mesh queries";
      };
    };

    firewall = {
      allowedTCPPorts = mkOption {
        type = types.listOf types.port;
        default = [ ];
        description = "TCP ports to allow through the firewall on the WireGuard interface";
      };

      allowedUDPPorts = mkOption {
        type = types.listOf types.port;
        default = [ ];
        description = "UDP ports to allow through the firewall on the WireGuard interface";
      };

      allowPing = mkOption {
        type = types.bool;
        default = true;
        description = "Allow ping (ICMP) traffic on the WireGuard interface";
      };
    };

    nat = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = "Enable NAT for WireGuard traffic to access external networks";
      };

      externalInterface = mkOption {
        type = types.str;
        default = "eth0";
        description = "External interface for NAT";
      };
    };

    # Enhanced monitoring features
    monitoring = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Enable enhanced monitoring for WireGuard mesh";
      };

      prometheus = {
        enable = mkOption {
          type = types.bool;
          default = true;
          description = "Enable Prometheus metrics export";
        };

        port = mkOption {
          type = types.port;
          default = 9586;
          description = "Port for Prometheus metrics endpoint";
        };

        scrapeInterval = mkOption {
          type = types.int;
          default = 15;
          description = "Metrics collection interval in seconds";
        };
      };

      grafana = {
        enable = mkOption {
          type = types.bool;
          default = false;
          description = "Enable Grafana dashboard";
        };

        port = mkOption {
          type = types.port;
          default = 3000;
          description = "Grafana web interface port";
        };
      };
    };

    # Enhanced security features
    security = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Enable enhanced security features";
      };

      intrusion = {
        enableDetection = mkOption {
          type = types.bool;
          default = true;
          description = "Enable intrusion detection system";
        };

        enablePrevention = mkOption {
          type = types.bool;
          default = false;
          description = "Enable intrusion prevention (may impact performance)";
        };

        alertThreshold = mkOption {
          type = types.int;
          default = 10;
          description = "Number of suspicious events before triggering alert";
        };
      };

      trafficObfuscation = {
        enable = mkOption {
          type = types.bool;
          default = false;
          description = "Enable traffic obfuscation to prevent DPI detection";
        };

        port = mkOption {
          type = types.port;
          default = 443;
          description = "Port to use for obfuscated traffic (appears as HTTPS)";
        };
      };
    };

    # Automated key rotation
    keyRotation = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Enable automatic WireGuard key rotation";
      };

      interval = mkOption {
        type = types.str;
        default = "monthly";
        description = "Key rotation interval (systemd timer format)";
      };

      backupCount = mkOption {
        type = types.int;
        default = 3;
        description = "Number of key backups to retain";
      };
    };

    # Health monitoring
    health = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Enable WireGuard health monitoring";
      };

      checkInterval = mkOption {
        type = types.int;
        default = 30;
        description = "Health check interval in seconds";
      };

      connectivity = {
        timeout = mkOption {
          type = types.int;
          default = 5;
          description = "Connectivity check timeout in seconds";
        };

        failureThreshold = mkOption {
          type = types.int;
          default = 3;
          description = "Number of consecutive failures before triggering recovery";
        };
      };

      recovery = {
        enable = mkOption {
          type = types.bool;
          default = true;
          description = "Enable automatic recovery actions";
        };

        actions = mkOption {
          type = types.listOf (
            types.enum [
              "restart-interface"
              "restart-service"
              "rotate-keys"
              "notify-admin"
            ]
          );
          default = [
            "restart-interface"
            "notify-admin"
          ];
          description = "Recovery actions to take on health check failures";
        };
      };
    };

    # TUI interface
    tui = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = "Enable WireGuard TUI monitoring application";
      };
    };
  };

  config = mkIf cfg.enable {
    # Core WireGuard configuration
    networking.wireguard.interfaces.${cfg.interfaceName} = wgConfig;

    # Firewall configuration
    networking.firewall = {
      allowedUDPPorts = [ cfg.listenPort ];

      interfaces.${cfg.interfaceName} = {
        allowedTCPPorts =
          cfg.firewall.allowedTCPPorts
          ++ (flatten (
            mapAttrsToList (
              name: service: optional (service.protocol == "tcp" || service.protocol == "both") service.port
            ) cfg.self.services
          ));

        allowedUDPPorts =
          cfg.firewall.allowedUDPPorts
          ++ (flatten (
            mapAttrsToList (
              name: service: optional (service.protocol == "udp" || service.protocol == "both") service.port
            ) cfg.self.services
          ));
      };
    };

    # Magic DNS with Unbound
    services.unbound = mkIf cfg.magicDNS.enable {
      enable = true;
      settings = {
        server = {
          access-control = [
            "${cfg.subnet.network}/${toString cfg.subnet.prefixLength} allow"
          ];

          # Local domain configuration
          local-zone = [ ''"${cfg.magicDNS.domain}." static'' ];

          # Generate local-data entries for mesh hosts and services
          local-data =
            (flatten (
              mapAttrsToList (hostname: peer: [
                ''"${hostname}.${cfg.magicDNS.domain}. IN A ${peer.ip}"''
                ''"${hostname}. IN A ${peer.ip}"''
              ]) allPeers
            ))
            ++
              # Generate service-specific DNS entries
              (flatten (
                mapAttrsToList (
                  hostname: peer:
                  mapAttrsToList (
                    serviceName: serviceConfig: ''"${serviceName}.${hostname}.${cfg.magicDNS.domain}. IN A ${peer.ip}"''
                  ) (peer.services or { })
                ) allPeers
              ));
        };
      };
    };

    # NAT configuration
    networking.nat = mkIf cfg.nat.enable {
      enable = true;
      internalInterfaces = [ cfg.interfaceName ];
      externalInterface = cfg.nat.externalInterface;
    };

    # Service discovery
    systemd.services.wireguard-service-discovery = {
      description = "WireGuard Service Discovery";
      wantedBy = [ "multi-user.target" ];
      after = [
        "network.target"
        "wireguard-${cfg.interfaceName}.service"
      ];

      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = serviceDiscoveryScript;
      };
    };

    # Directory for service registry
    systemd.tmpfiles.rules = [
      "d /var/lib/wireguard-services 755 root root -"
    ];

    # Helper script for managing the mesh
    environment.systemPackages = [
      (pkgs.writeShellScriptBin "wg-mesh" ''
        #!/usr/bin/env bash
        set -euo pipefail

        REGISTRY_FILE="/var/lib/wireguard-services/registry.json"

        case "''${1:-help}" in
          "status")
            echo "WireGuard Mesh Status:"
            echo "====================="
            wg show ${cfg.interfaceName}
            echo
            echo "Services:"
            if [[ -f "$REGISTRY_FILE" ]]; then
              ${pkgs.jq}/bin/jq -r '.services | to_entries[] | "\(.key): \(.value | to_entries[] | "\(.key):\(.value.port) (\(.value.protocol))")"' "$REGISTRY_FILE" 2>/dev/null || echo "No services registered"
            else
              echo "Service registry not found"
            fi
            ;;
          "peers")
            echo "Active Peers:"
            wg show ${cfg.interfaceName} peers
            ;;
          "services")
            echo "Available Services:"
            if [[ -f "$REGISTRY_FILE" ]]; then
              ${pkgs.jq}/bin/jq -r '.services | to_entries[] | "\(.key).\(.value | keys[] as $svc | "${cfg.magicDNS.domain}: \($svc) (port \(.[$svc].port))")"' "$REGISTRY_FILE" 2>/dev/null || echo "No services registered"
            else
              echo "Service registry not found"
            fi
            ;;
          "ping")
            if [[ -n "''${2:-}" ]]; then
              ping -c 3 "''${2}.${cfg.magicDNS.domain}"
            else
              echo "Usage: wg-mesh ping <hostname>"
              exit 1
            fi
            ;;
          "help"|*)
            echo "WireGuard Mesh Management Tool"
            echo "Usage: wg-mesh <command>"
            echo
            echo "Commands:"
            echo "  status    - Show WireGuard status and services"
            echo "  peers     - List active peers"
            echo "  services  - List available services"
            echo "  ping <host> - Ping a mesh host"
            echo "  help      - Show this help"
            ;;
        esac
      '')
    ];

    # Assertions
    assertions = [
      {
        assertion = cfg.privateKeyFile != null;
        message = "WireGuard private key file must be specified";
      }
      {
        assertion = cfg.self.ip != null;
        message = "Self IP address must be specified";
      }
      {
        assertion = cfg.magicDNS.domain != "";
        message = "Magic DNS domain must be specified";
      }
    ];
  };
}
