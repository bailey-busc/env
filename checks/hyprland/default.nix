{
  lib,
  inputs,
  pkgs,
  ...
}:
let
  inherit (lib)
    getExe
    mapAttrs'
    ;
  inherit (inputs.self) nixosConfigurations;
  inherit (inputs.self.lib) filterMapAttrVals;
in
nixosConfigurations
|> filterMapAttrVals (
  { config, ... }:
  config.home-manager.users.${config.env.username}.wayland.windowManager.hyprland.enable
) ({ config, ... }: config.home-manager.users.${config.env.username})
|> mapAttrs' (
  name: homeConfig:
  let
    runtimeDir = "/tmp/check-hyprland-config-${name}-tmpdir";
  in
  {
    name = "hyprland-config-${name}";
    value = pkgs.writeShellScriptBin "check-hyprland-config-${name}" ''
      # Parse arguments
      JSON_OUTPUT=false
      for arg in "$@"; do
        case "$arg" in
          --json)
            JSON_OUTPUT=true
            ;;
        esac
      done

      mkdir -p ${runtimeDir}
      # Cleanup temp dir via trap
      trap "${lib.getExe' pkgs.coreutils "rm"} -rf ${runtimeDir}" EXIT

      # Initialize JSON structure
      if [ "$JSON_OUTPUT" = true ]; then
        exec 3>&1  # Save stdout
        exec 1>&2  # Redirect stdout to stderr for progress messages

        cat > "${runtimeDir}/result.json" <<EOF
      {
        "check": "hyprland-config",
        "host": "${name}",
        "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
        "status": "unknown",
        "checks": {},
        "errors": [],
        "warnings": [],
        "info": {}
      }
      EOF
      fi

      # Helper functions for dual output
      add_check_result() {
        local check_name="$1"
        local status="$2"  # pass, fail, warning, skip
        local message="$3"
        local details="$4"

        if [ "$JSON_OUTPUT" = true ]; then
          ${lib.getExe pkgs.jq} --arg name "$check_name" \
                            --arg status "$status" \
                            --arg message "$message" \
                            --arg details "$details" \
                            '.checks[$name] = {status: $status, message: $message, details: $details}' \
                            "${runtimeDir}/result.json" > "${runtimeDir}/result.json.tmp" && \
                            mv "${runtimeDir}/result.json.tmp" "${runtimeDir}/result.json"
        else
          case "$status" in
            pass) echo "✓ $message" ;;
            fail) echo "✗ $message" ;;
            warning) echo "⚠ $message" ;;
            skip) echo "⊘ $message" ;;
            *) echo "$message" ;;
          esac
          [ -n "$details" ] && echo "$details"
        fi
      }

      add_info() {
        local key="$1"
        local value="$2"

        if [ "$JSON_OUTPUT" = true ]; then
          ${lib.getExe pkgs.jq} --arg key "$key" \
                            --arg value "$value" \
                            '.info[$key] = $value' \
                            "${runtimeDir}/result.json" > "${runtimeDir}/result.json.tmp" && \
                            mv "${runtimeDir}/result.json.tmp" "${runtimeDir}/result.json"
        else
          echo "$value"
        fi
      }

      log_message() {
        if [ "$JSON_OUTPUT" != true ]; then
          echo "$@"
        fi
      }

      config_file="${homeConfig.xdg.configFile."hypr/hyprland.conf".source}"

      log_message "=== HYPRLAND CONFIG CHECK FOR ${name} ==="
      add_info "config_file" "$config_file"
      add_info "config_size_lines" "$(wc -l < "$config_file")"
      log_message ""

      # Extract and analyze bind statements
      log_message "=== BIND ANALYSIS ==="
      bind_count=$(grep -c '^bind' "$config_file" || echo 0)
      add_info "bind_count" "$bind_count"
      log_message "Total bind statements: $bind_count"
      log_message ""

      # Show problematic bind lines (those without proper dispatcher format)
      log_message "=== PROBLEMATIC BIND LINES ==="
      problematic_binds=$(grep '^bind' "$config_file" | ${lib.getExe pkgs.gnugrep} -n -v '^bind = [^,]*, \(exec\|submap\|workspace\|killactive\|togglesplit\|togglefloating\|fullscreen\|centerwindow\|pin\|forcerendererreload\|focusmonitor\|movewindow\)' 2>/dev/null || echo "")

      if [ -z "$problematic_binds" ]; then
        add_check_result "bind_syntax" "pass" "No problematic binds found" ""
        log_message "No problematic binds found"
      else
        bind_count=$(echo "$problematic_binds" | wc -l)
        add_check_result "bind_syntax" "warning" "$bind_count problematic bind lines detected" "$problematic_binds"
        log_message "$problematic_binds"
      fi
      log_message ""

      # Show bind patterns
      log_message "=== BIND PATTERNS ==="
      dispatcher_usage=$(${lib.getExe' pkgs.gawk "awk"} '/^bind = / {
        split($0, parts, ",");
        if (length(parts) >= 3) {
          gsub(/^[ \t]+|[ \t]+$/, "", parts[2]);
          dispatchers[parts[2]]++
        }
      }
      END {
        for (d in dispatchers) print d "|" dispatchers[d]
      }' "$config_file")

      if [ "$JSON_OUTPUT" = true ]; then
        dispatcher_json="{"
        while IFS='|' read -r dispatcher count; do
          [ -n "$dispatcher" ] && dispatcher_json="$dispatcher_json\"$dispatcher\": $count,"
        done <<< "$dispatcher_usage"
        dispatcher_json="''${dispatcher_json%,}}"

        ${lib.getExe pkgs.jq} --argjson dispatchers "$dispatcher_json" '.info.dispatcher_usage = $dispatchers' \
          "${runtimeDir}/result.json" > "${runtimeDir}/result.json.tmp" && \
          mv "${runtimeDir}/result.json.tmp" "${runtimeDir}/result.json"
      else
        echo "Dispatcher usage:"
        while IFS='|' read -r dispatcher count; do
          [ -n "$dispatcher" ] && echo "  $dispatcher: $count"
        done <<< "$dispatcher_usage"
      fi
      log_message ""
      # Show submap-related binds
      log_message "=== SUBMAP BINDS ==="
      submap_binds=$(grep '^bind.*submap' "$config_file" 2>/dev/null || echo "")
      submap_count=$(echo "$submap_binds" | grep -c . || echo 0)

      if [ "$submap_count" -gt 0 ]; then
        add_info "submap_bind_count" "$submap_count"
        if [ "$JSON_OUTPUT" != true ]; then
          echo "$submap_binds" | head -10
          [ "$submap_count" -gt 10 ] && echo "... and $(($submap_count - 10)) more"
        fi
      else
        add_info "submap_bind_count" "0"
        log_message "No submap binds found"
      fi
      log_message ""

      # Run the actual verification
      log_message "=== HYPRLAND VERIFICATION OUTPUT ==="
      XDG_RUNTIME_DIR=${runtimeDir} ${getExe pkgs.hyprland} --config "$config_file" --verify-config 2>&1 | tee "${runtimeDir}/hypr-check.log"
      verification_result=$?

      # Parse and summarize errors
      log_message ""
      log_message "=== ERROR SUMMARY ==="
      error_count=$(grep -c '\[ERR\]' "${runtimeDir}/hypr-check.log" || echo 0)
      add_info "error_count" "$error_count"
      log_message "Total errors: $error_count"

      if [ "$error_count" -gt 0 ]; then
        error_types=$(grep '\[ERR\]' "${runtimeDir}/hypr-check.log" | ${lib.getExe' pkgs.gnugrep "grep"} -o 'Invalid dispatcher.*' | sort | uniq -c | head -10)
        add_check_result "hyprland_verification" "fail" "Hyprland config has $error_count errors" "$error_types"
        log_message "Error types:"
        log_message "$error_types"
      else
        add_check_result "hyprland_verification" "pass" "Hyprland config verification passed" ""
      fi

      # Determine overall status for JSON output
      if [ "$JSON_OUTPUT" = true ]; then
        # Check for any failures
        fail_count=$(${lib.getExe pkgs.jq} '[.checks[] | select(.status == "fail")] | length' "${runtimeDir}/result.json")
        warn_count=$(${lib.getExe pkgs.jq} '[.checks[] | select(.status == "warning")] | length' "${runtimeDir}/result.json")

        if [ "$fail_count" -gt 0 ]; then
          overall_status="fail"
        elif [ "$warn_count" -gt 0 ]; then
          overall_status="warning"
        else
          overall_status="pass"
        fi

        ${lib.getExe pkgs.jq} --arg status "$overall_status" '.status = $status' \
          "${runtimeDir}/result.json" > "${runtimeDir}/result.json.tmp" && \
          mv "${runtimeDir}/result.json.tmp" "${runtimeDir}/result.json"

        # Output final JSON
        exec 1>&3  # Restore stdout
        cat "${runtimeDir}/result.json"
      fi
    '';
  }
)
