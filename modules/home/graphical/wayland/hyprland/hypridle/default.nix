{
  inputs',
  lib,
  config,
  osConfig,
  pkgs,
  ...
}:
let
  inherit (lib) getExe getExe' mkIf;

  minutes = 60; # seconds, duh
  lockTimeout = 5 * minutes;
  displayOffTimeout = lockTimeout + 10 * minutes;
  sleepTimeout = displayOffTimeout + 15 * minutes;

  hyprctl' = getExe' osConfig.programs.hyprland.package "hyprctl";

  # SSH session check script
  sshCheckScript = pkgs.writeShellScript "check-ssh-sessions" ''
    # Check for active SSH sessions
    # Returns 0 if NO active SSH sessions (safe to sleep)
    # Returns 1 if active SSH sessions exist (prevent sleep)

    # Check using ss command for established SSH connections
    if command -v ss >/dev/null 2>&1; then
        ssh_connections=$(ss -tn state established '( sport = :22 or dport = :22 )' 2>/dev/null | grep -c ':22')
        if [ "$ssh_connections" -gt 0 ]; then
            echo "Active SSH sessions detected: $ssh_connections"
            exit 1
        fi
    fi

    # Alternative check using who command for pts sessions
    if command -v who >/dev/null 2>&1; then
        pts_sessions=$(who | grep -c "pts/")
        if [ "$pts_sessions" -gt 0 ]; then
            echo "Active PTS sessions detected: $pts_sessions"
            exit 1
        fi
    fi

    echo "No active SSH sessions"
    exit 0
  '';

  # Sleep command that checks for SSH sessions first
  sleepCommand = pkgs.writeShellScript "conditional-sleep" ''
    if ${sshCheckScript}; then
        ${getExe' osConfig.systemd.package "systemctl"} suspend
    else
        echo "Skipping sleep due to active SSH sessions"
    fi
  '';
in
{
  services = mkIf config.wayland.windowManager.hyprland.enable {
    hypridle = {
      enable = true;
      package = inputs'.hypridle.packages.hypridle;

      settings = rec {
        general = rec {
          lock_cmd = getExe config.programs.hyprlock.package;
          before_sleep_cmd = lock_cmd;
          after_sleep_cmd = "${hyprctl'} dispatch dpms on";
        };
        listener = [
          {
            timeout = displayOffTimeout;
            on-timeout = "${hyprctl'} dispatch dpms off";
            on-resume = general.after_sleep_cmd;
          }
          {
            timeout = lockTimeout;
            on-timeout = general.lock_cmd;
          }
          {
            timeout = sleepTimeout;
            on-timeout = "${sleepCommand}";
          }
        ];
      };
    };
  };
}
