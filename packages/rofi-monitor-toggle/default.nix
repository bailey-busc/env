{
  writeShellScriptBin,
  rofi,
  xorg,
  gnugrep,
  gnused,
  gawk,
  wlr-randr,
}:

writeShellScriptBin "rofi-monitor-toggle" ''
  #!/usr/bin/env bash

  # Rofi Monitor Toggle - A rofi menu for toggling monitors on/off
  # Supports both X11 (xrandr) and Wayland (hyprctl/wlr-randr)

  set -euo pipefail

  # Colors and styling
  ROFI_THEME="dmenu"
  ROFI_PROMPT="Monitor Toggle"

  # Detect display server
  detect_display_server() {
      if [[ -n "''${WAYLAND_DISPLAY:-}" ]] || [[ -n "''${HYPRLAND_INSTANCE_SIGNATURE:-}" ]]; then
          if command -v hyprctl >/dev/null 2>&1; then
              echo "hyprland"
          elif command -v wlr-randr >/dev/null 2>&1; then
              echo "wlr-randr"
          else
              echo "wayland-unknown"
          fi
      elif [[ -n "''${DISPLAY:-}" ]]; then
          echo "x11"
      else
          echo "unknown"
      fi
  }

  # Get all connected monitors
  get_monitors() {
      local display_server
      display_server=$(detect_display_server)

      case "$display_server" in
          "hyprland")
              hyprctl monitors -j | ${gawk}/bin/awk -F'"' '/"name":/ {print $4}'
              ;;
          "wlr-randr")
              ${wlr-randr}/bin/wlr-randr | ${gnugrep}/bin/grep "^[A-Z]" | ${gawk}/bin/awk '{print $1}'
              ;;
          "x11")
              ${xorg.xrandr}/bin/xrandr --query | \
              ${gnugrep}/bin/grep " connected" | \
              ${gawk}/bin/awk '{print $1}'
              ;;
          *)
              echo "Error: Unsupported display server: $display_server" >&2
              return 1
              ;;
      esac
  }

  # Get monitor status (on/off)
  get_monitor_status() {
      local monitor="$1"
      local display_server
      display_server=$(detect_display_server)

      case "$display_server" in
          "hyprland")
              if hyprctl monitors -j | ${gnugrep}/bin/grep -q "\"name\":\"$monitor\""; then
                  echo "ON"
              else
                  echo "OFF"
              fi
              ;;
          "wlr-randr")
              if ${wlr-randr}/bin/wlr-randr | ${gnugrep}/bin/grep "^$monitor" | ${gnugrep}/bin/grep -q "Enabled: yes"; then
                  echo "ON"
              else
                  echo "OFF"
              fi
              ;;
          "x11")
              if ${xorg.xrandr}/bin/xrandr --query | \
                 ${gnugrep}/bin/grep "^$monitor connected" | \
                 ${gnugrep}/bin/grep -q "[0-9]\+x[0-9]\+"; then
                  echo "ON"
              else
                  echo "OFF"
              fi
              ;;
          *)
              echo "OFF"
              ;;
      esac
  }

  # Get primary monitor
  get_primary_monitor() {
      local display_server
      display_server=$(detect_display_server)

      case "$display_server" in
          "hyprland")
              hyprctl monitors -j | ${gawk}/bin/awk -F'"' '/"focused":true/ {found=1} found && /"name":/ {print $4; exit}'
              ;;
          "wlr-randr")
              ${wlr-randr}/bin/wlr-randr | ${gnugrep}/bin/grep -B5 "Enabled: yes" | ${gnugrep}/bin/grep "^[A-Z]" | head -1 | ${gawk}/bin/awk '{print $1}'
              ;;
          "x11")
              ${xorg.xrandr}/bin/xrandr --query | \
              ${gnugrep}/bin/grep " connected primary" | \
              ${gawk}/bin/awk '{print $1}' | head -1
              ;;
          *)
              echo ""
              ;;
      esac
  }

  # Toggle monitor on/off
  toggle_monitor() {
      local monitor="$1"
      local status="$2"
      local display_server
      display_server=$(detect_display_server)
      local primary_monitor
      primary_monitor=$(get_primary_monitor)

      case "$display_server" in
          "hyprland")
              if [[ "$status" == "ON" ]]; then
                  # Turn monitor off
                  if [[ "$monitor" == "$primary_monitor" ]]; then
                      ${rofi}/bin/rofi -e "Cannot turn off focused monitor: $monitor"
                      return 1
                  fi
                  hyprctl keyword monitor "$monitor,disable"
                  notify "Monitor $monitor turned OFF"
              else
                  # Turn monitor on
                  hyprctl keyword monitor "$monitor,preferred,auto,1"
                  notify "Monitor $monitor turned ON"
              fi
              ;;
          "wlr-randr")
              if [[ "$status" == "ON" ]]; then
                  ${wlr-randr}/bin/wlr-randr --output "$monitor" --off
                  notify "Monitor $monitor turned OFF"
              else
                  ${wlr-randr}/bin/wlr-randr --output "$monitor" --on
                  notify "Monitor $monitor turned ON"
              fi
              ;;
          "x11")
              if [[ "$status" == "ON" ]]; then
                  # Turn monitor off
                  if [[ "$monitor" == "$primary_monitor" ]]; then
                      ${rofi}/bin/rofi -e "Cannot turn off primary monitor: $monitor"
                      return 1
                  fi
                  ${xorg.xrandr}/bin/xrandr --output "$monitor" --off
                  notify "Monitor $monitor turned OFF"
              else
                  # Turn monitor on (auto-detect best mode and position)
                  if [[ -n "$primary_monitor" && "$monitor" != "$primary_monitor" ]]; then
                      # Position secondary monitor to the right of primary
                      ${xorg.xrandr}/bin/xrandr --output "$monitor" --auto --right-of "$primary_monitor"
                  else
                      # Just turn on with auto settings
                      ${xorg.xrandr}/bin/xrandr --output "$monitor" --auto
                  fi
                  notify "Monitor $monitor turned ON"
              fi
              ;;
          *)
              ${rofi}/bin/rofi -e "Error: Unsupported display server: $display_server"
              return 1
              ;;
      esac
  }

  # Send notification (if available)
  notify() {
      local message="$1"
      if command -v notify-send >/dev/null 2>&1; then
          notify-send "Monitor Toggle" "$message"
      fi
      echo "$message"
  }

  # Create menu entries
  create_menu() {
      local monitors
      local display_server
      display_server=$(detect_display_server)
      monitors=$(get_monitors)

      if [[ -z "$monitors" ]]; then
          echo "No monitors detected"
          return 1
      fi

      echo "🖥️  Monitor Control ($display_server)"
      echo "─────────────────"

      while IFS= read -r monitor; do
          local status
          status=$(get_monitor_status "$monitor")
          local primary_indicator=""

          if [[ "$monitor" == "$(get_primary_monitor)" ]]; then
              case "$display_server" in
                  "hyprland")
                      primary_indicator=" (Focused)"
                      ;;
                  *)
                      primary_indicator=" (Primary)"
                      ;;
              esac
          fi

          if [[ "$status" == "ON" ]]; then
              echo "🟢 $monitor$primary_indicator - Turn OFF"
          else
              echo "🔴 $monitor$primary_indicator - Turn ON"
          fi
      done <<< "$monitors"

      echo "─────────────────"
      echo "🔄 Refresh"
      echo "⚙️  Display Settings"
      echo "📋 Show Current Setup"
  }

  # Show current display setup
  show_current_setup() {
      local display_server
      display_server=$(detect_display_server)
      local setup_info

      case "$display_server" in
          "hyprland")
              setup_info=$(hyprctl monitors | ${gnused}/bin/sed 's/Monitor /\nMonitor: /g')
              ;;
          "wlr-randr")
              setup_info=$(${wlr-randr}/bin/wlr-randr)
              ;;
          "x11")
              setup_info=$(${xorg.xrandr}/bin/xrandr --query | \
                           ${gnugrep}/bin/grep " connected" | \
                           ${gnused}/bin/sed 's/connected/\nStatus: Connected/' | \
                           ${gnused}/bin/sed 's/primary/\nPrimary: Yes/' | \
                           ${gnused}/bin/sed 's/\([0-9]\+x[0-9]\++[0-9]\++[0-9]\+\)/\nResolution: \1/')
              ;;
          *)
              setup_info="Unsupported display server: $display_server"
              ;;
      esac

      ${rofi}/bin/rofi -e "$setup_info"
  }

  # Open display settings (if available)
  open_display_settings() {
      local display_server
      display_server=$(detect_display_server)

      case "$display_server" in
          "hyprland")
              if command -v wdisplays >/dev/null 2>&1; then
                  wdisplays &
              elif command -v nwg-displays >/dev/null 2>&1; then
                  nwg-displays &
              else
                  ${rofi}/bin/rofi -e "No Wayland display settings app found.\nTry installing: wdisplays or nwg-displays"
              fi
              ;;
          "wlr-randr"|"wayland-unknown")
              if command -v wdisplays >/dev/null 2>&1; then
                  wdisplays &
              elif command -v kanshi >/dev/null 2>&1; then
                  ${rofi}/bin/rofi -e "Kanshi is installed but requires manual configuration"
              else
                  ${rofi}/bin/rofi -e "No Wayland display settings app found.\nTry installing: wdisplays"
              fi
              ;;
          "x11")
              if command -v gnome-control-center >/dev/null 2>&1; then
                  gnome-control-center display &
              elif command -v systemsettings5 >/dev/null 2>&1; then
                  systemsettings5 kcm_displayconfiguration &
              elif command -v arandr >/dev/null 2>&1; then
                  arandr &
              else
                  ${rofi}/bin/rofi -e "No display settings application found.\nTry installing: arandr, gnome-control-center, or systemsettings5"
              fi
              ;;
          *)
              ${rofi}/bin/rofi -e "Unsupported display server: $display_server"
              ;;
      esac
  }

  # Main function
  main() {
      local choice
      choice=$(create_menu | ${rofi}/bin/rofi -dmenu -i -p "$ROFI_PROMPT" -theme "$ROFI_THEME")

      if [[ -z "$choice" ]]; then
          exit 0
      fi

      case "$choice" in
          "🖥️  Monitor Control"*|"─────────────────")
              # Header items, do nothing
              ;;
          "🔄 Refresh")
              exec "$0"
              ;;
          "⚙️  Display Settings")
              open_display_settings
              ;;
          "📋 Show Current Setup")
              show_current_setup
              ;;
          *)
              # Parse monitor toggle choice
              if [[ "$choice" =~ ^🟢\ (.+)\ \(.*\)?\ -\ Turn\ OFF$ ]] || \
                 [[ "$choice" =~ ^🟢\ (.+)\ -\ Turn\ OFF$ ]]; then
                  local monitor="''${BASH_REMATCH[1]}"
                  toggle_monitor "$monitor" "ON"
              elif [[ "$choice" =~ ^🔴\ (.+)\ \(.*\)?\ -\ Turn\ ON$ ]] || \
                   [[ "$choice" =~ ^🔴\ (.+)\ -\ Turn\ ON$ ]]; then
                  local monitor="''${BASH_REMATCH[1]}"
                  toggle_monitor "$monitor" "OFF"
              else
                  ${rofi}/bin/rofi -e "Unknown choice: $choice"
              fi
              ;;
      esac
  }

  # Run main function
  main "$@"
''
