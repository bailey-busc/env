{ config, pkgs, ... }:
let
  deployUser = config.users.users.deploy.name;
  inhibitorPath = "/tmp/no-reboot";

  # Script to manage the reboot inhibitor
  # This allows operators to temporarily disable automatic reboots
  inhibitorHelper = pkgs.writeShellScriptBin "reboot-inhibitor" ''
        set -euo pipefail

        readonly SCRIPT_NAME="$(basename "$0")"
        readonly INHIBITOR_FILE="${inhibitorPath}"

        log() {
            echo "[$(date '+%Y-%m-%d %H:%M:%S')] $SCRIPT_NAME: $*" >&2
        }

        show_usage() {
            cat <<EOF
    Usage: $SCRIPT_NAME <command>

    Commands:
        enable      Create inhibitor file to prevent reboots
        disable     Remove inhibitor file to allow reboots
        status      Show current inhibitor status
        help        Show this help message

    The inhibitor file is located at: $INHIBITOR_FILE
    EOF
        }

        enable_inhibitor() {
            if [ -f "$INHIBITOR_FILE" ]; then
                log "Inhibitor already enabled"
                return 0
            fi

            touch "$INHIBITOR_FILE"
            log "Reboot inhibitor enabled at $INHIBITOR_FILE"
        }

        disable_inhibitor() {
            if [ ! -f "$INHIBITOR_FILE" ]; then
                log "Inhibitor already disabled"
                return 0
            fi

            rm -f "$INHIBITOR_FILE"
            log "Reboot inhibitor disabled (removed $INHIBITOR_FILE)"
        }

        show_status() {
            if [ -f "$INHIBITOR_FILE" ]; then
                log "Reboot inhibitor: ENABLED"
                log "File: $INHIBITOR_FILE (exists)"
                log "Created: $(stat -c %y "$INHIBITOR_FILE" 2>/dev/null || echo "unknown")"
            else
                log "Reboot inhibitor: DISABLED"
                log "File: $INHIBITOR_FILE (does not exist)"
            fi
        }

        main() {
            case "''${1:-}" in
                enable)
                    enable_inhibitor
                    ;;
                disable)
                    disable_inhibitor
                    ;;
                status)
                    show_status
                    ;;
                help|--help|-h)
                    show_usage
                    ;;
                "")
                    log "ERROR: No command specified"
                    show_usage
                    exit 1
                    ;;
                *)
                    log "ERROR: Unknown command: $1"
                    show_usage
                    exit 1
                    ;;
            esac
        }

        main "$@"
  '';

  # Main reboot helper script with comprehensive safety checks
  # This script is designed to safely reboot a NixOS system only when:
  # 1. Explicitly confirmed with --yes argument
  # 2. System has been running for at least 2 minutes
  # 3. No inhibitor file exists
  # 4. A new configuration is available
  rebootHelper = pkgs.writeShellScriptBin "reboot-helper" ''
    set -euo pipefail

    # Configuration
    readonly SCRIPT_NAME="$(basename "$0")"
    readonly MIN_UPTIME_SECONDS=120
    readonly INHIBITOR_FILE="${inhibitorPath}"
    readonly SYSTEM_PROFILE="/nix/var/nix/profiles/system"
    readonly BOOTED_SYSTEM="/run/booted-system"

    # Exit codes
    readonly EXIT_SUCCESS=0
    readonly EXIT_INVALID_ARGS=1
    readonly EXIT_UPTIME_TOO_LOW=2
    readonly EXIT_INHIBITOR_EXISTS=3
    readonly EXIT_NO_CONFIG_CHANGE=4

    # Logging function
    log() {
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] $SCRIPT_NAME: $*" >&2
    }

    # Error function
    error() {
        log "ERROR: $*"
    }

    # Info function
    info() {
        log "INFO: $*"
    }

    # Check arguments
    check_arguments() {
        if [ "$#" -ne 1 ] || [ "$1" != "--yes" ]; then
            error "Invalid arguments. Must be invoked with a single argument: --yes"
            error "This is a safety measure to prevent accidental reboots"
            exit $EXIT_INVALID_ARGS
        fi
        info "Arguments validated successfully"
    }

    # Check system uptime
    check_uptime() {
        local uptime_seconds
        uptime_seconds="$(cut -d' ' -f1 /proc/uptime | cut -d. -f1)"

        if [ "$uptime_seconds" -le "$MIN_UPTIME_SECONDS" ]; then
            error "System uptime ($uptime_seconds seconds) is below minimum threshold ($MIN_UPTIME_SECONDS seconds)"
            error "This prevents reboots immediately after boot"
            exit $EXIT_UPTIME_TOO_LOW
        fi

        info "Uptime check passed ($uptime_seconds seconds > $MIN_UPTIME_SECONDS seconds)"
    }

    # Check for inhibitor file
    check_inhibitor() {
        if [ -f "$INHIBITOR_FILE" ]; then
            error "Reboot inhibitor file exists: $INHIBITOR_FILE"
            error "Remove this file to allow reboots, or use 'rm $INHIBITOR_FILE'"
            exit $EXIT_INHIBITOR_EXISTS
        fi

        info "No reboot inhibitor found"
    }

    # Check if configuration has changed
    check_configuration_change() {
        local current_system booted_system

        if ! current_system="$(readlink -f "$SYSTEM_PROFILE" 2>/dev/null)"; then
            error "Failed to read current system profile: $SYSTEM_PROFILE"
            exit $EXIT_NO_CONFIG_CHANGE
        fi

        if ! booted_system="$(readlink -f "$BOOTED_SYSTEM" 2>/dev/null)"; then
            error "Failed to read booted system profile: $BOOTED_SYSTEM"
            exit $EXIT_NO_CONFIG_CHANGE
        fi

        if [ "$current_system" = "$booted_system" ]; then
            error "No configuration change detected"
            error "Current: $current_system"
            error "Booted:  $booted_system"
            exit $EXIT_NO_CONFIG_CHANGE
        fi

        info "Configuration change detected:"
        info "  Booted:  $booted_system"
        info "  Current: $current_system"
    }

    # Perform the reboot
    perform_reboot() {
        info "All safety checks passed - initiating reboot"
        info "System will reboot now..."

        # Use exec to replace the shell process and redirect stdin from /dev/null
        # to ensure clean execution
        exec reboot </dev/null
    }

    # Main execution
    main() {
        info "Starting reboot helper with safety checks"

        check_arguments "$@"
        check_uptime
        check_inhibitor
        check_configuration_change
        perform_reboot
    }

    # Execute main function with all arguments
    main "$@"
  '';
in
{
  nix.settings = {
    allowed-users = [ deployUser ];
    trusted-users = [ deployUser ];
  };
  users.users.deploy = {
    packages = [
      rebootHelper
      inhibitorHelper
    ];
    isNormalUser = true;
    group = "nogroup";
    home = "/var/empty";
    createHome = false;
    shell = pkgs.zsh;
    inherit (config.users.users.bailey) hashedPassword openssh;
  };
  security.sudo.extraRules = [
    {
      users = [ deployUser ];
      runAs = "root";
      commands =
        [
          "/nix/var/nix/profiles/default/bin/nix-env ^-p /nix/var/nix/profiles/system --set /nix/store/([a-z0-9]+)-nixos-system-${config.networking.hostName}-([0-9.a-z]+)$"
          "/run/current-system/sw/bin/nix-env ^-p /nix/var/nix/profiles/system --set /nix/store/([a-z0-9]+)-nixos-system-${config.networking.hostName}-([0-9.a-z]+)$"
          "/nix/var/nix/profiles/default/bin/nix-env --rollback -p /nix/var/nix/profiles/system"
          "/run/current-system/sw/bin/nix-env --rollback -p /nix/var/nix/profiles/system"

          "/run/current-system/sw/bin/systemd-run ^-E LOCALE_ARCHIVE -E NIXOS_INSTALL_BOOTLOADER=(1?) --collect --no-ask-password --pipe --quiet (--same-dir )?--service-type=exec --unit=nixos-rebuild-switch-to-configuration --wait true$"
          "/run/current-system/sw/bin/systemd-run ^-E LOCALE_ARCHIVE -E NIXOS_INSTALL_BOOTLOADER=(1?) --collect --no-ask-password --pipe --quiet (--same-dir )?--service-type=exec --unit=nixos-rebuild-switch-to-configuration --wait /nix/store/([a-z0-9]+)-nixos-system-${config.networking.hostName}-([0-9.a-z]+)/bin/switch-to-configuration (switch|boot|test|dry-activate)$"
          "/run/current-system/sw/bin/env ^-i LOCALE_ARCHIVE=([^ ]+) NIXOS_INSTALL_BOOTLOADER=(1?) /nix/store/([a-z0-9]+)-nixos-system-${config.networking.hostName}-([0-9.a-z]+)/bin/switch-to-configuration (switch|boot|test|dry-activate)$"

          "/etc/profiles/per-user/${deployUser}/bin/${rebootHelper.meta.mainProgram} --yes"
          "/etc/profiles/per-user/${deployUser}/bin/${inhibitorHelper.meta.mainProgram} (enable|disable|status|help)"
        ]
        |> map (cmd: {
          command = cmd;
          options = [ "NOPASSWD" ];
        });
    }
  ];
}
