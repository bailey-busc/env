{
  lib,
  pkgs,
  osConfig,
  self,
  config,
  ...
}:
let
  inherit (lib)
    mkIf
    getExe
    optionals
    optionalAttrs
    concatLines
    ;
  inherit (config.env) profiles;
  inherit (osConfig.networking) hostName;
  isAzalea = hostName == "azalea";
  isOrchid = hostName == "orchid";
  inherit (pkgs.stdenv) isLinux;

  toggle-control-center = pkgs.writeShellScriptBin "toggle-control-center" ''
        #!/usr/bin/env bash

        # macOS-style Control Center for Hyprland
        # Toggle quick settings using rofi

        # Get current states
        get_wifi_status() {
            if ${pkgs.networkmanager}/bin/nmcli radio wifi | grep -q "enabled"; then
                echo "󰤨 WiFi: On"
            else
                echo "󰤮 WiFi: Off"
            fi
        }

        get_bluetooth_status() {
            if ${pkgs.systemd}/bin/systemctl is-active --quiet bluetooth.service; then
                if ${pkgs.bluez}/bin/bluetoothctl show | grep -q "Powered: yes"; then
                    echo "󰂯 Bluetooth: On"
                else
                    echo "󰂲 Bluetooth: Off"
                fi
            else
                echo "󰂲 Bluetooth: Off"
            fi
        }

        get_dnd_status() {
            if ${pkgs.procps}/bin/pgrep -x dunst >/dev/null; then
                if ${pkgs.dunst}/bin/dunstctl is-paused | grep -q "true"; then
                    echo "󰂛 Do Not Disturb: On"
                else
                    echo "󰂚 Do Not Disturb: Off"
                fi
            else
                echo "󰂚 Do Not Disturb: Off"
            fi
        }

        get_night_light_status() {
            if ${pkgs.procps}/bin/pgrep -x hyprsunset >/dev/null; then
                echo "󰖔 Night Shift: On"
            else
                echo "󰖙 Night Shift: Off"
            fi
        }

        get_volume() {
            volume=$(${pkgs.wireplumber}/bin/wpctl get-volume @DEFAULT_AUDIO_SINK@ | awk '{print int($2*100)}')
            if ${pkgs.wireplumber}/bin/wpctl get-volume @DEFAULT_AUDIO_SINK@ | grep -q "MUTED"; then
                echo "󰖁 Volume: Muted"
            else
                echo "󰕾 Volume: ''${volume}%"
            fi
        }

        get_brightness() {
            if command -v brightnessctl &>/dev/null; then
                brightness=$(${pkgs.brightnessctl}/bin/brightnessctl get)
                max=$(${pkgs.brightnessctl}/bin/brightnessctl max)
                percent=$((brightness * 100 / max))
                echo "󰃠 Brightness: ''${percent}%"
            else
                echo "󰃠 Brightness: N/A"
            fi
        }

        # Menu options
        options="$(get_wifi_status)
    $(get_bluetooth_status)
    $(get_dnd_status)
    $(get_night_light_status)
    󰍃 Display Settings
    󰔊 Sound Settings
    $(get_volume)
    $(get_brightness)
    󱄅 Screen Lock
    󰐥 Power Menu
    󰒓 System Settings"

        # Show menu
        chosen="$(echo -e "$options" | ${getExe config.programs.rofi.finalPackage} -dmenu -p "Control Center" -theme-str 'window {width: 400px;} listview {lines: 11;}')"

        # Handle selection
        case $chosen in
        *"WiFi"*)
            if ${pkgs.networkmanager}/bin/nmcli radio wifi | grep -q "enabled"; then
                ${pkgs.networkmanager}/bin/nmcli radio wifi off
                ${pkgs.libnotify}/bin/notify-send "WiFi" "Turned off" -i network-wireless-offline
            else
                ${pkgs.networkmanager}/bin/nmcli radio wifi on
                ${pkgs.libnotify}/bin/notify-send "WiFi" "Turned on" -i network-wireless
            fi
            ;;
        *"Bluetooth"*)
            if ${pkgs.bluez}/bin/bluetoothctl show | grep -q "Powered: yes"; then
                ${pkgs.bluez}/bin/bluetoothctl power off
                ${pkgs.libnotify}/bin/notify-send "Bluetooth" "Turned off" -i bluetooth-disabled
            else
                ${pkgs.bluez}/bin/bluetoothctl power on
                ${pkgs.libnotify}/bin/notify-send "Bluetooth" "Turned on" -i bluetooth-active
            fi
            ;;
        *"Do Not Disturb"*)
            if ${pkgs.dunst}/bin/dunstctl is-paused | grep -q "true"; then
                ${pkgs.dunst}/bin/dunstctl set-paused false
                ${pkgs.libnotify}/bin/notify-send "Do Not Disturb" "Turned off" -i notifications
            else
                ${pkgs.libnotify}/bin/notify-send "Do Not Disturb" "Turning on..." -i notifications-disabled
                sleep 2
                ${pkgs.dunst}/bin/dunstctl set-paused true
            fi
            ;;
        *"Night Shift"*)
            if ${pkgs.procps}/bin/pgrep -x hyprsunset >/dev/null; then
                ${pkgs.procps}/bin/pkill hyprsunset
                ${pkgs.libnotify}/bin/notify-send "Night Shift" "Turned off" -i weather-clear
            else
                ${config.services.hyprsunset.package}/bin/hyprsunset -t 4500 &
                ${pkgs.libnotify}/bin/notify-send "Night Shift" "Turned on" -i weather-clear-night
            fi
            ;;
        *"Display Settings"*)
            ${pkgs.wdisplays}/bin/wdisplays &
            ;;
        *"Sound Settings"*)
            ${pkgs.pavucontrol}/bin/pavucontrol &
            ;;
        *"Volume"*)
            ${pkgs.pavucontrol}/bin/pavucontrol &
            ;;
        *"Brightness"*)
            # Create a brightness adjustment submenu
            brightness_options="󰃞 25%
    󰃟 50%
    󰃠 75%
    󰃠 100%"
            brightness_chosen="$(echo -e "$brightness_options" | ${getExe config.programs.rofi.finalPackage} -dmenu -p "Brightness")"
            case $brightness_chosen in
            *"25%"*) ${pkgs.brightnessctl}/bin/brightnessctl set 25% ;;
            *"50%"*) ${pkgs.brightnessctl}/bin/brightnessctl set 50% ;;
            *"75%"*) ${pkgs.brightnessctl}/bin/brightnessctl set 75% ;;
            *"100%"*) ${pkgs.brightnessctl}/bin/brightnessctl set 100% ;;
            esac
            ;;
        *"Screen Lock"*)
            ${getExe config.programs.hyprlock.package} &
            ;;
        *"Power Menu"*)
            ${getExe config.programs.rofi.finalPackage} -show power-menu
            ;;
        *"System Settings"*)
            ${pkgs.gnome-control-center}/bin/gnome-control-center &
            ;;
        esac
  '';
in
{
  config = mkIf (config.env.profiles.graphical.enable && isLinux) {
    home.packages = [ toggle-control-center ];

    programs.waybar = {
      enable = false;
      # systemd.enable = true;
      settings = {
        mainBar = {
          layer = "top";
          position = "top";
          height = 26;
          spacing = 8;
          margin = "0 10 0 10";

          output = "!HDMI-A-2"; # Don't show on the TV
          modules-left = [
            "custom/apple"
            "custom/environment"
            "tray"
          ];
          modules-center = [ "clock" ];
          modules-right = [
            "custom/weather"
            "pulseaudio"
          ]
          ++ (optionals isAzalea [
            "battery"
            "backlight"
          ])
          ++ [
            "network"
            "custom/control-center"
          ];
          "hyprland/window" = {
            max-length = 150;
            separate-outputs = true;
          };

          network = {
            format-wifi = "󰤨";
            format-ethernet = "󰈀";
            tooltip-format = "{essid} ({signalStrength}%)\n{ipaddr}";
            format-linked = "󰤭";
            format-disconnected = "󰤮";
            on-click = "nm-connection-editor";
          };

          "custom/apple" = {
            format = "";
            on-click = "rofi -show drun";
            tooltip = false;
          };

          "custom/control-center" = {
            format = "󰍜";
            on-click = "${getExe toggle-control-center}";
            tooltip-format = "Control Center";
          };

          battery = {
            states = {
              good = 95;
              warning = 30;
              critical = 10;
            };

            format = "{icon}";
            format-charging = "󰂄";
            format-plugged = "󰂄";
            format-alt = "{icon} {capacity}%";
            format-icons = [
              "󰁺"
              "󰁻"
              "󰁼"
              "󰁽"
              "󰁾"
              "󰁿"
              "󰂀"
              "󰂁"
              "󰂂"
            ];
            tooltip-format = "{capacity}% - {time}";
          };

          tray = {
            icon-size = 18;
            spacing = 8;
            show-passive-items = true;
          };

          clock = {
            format = "{:%a %b %d  %I:%M %p}";
            tooltip-format = "<big>{:%Y %B}</big>\n<tt><small>{calendar}</small></tt>";
            on-click = "gnome-calendar"; # or your preferred calendar
          };

          pulseaudio = optionalAttrs osConfig.services.pulseaudio.enable {
            format = "{icon}";
            tooltip = true;
            tooltip-format = "Volume: {volume}%";
            format-muted = "󰖁";
            on-click = getExe pkgs.pavucontrol;
            scroll-step = 5;
            format-icons = {
              headphone = "";
              hands-free = "";
              headset = "";
              phone = "";
              portable = "";
              car = "";
              default = [
                ""
                ""
                ""
              ];
            };
          };

          backlight = {
            format = "{icon}";
            format-icons = [
              "󰃞"
              "󰃟"
              "󰃠"
            ];
            tooltip-format = "Brightness: {percent}%";
            on-scroll-up = "brightnessctl set +5%";
            on-scroll-down = "brightnessctl set 5%-";
          };
          temperature = {
            critical-threshold = 70;
            tooltip = false;
            thermal-zone = 2;
            hwmon-path = "/sys/class/hwmon/hwmon1/temp1_input";
            format = "{temperatureC}°C {icon}";
            format-icons = [
              ""
              ""
              ""
            ];
          };
          "custom/environment" = {
            format = "{icon}";
            return-type = "json";
            interval = 5;
            exec = "${getExe config.programs.zsh.package} -c 'get-current-env'";
            on-click = "switch-environment --menu";
            tooltip = true;
            format-icons = {
              personal = "󰋃";
              work = "󰅴";
              gaming = "󰊗";
              focus = "󰒊";
            };
          };
          "custom/weather" = {
            format = "{icon} {temperature}°";
            tooltip = true;
            interval = 60 * 15;
            exec = concatLines [
              (lib.getExe pkgs.wttrbar)
              "--fahrenheit"
              "--mph"
              "--ampm"
              (lib.optionalString isOrchid ''--location "Somerville, MA"'')
            ];
            return-type = "json";
            format-icons = {
              "01d" = "󰖙";
              "01n" = "󰖔";
              "02d" = "󰖕";
              "02n" = "󰖐";
              "03d" = "󰖐";
              "03n" = "󰖐";
              "04d" = "󰖐";
              "04n" = "󰖐";
              "09d" = "󰖗";
              "09n" = "󰖗";
              "10d" = "󰖖";
              "10n" = "󰖖";
              "11d" = "󰖓";
              "11n" = "󰖓";
              "13d" = "󰖘";
              "13n" = "󰖘";
              "50d" = "󰖑";
              "50n" = "󰖑";
            };
          };
        };
      };
      style = ''
        /* macOS Big Sur/Monterey inspired theme */
        * {
          border: none;
          border-radius: 0;
          font-family: ${osConfig.env.theme.fonts.statusBar.name}, "SF Pro Display";
          font-size: 13px;
          font-weight: 500;
          min-height: 0;
        }

        window#waybar {
          background: rgba(28, 28, 30, 0.85);
          color: rgba(255, 255, 255, 0.9);
          transition: all 0.3s cubic-bezier(0.25, 0.46, 0.45, 0.94);
        }

        /* Apple logo */
        #custom-apple {
          font-size: 16px;
          padding: 0 14px;
          color: rgba(255, 255, 255, 0.85);
        }

        #custom-apple:hover {
          background: rgba(255, 255, 255, 0.1);
          border-radius: 6px;
        }

        /* All modules default styling */
        #clock,
        #battery,
        #network,
        #pulseaudio,
        #backlight,
        #custom-weather,
        #custom-environment,
        #custom-control-center,
        #tray {
          padding: 0 8px;
          margin: 3px 2px;
          background: transparent;
          color: rgba(255, 255, 255, 0.85);
          border-radius: 6px;
          transition: all 0.3s cubic-bezier(0.25, 0.46, 0.45, 0.94);
        }

        /* Hover effects */
        #clock:hover,
        #battery:hover,
        #network:hover,
        #pulseaudio:hover,
        #backlight:hover,
        #custom-weather:hover,
        #custom-environment:hover,
        #custom-control-center:hover {
          background: rgba(255, 255, 255, 0.1);
        }

        /* Clock special styling */
        #clock {
          font-weight: 600;
          padding: 0 12px;
        }

        /* Tray styling */
        #tray {
          background: transparent;
        }

        #tray > .passive {
          -gtk-icon-effect: dim;
        }

        #tray > .needs-attention {
          -gtk-icon-effect: highlight;
        }

        /* Environment indicator colors */
        #custom-environment {
          font-size: 15px;
          padding: 0 10px;
        }

        #custom-environment.env-personal {
          color: #ff6b6b;
        }

        #custom-environment.env-work {
          color: #4ecdc4;
        }

        #custom-environment.env-gaming {
          color: #9b59b6;
        }

        #custom-environment.env-focus {
          color: #f1c40f;
        }

        /* Control Center */
        #custom-control-center {
          font-size: 15px;
          padding: 0 12px;
        }

        /* Battery states */
        #battery.charging,
        #battery.plugged {
          color: #2ecc71;
        }

        #battery.warning {
          color: #f39c12;
        }

        #battery.critical:not(.charging) {
          color: #e74c3c;
          animation-name: pulse;
          animation-duration: 1s;
          animation-timing-function: ease-in-out;
          animation-iteration-count: infinite;
          animation-direction: alternate;
        }

        @keyframes pulse {
          from {
            opacity: 1;
          }
          to {
            opacity: 0.3;
          }
        }

        /* Network states */
        #network.disconnected {
          color: rgba(255, 255, 255, 0.4);
        }

        /* Pulseaudio */
        #pulseaudio.muted {
          color: rgba(255, 255, 255, 0.4);
        }

        /* Weather */
        #custom-weather {
          padding: 0 10px;
        }

        /* Tooltips - macOS style */
        tooltip {
          background: rgba(50, 50, 52, 0.95);
          border: 1px solid rgba(255, 255, 255, 0.1);
          border-radius: 8px;
          box-shadow: 0 8px 32px rgba(0, 0, 0, 0.3);
          padding: 8px 12px;
        }

        tooltip label {
          color: rgba(255, 255, 255, 0.9);
          font-size: 12px;
        }
      '';
    };
  };
}
