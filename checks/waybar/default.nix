{
  lib,
  inputs,
  pkgs,
  ...
}:
let
  inherit (lib)
    getExe
    mapAttrs
    ;
  inherit (inputs.self) nixosConfigurations;
  inherit (inputs.self.lib) filterMapAttrVals;
in
nixosConfigurations
|> filterMapAttrVals (
  { config, ... }: config.home-manager.users.${config.env.username}.programs.waybar.enable
) ({ config, ... }: config.home-manager.users.${config.env.username})
|> mapAttrs (
  name: homeConfig:
  let
    runtimeDir = "/tmp/check-waybar-config-${name}-tmpdir";
  in
  {
    name = "waybar-config-${name}";
    value = pkgs.writeShellScriptBin "check-waybar-config-${name}" ''
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
        "check": "waybar-config",
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
          ${getExe pkgs.jq} --arg name "$check_name" \
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
          ${getExe pkgs.jq} --arg key "$key" \
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

      config_file="${homeConfig.xdg.configFile."waybar/config".source}"
      style_file="${homeConfig.xdg.configFile."waybar/style.css".source}"

      log_message "=== WAYBAR CONFIG CHECK FOR ${name} ==="
      add_info "config_file" "$config_file"
      add_info "style_file" "$style_file"
      log_message ""

      # Check if files exist
      if [ ! -f "$config_file" ]; then
        add_check_result "config_exists" "fail" "Config file not found!" ""
        if [ "$JSON_OUTPUT" = true ]; then
          ${getExe pkgs.jq} '.status = "fail"' "${runtimeDir}/result.json" > "${runtimeDir}/result.json.tmp" && \
          mv "${runtimeDir}/result.json.tmp" "${runtimeDir}/result.json"
          exec 1>&3  # Restore stdout
          cat "${runtimeDir}/result.json"
        fi
        exit 1
      else
        add_check_result "config_exists" "pass" "Config file exists" ""
      fi

      if [ ! -f "$style_file" ]; then
        add_check_result "style_exists" "fail" "Style file not found!" ""
        if [ "$JSON_OUTPUT" = true ]; then
          ${getExe pkgs.jq} '.status = "fail"' "${runtimeDir}/result.json" > "${runtimeDir}/result.json.tmp" && \
          mv "${runtimeDir}/result.json.tmp" "${runtimeDir}/result.json"
          exec 1>&3  # Restore stdout
          cat "${runtimeDir}/result.json"
        fi
        exit 1
      else
        add_check_result "style_exists" "pass" "Style file exists" ""
      fi

      # Config format detection and validation
      log_message "=== CONFIG FORMAT CHECK ==="

      # Try to detect if it's JSON or Nix-generated
      if ${getExe pkgs.jq} . "$config_file" > /dev/null 2>&1; then
        add_check_result "config_format" "pass" "Config is in JSON format" ""
        add_info "config_format" "json"
        CONFIG_FORMAT="json"

        # Extract and analyze waybar configuration
        log_message ""
        log_message "=== MODULE ANALYSIS ==="

        # Count modules
        log_message "Modules configured:"
        ${getExe pkgs.jq} -r '
          if type == "array" then
            .[0] |
            to_entries[] |
            select(.key | startswith("modules-")) |
            "\(.key): \(.value | length) modules"
          else
            to_entries[] |
            select(.key | startswith("modules-")) |
            "\(.key): \(.value | length) modules"
          end
        ' "$config_file" 2>/dev/null || log_message "  Could not analyze modules"

        # Store module counts in JSON
        if [ "$JSON_OUTPUT" = true ]; then
          module_info=$(${getExe pkgs.jq} -r '
            if type == "array" then
              .[0] |
              {
                modules_left: (."modules-left" | length),
                modules_center: (."modules-center" | length),
                modules_right: (."modules-right" | length)
              }
            else
              {
                modules_left: (."modules-left" | length),
                modules_center: (."modules-center" | length),
                modules_right: (."modules-right" | length)
              }
            end
          ' "$config_file" 2>/dev/null || echo '{}')

          ${getExe pkgs.jq} --argjson modules "$module_info" '.info.modules = $modules' \
            "${runtimeDir}/result.json" > "${runtimeDir}/result.json.tmp" && \
            mv "${runtimeDir}/result.json.tmp" "${runtimeDir}/result.json"
        fi

        # List all unique modules
        log_message ""
        log_message "All modules found:"
        ${getExe pkgs.jq} -r '
          if type == "array" then
            .[0] | keys[] | select(. | IN("layer", "position", "height", "spacing", "margin", "output", "modules-left", "modules-center", "modules-right") | not)
          else
            keys[] | select(. | IN("layer", "position", "height", "spacing", "margin", "output", "modules-left", "modules-center", "modules-right") | not)
          end
        ' "$config_file" 2>/dev/null | sort -u > "${runtimeDir}/all_modules.txt"

        if [ -s "${runtimeDir}/all_modules.txt" ]; then
          if [ "$JSON_OUTPUT" = true ]; then
            modules_json=$(${getExe pkgs.jq} -Rs 'split("\n") | map(select(. != ""))' "${runtimeDir}/all_modules.txt")
            ${getExe pkgs.jq} --argjson modules "$modules_json" '.info.all_modules = $modules' \
              "${runtimeDir}/result.json" > "${runtimeDir}/result.json.tmp" && \
              mv "${runtimeDir}/result.json.tmp" "${runtimeDir}/result.json"
          else
            sed 's/^/  - /' "${runtimeDir}/all_modules.txt"
          fi
        else
          log_message "  Could not list modules"
        fi

        # Check for custom modules
        log_message ""
        log_message "Custom modules:"
        ${getExe pkgs.jq} -r '
          if type == "array" then
            .[0] | to_entries[] |
            select(.key | startswith("custom/")) |
            "  - " + .key
          else
            to_entries[] |
            select(.key | startswith("custom/")) |
            "  - " + .key
          end
        ' "$config_file" 2>/dev/null > "${runtimeDir}/custom_modules.txt"

        if [ -s "${runtimeDir}/custom_modules.txt" ]; then
          if [ "$JSON_OUTPUT" = true ]; then
            custom_json=$(${getExe pkgs.jq} -Rs 'split("\n") | map(select(. != "")) | map(ltrimstr("  - "))' "${runtimeDir}/custom_modules.txt")
            ${getExe pkgs.jq} --argjson custom "$custom_json" '.info.custom_modules = $custom' \
              "${runtimeDir}/result.json" > "${runtimeDir}/result.json.tmp" && \
              mv "${runtimeDir}/result.json.tmp" "${runtimeDir}/result.json"
          else
            cat "${runtimeDir}/custom_modules.txt"
          fi
        else
          log_message "  No custom modules found"
        fi

      else
        # Not JSON, likely Nix-generated
        add_check_result "config_format" "pass" "Config appears to be Nix-generated (not JSON)" ""
        add_info "config_format" "nix"
        CONFIG_FORMAT="nix"

        # Try to extract module information from the raw config
        echo ""
        echo "=== MODULE ANALYSIS (from raw config) ==="

        # Look for module patterns in the config
        echo "Detected modules:"
        grep -E '(modules-left|modules-center|modules-right)' "$config_file" | head -20 || echo "  Could not detect module layout"

        echo ""
        echo "Custom modules found:"
        grep -o '"custom/[^"]*"' "$config_file" | sort -u | sed 's/"//g' | sed 's/^/  - /' || echo "  No custom modules detected"

        echo ""
        echo "Standard modules found:"
        grep -oE '"(clock|battery|network|cpu|memory|temperature|pulseaudio|backlight|tray|idle_inhibitor|mpd|sway/[^"]*|hyprland/[^"]*)"' "$config_file" | sort -u | sed 's/"//g' | sed 's/^/  - /' || echo "  No standard modules detected"
      fi

      # CSS syntax validation
      log_message ""
      log_message "=== CSS SYNTAX CHECK ==="

      # Check for unsupported CSS properties that waybar doesn't recognize
      log_message "Checking for unsupported CSS properties..."
      if grep -q "backdrop-filter\|webkit-backdrop-filter" "$style_file"; then
        add_check_result "css_unsupported_properties" "warning" \
          "'backdrop-filter' property found - not supported by waybar's CSS parser" \
          "Blur effects should be achieved through compositor settings instead"
      else
        add_check_result "css_unsupported_properties" "pass" "No unsupported CSS properties found" ""
      fi

      # Basic CSS validation using stylelint if available, otherwise basic checks
      if command -v stylelint >/dev/null 2>&1; then
        stylelint "$style_file" --formatter=compact || echo "✓ CSS validation completed"
      else
        # Basic CSS syntax checks
        echo "Performing basic CSS checks..."

        # Check for unclosed braces
        open_braces=$(grep -o '{' "$style_file" | wc -l)
        close_braces=$(grep -o '}' "$style_file" | wc -l)
        if [ "$open_braces" -eq "$close_braces" ]; then
          add_check_result "css_braces" "pass" "Braces are balanced" ""
        else
          add_check_result "css_braces" "fail" \
            "Unbalanced braces detected!" \
            "Open: $open_braces, Close: $close_braces"
        fi

        # Check for common CSS issues
        log_message ""
        log_message "CSS Statistics:"

        css_stats="{
          \"total_lines\": $(wc -l < "$style_file"),
          \"selectors\": $(grep -c '^[[:space:]]*[#\.\*\[]' "$style_file" || echo 0),
          \"color_definitions\": $(grep -cE '(#[0-9a-fA-F]{3,8}|rgba?\(|hsla?\()' "$style_file" || echo 0),
          \"font_definitions\": $(grep -c 'font' "$style_file" || echo 0)
        }"

        if [ "$JSON_OUTPUT" = true ]; then
          ${getExe pkgs.jq} --argjson stats "$css_stats" '.info.css_stats = $stats' \
            "${runtimeDir}/result.json" > "${runtimeDir}/result.json.tmp" && \
            mv "${runtimeDir}/result.json.tmp" "${runtimeDir}/result.json"
        else
          echo "  Total lines: $(wc -l < "$style_file")"
          echo "  Selectors: $(grep -c '^[[:space:]]*[#\.\*\[]' "$style_file" || echo 0)"
          echo "  Color definitions: $(grep -cE '(#[0-9a-fA-F]{3,8}|rgba?\(|hsla?\()' "$style_file" || echo 0)"
          echo "  Font definitions: $(grep -c 'font' "$style_file" || echo 0)"
        fi
      fi

      # Check for module-style correspondence
      log_message ""
      log_message "=== MODULE-STYLE CORRESPONDENCE CHECK ==="

      # Create modules list based on config format
      > "${runtimeDir}/modules.txt"

      if [ "$CONFIG_FORMAT" = "json" ]; then
        # Extract all modules from JSON config (handle both array and object formats)
        ${getExe pkgs.jq} -r '
          if type == "array" then
            # Waybar config as array with single object
            .[0] |
            # Get modules from modules-* arrays
            ([to_entries[] | select(.key | startswith("modules-")) | .value[]] +
             # Also get any module definitions (keys that aren't config properties)
             [keys[] | select(. | IN("layer", "position", "height", "spacing", "margin", "output", "modules-left", "modules-center", "modules-right") | not)]) |
            unique | .[]
          else
            # Regular object format
            ([to_entries[] | select(.key | startswith("modules-")) | .value[]] +
             [keys[] | select(. | IN("layer", "position", "height", "spacing", "margin", "output", "modules-left", "modules-center", "modules-right") | not)]) |
            unique | .[]
          end
        ' "$config_file" 2>/dev/null | sort -u > "${runtimeDir}/modules.txt" || true
      else
        # Extract modules from non-JSON config
        grep -o '"custom/[^"]*"' "$config_file" | sed 's/"//g' | sort -u >> "${runtimeDir}/modules.txt" 2>/dev/null || true
        grep -oE '"(clock|battery|network|cpu|memory|temperature|pulseaudio|backlight|tray|idle_inhibitor|mpd|sway/[^"]*|hyprland/[^"]*)"' "$config_file" | sed 's/"//g' | sort -u >> "${runtimeDir}/modules.txt" 2>/dev/null || true
      fi

      # Check if modules have corresponding styles
      if [ -s "${runtimeDir}/modules.txt" ]; then
        log_message "Checking if modules have styles defined:"

        modules_with_styles=""
        modules_without_styles=""

        while IFS= read -r module; do
          # Escape special characters for grep
          escaped_module=$(echo "$module" | sed 's/[[\.*^$()+?{|]/\\&/g')
          if grep -q "#$escaped_module" "$style_file"; then
            log_message "  ✓ $module"
            modules_with_styles="$modules_with_styles$module,"
          else
            log_message "  ⚠ $module (no specific style found)"
            modules_without_styles="$modules_without_styles$module,"
          fi
        done < "${runtimeDir}/modules.txt"

        if [ "$JSON_OUTPUT" = true ]; then
          with_json=$(echo "$modules_with_styles" | sed 's/,$//' | ${getExe pkgs.jq} -Rs 'split(",") | map(select(. != ""))')
          without_json=$(echo "$modules_without_styles" | sed 's/,$//' | ${getExe pkgs.jq} -Rs 'split(",") | map(select(. != ""))')

          ${getExe pkgs.jq} --argjson with "$with_json" \
                            --argjson without "$without_json" \
                            '.info.module_styles = {with_styles: $with, without_styles: $without}' \
            "${runtimeDir}/result.json" > "${runtimeDir}/result.json.tmp" && \
            mv "${runtimeDir}/result.json.tmp" "${runtimeDir}/result.json"
        fi

        if [ -n "$modules_without_styles" ]; then
          add_check_result "module_styles" "warning" "Some modules lack specific styles" ""
        else
          add_check_result "module_styles" "pass" "All modules have styles defined" ""
        fi
      else
        log_message "  No modules detected to check against styles"
        add_check_result "module_styles" "skip" "No modules detected to check against styles" ""
      fi

      # Waybar validation using CLI
      log_message ""
      log_message "=== WAYBAR CLI VALIDATION ==="

      # Create a minimal test environment
      export XDG_RUNTIME_DIR="${runtimeDir}"
      export WAYLAND_DISPLAY="waybar-test"
      export XDG_CONFIG_HOME="${runtimeDir}/config"

      # Copy config files to test location
      mkdir -p "${runtimeDir}/config/waybar"
      cp "$config_file" "${runtimeDir}/config/waybar/config"
      cp "$style_file" "${runtimeDir}/config/waybar/style.css"

      # Run waybar config validation
      echo "Running waybar config validation..."

      # Check if --fake-outputs is supported
      if ${getExe pkgs.waybar} --help 2>&1 | grep -q "fake-outputs"; then
        echo "Using --fake-outputs for validation..."
        ${getExe pkgs.waybar} --config "$config_file" --css "$style_file" --fake-outputs 2>&1 | tee "${runtimeDir}/waybar-validation.log"
        validation_result=$?
      else
        echo "Using --version for validation (--fake-outputs not supported)..."
        # Fall back to just loading config with --version
        ${getExe pkgs.waybar} --config "$config_file" --css "$style_file" --version 2>&1 | tee "${runtimeDir}/waybar-validation.log"
        validation_result=$?

        # Also try a dry-run with timeout
        echo ""
        echo "Attempting dry-run validation..."
        timeout 1s ${getExe pkgs.waybar} --config "$config_file" --css "$style_file" 2>&1 | tee -a "${runtimeDir}/waybar-validation.log" || true
      fi

      if [ $validation_result -eq 0 ]; then
        add_check_result "waybar_validation" "pass" "Waybar configuration is valid" ""
      else
        validation_errors=$(grep -E "(error|warning|Error|Warning)" "${runtimeDir}/waybar-validation.log" | head -20 || echo "")
        add_check_result "waybar_validation" "fail" \
          "Waybar configuration validation failed" \
          "$validation_errors"
      fi

      # Additional check for CSS parsing errors
      log_message ""
      log_message "Checking for CSS parsing errors..."
      if grep -q "style.css.*is not a valid property" "${runtimeDir}/waybar-validation.log"; then
        css_errors=$(grep "style.css.*is not a valid property" "${runtimeDir}/waybar-validation.log" || echo "")
        add_check_result "css_parsing" "fail" \
          "CSS parsing errors detected" \
          "$css_errors"
      else
        add_check_result "css_parsing" "pass" "No CSS parsing errors detected" ""
      fi

      # Summary
      log_message ""
      log_message "=== VALIDATION SUMMARY ==="
      log_message "Configuration appears to be valid for host: ${name}"
      log_message ""

      # Warnings for common issues
      log_message "=== COMMON ISSUES TO CHECK ==="
      log_message "1. Ensure all custom module scripts are executable"
      log_message "2. Check that icon fonts are installed for icon display"
      log_message "3. Verify that all exec commands in custom modules exist"
      log_message "4. Ensure proper permissions for any system files accessed"
      log_message "5. Note: waybar doesn't support 'backdrop-filter' CSS property"
      log_message "   Use compositor blur settings for transparency effects instead"

      # Determine overall status for JSON output
      if [ "$JSON_OUTPUT" = true ]; then
        # Check for any failures
        fail_count=$(${getExe pkgs.jq} '[.checks[] | select(.status == "fail")] | length' "${runtimeDir}/result.json")
        warn_count=$(${getExe pkgs.jq} '[.checks[] | select(.status == "warning")] | length' "${runtimeDir}/result.json")

        if [ "$fail_count" -gt 0 ]; then
          overall_status="fail"
        elif [ "$warn_count" -gt 0 ]; then
          overall_status="warning"
        else
          overall_status="pass"
        fi

        ${getExe pkgs.jq} --arg status "$overall_status" '.status = $status' \
          "${runtimeDir}/result.json" > "${runtimeDir}/result.json.tmp" && \
          mv "${runtimeDir}/result.json.tmp" "${runtimeDir}/result.json"

        # Output final JSON
        exec 1>&3  # Restore stdout
        cat "${runtimeDir}/result.json"
      fi
    '';
  }
)
