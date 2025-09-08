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
  { config, ... }: config.home-manager.users.${config.env.username}.programs.rofi.enable
) ({ config, ... }: config.home-manager.users.${config.env.username})
|> mapAttrs' (
  name: homeConfig:
  let
    runtimeDir = "/tmp/check-rofi-config-${name}-tmpdir";
  in
  {
    name = "rofi-config-${name}";
    value = pkgs.writeShellScriptBin "check-rofi-config-${name}" ''
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
            "check": "rofi-config",
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

          log_message "=== ROFI CONFIG CHECK FOR ${name} ==="

          # Find config files
          config_file=""
          theme_file=""
          config_dir="${homeConfig.xdg.configHome}/rofi"

          # Check for Nix-managed config files
          ${lib.optionalString (homeConfig.xdg.configFile ? "rofi/config.rasi") ''
            config_file="${homeConfig.xdg.configFile."rofi/config.rasi".source}"
          ''}
          ${lib.optionalString (homeConfig.xdg.configFile ? "rofi/config") ''
            [ -z "$config_file" ] && config_file="${homeConfig.xdg.configFile."rofi/config".source}"
          ''}
          ${lib.optionalString (homeConfig.xdg.configFile ? "rofi/theme.rasi") ''
            theme_file="${homeConfig.xdg.configFile."rofi/theme.rasi".source}"
          ''}

          add_info "config_file" "''${config_file:-Not found}"
          add_info "theme_file" "''${theme_file:-Not found}"
          log_message "Config file: ''${config_file:-"Not found"}"
          log_message "Theme file: ''${theme_file:-"Not found"}"
          log_message ""

          # Create test environment
          export XDG_RUNTIME_DIR="${runtimeDir}"
          export XDG_CONFIG_HOME="${runtimeDir}/config"
          export HOME="${runtimeDir}/home"
          # Prevent rofi from trying to connect to display
          unset DISPLAY
          unset WAYLAND_DISPLAY
          export ROFI_NO_DISPLAY=1
          mkdir -p "${runtimeDir}/config/rofi"
          mkdir -p "${runtimeDir}/home"

          # === CONFIGURATION ANALYSIS ===
          log_message "=== CONFIGURATION ANALYSIS ==="

          # Check if using Nix-generated theme
          if ${lib.boolToString (homeConfig.programs.rofi.theme != null)}; then
            add_check_result "theme_source" "pass" "Using Nix-generated theme" ""
            add_info "theme_type" "nix"

            # Extract theme configuration from Nix
            log_message ""
            log_message "Theme configuration summary:"
            add_info "terminal" "${homeConfig.programs.rofi.terminal or "default"}"
            add_info "plugin_count" "${
              toString (builtins.length (homeConfig.programs.rofi.plugins or [ ]))
            }"
            log_message "  Terminal: ${homeConfig.programs.rofi.terminal or "default"}"
            log_message "  Plugins: ${
              toString (builtins.length (homeConfig.programs.rofi.plugins or [ ]))
            }"

            if [ ${toString (builtins.length (homeConfig.programs.rofi.plugins or [ ]))} -gt 0 ]; then
              log_message ""
              log_message "Installed plugins:"
              ${lib.concatMapStringsSep "\n" (plugin: ''
                log_message "  - ${plugin.pname or plugin.name or "unknown"}"
              '') (homeConfig.programs.rofi.plugins or [ ])}

              if [ "$JSON_OUTPUT" = true ]; then
                plugins_json='['
                ${lib.concatMapStringsSep "\n" (plugin: ''
                  plugins_json="$plugins_json\"${plugin.pname or plugin.name or "unknown"}\","
                '') (homeConfig.programs.rofi.plugins or [ ])}
                plugins_json="''${plugins_json%,}]"
                ${getExe pkgs.jq} --argjson plugins "$plugins_json" '.info.plugins = $plugins' \
                  "${runtimeDir}/result.json" > "${runtimeDir}/result.json.tmp" && \
                  mv "${runtimeDir}/result.json.tmp" "${runtimeDir}/result.json"
              fi
            fi
          else
            add_info "theme_type" "unknown"
          fi

          # === ROFI VALIDATION ===
          log_message ""
          log_message "=== ROFI CLI VALIDATION ==="

          # Test rofi configuration loading
          log_message "Testing rofi configuration..."

          # Create a minimal valid config for testing if no config exists
          if [ -z "$config_file" ] && [ -z "$theme_file" ]; then
            cat > "${runtimeDir}/config/rofi/config.rasi" <<'EOF'
      configuration {
          modes: [ "drun", "run" ];
      }
      EOF
            add_info "config_source" "minimal_generated"
          else
            [ -n "$config_file" ] && cp "$config_file" "${runtimeDir}/config/rofi/config.rasi"
            [ -n "$theme_file" ] && cp "$theme_file" "${runtimeDir}/config/rofi/theme.rasi"
            add_info "config_source" "user_provided"
          fi

          # Run rofi -rasi-validate to validate configuration
          log_message ""
          log_message "Validating configuration syntax..."
          if [ -f "${runtimeDir}/config/rofi/config.rasi" ]; then
            # Check if file is not empty
            if [ ! -s "${runtimeDir}/config/rofi/config.rasi" ]; then
              add_check_result "config_syntax" "fail" "Configuration file is empty" ""
            else
              # Run validation with timeout to catch segfaults
              if timeout 5s ${getExe homeConfig.programs.rofi.finalPackage} -rasi-validate "${runtimeDir}/config/rofi/config.rasi" >/dev/null 2>"${runtimeDir}/rofi-validate.err"; then
                add_check_result "config_syntax" "pass" "Configuration syntax is valid" ""
              else
                exit_code=$?
                if [ $exit_code -eq 124 ]; then
                  add_check_result "config_syntax" "fail" "Configuration validation timed out (possible crash)" ""
                elif [ $exit_code -eq 139 ]; then
                  add_check_result "config_syntax" "fail" "Configuration validation crashed (segmentation fault)" ""
                else
                  errors=$(cat "${runtimeDir}/rofi-validate.err" 2>/dev/null | grep -v "^$" | head -10)
                  if [ -z "$errors" ]; then
                    errors="Validation failed with exit code $exit_code"
                  fi
                  add_check_result "config_syntax" "fail" "Configuration syntax errors detected" "$errors"
                fi
              fi
            fi
          else
            add_check_result "config_syntax" "skip" "No configuration file to validate" ""
          fi

          # Test rofi theme validation
          log_message ""
          log_message "Validating theme..."
          if [ -f "${runtimeDir}/config/rofi/theme.rasi" ]; then
            if [ ! -s "${runtimeDir}/config/rofi/theme.rasi" ]; then
              add_check_result "theme_syntax" "fail" "Theme file is empty" ""
            else
              if timeout 5s ${getExe homeConfig.programs.rofi.finalPackage} -rasi-validate "${runtimeDir}/config/rofi/theme.rasi" >/dev/null 2>"${runtimeDir}/rofi-theme-validate.err"; then
                add_check_result "theme_syntax" "pass" "Theme syntax is valid" ""
              else
                exit_code=$?
                if [ $exit_code -eq 124 ]; then
                  add_check_result "theme_syntax" "fail" "Theme validation timed out (possible crash)" ""
                elif [ $exit_code -eq 139 ]; then
                  add_check_result "theme_syntax" "fail" "Theme validation crashed (segmentation fault)" ""
                else
                  errors=$(cat "${runtimeDir}/rofi-theme-validate.err" 2>/dev/null | grep -v "^$" | head -10)
                  if [ -z "$errors" ]; then
                    errors="Validation failed with exit code $exit_code"
                  fi
                  add_check_result "theme_syntax" "fail" "Theme syntax errors detected" "$errors"
                fi
              fi
            fi
          elif [ -f "${runtimeDir}/config/rofi/config.rasi" ]; then
            # Check if theme is embedded in config
            log_message "  Checking for embedded theme in config..."
            if grep -q "@theme" "${runtimeDir}/config/rofi/config.rasi" || grep -q "^[[:space:]]*\*[[:space:]]*{" "${runtimeDir}/config/rofi/config.rasi"; then
              add_check_result "theme_syntax" "skip" "Theme appears to be embedded in config (already validated)" ""
            else
              add_check_result "theme_syntax" "skip" "No separate theme file found" ""
            fi
          else
            add_check_result "theme_syntax" "skip" "No theme file to validate" ""
          fi

          # === PLUGIN VALIDATION ===
          log_message ""
          log_message "=== PLUGIN VALIDATION ==="

          # Check if plugins are properly loaded
          log_message "Checking available modi..."
          # Try with -help first since it might work without display
          available_modi=$(${getExe homeConfig.programs.rofi.finalPackage} -help 2>/dev/null | grep -A20 "Detected modi" | grep -E "^\s+\*" | sed 's/^\s*\*\s*//' || echo "")

          if [ -n "$available_modi" ]; then
            log_message "Available modi:"
            log_message "$available_modi" | sed 's/^/  /'

            # Store modi info in JSON
            if [ "$JSON_OUTPUT" = true ]; then
              modi_json=$(echo "$available_modi" | ${getExe pkgs.jq} -Rs 'split("\n") | map(select(. != ""))')
              ${getExe pkgs.jq} --argjson modi "$modi_json" '.info.available_modi = $modi' \
                "${runtimeDir}/result.json" > "${runtimeDir}/result.json.tmp" && \
                mv "${runtimeDir}/result.json.tmp" "${runtimeDir}/result.json"
            fi

            # Check for plugin-specific modi
            log_message ""
            log_message "Plugin modi detected:"
            plugin_modi=$(echo "$available_modi" | grep -v -E "^(run|window|windowcd|drun|ssh|keys|filebrowser|combi)" || echo "")
            if [ -n "$plugin_modi" ]; then
              log_message "$plugin_modi" | sed 's/^/  /'
              add_check_result "plugin_modi" "pass" "Plugin modi detected" "$plugin_modi"
            else
              log_message "  No additional plugin modi found"
              add_check_result "plugin_modi" "warning" "No additional plugin modi found" ""
            fi
          else
            add_check_result "modi_detection" "skip" "Modi list not available in headless environment" "This is normal for CI/test environments"
          fi

          # === RASI SYNTAX VALIDATION ===
          if [ -n "$config_file" ] || [ -n "$theme_file" ]; then
            log_message ""
            log_message "=== RASI SYNTAX CHECK ==="

            # Basic RASI syntax checks
            # Check for common RASI issues and validate with rofi
            for file in "$config_file" "$theme_file"; do
              if [ -n "$file" ] && [ -f "$file" ]; then
                file_basename=$(basename "$file")
                log_message ""
                log_message "Checking $file_basename..."

                # Validate RASI syntax with rofi
                if timeout 5s ${getExe homeConfig.programs.rofi.finalPackage} -rasi-validate "$file" >/dev/null 2>"${runtimeDir}/rasi-validate-$file_basename.err"; then
                  add_check_result "rasi_syntax_$file_basename" "pass" "RASI syntax is valid in $file_basename" ""
                else
                  exit_code=$?
                  if [ $exit_code -eq 124 ]; then
                    add_check_result "rasi_syntax_$file_basename" "fail" "Validation timed out for $file_basename" ""
                  elif [ $exit_code -eq 139 ]; then
                    add_check_result "rasi_syntax_$file_basename" "fail" "Validation crashed for $file_basename" ""
                  else
                    errors=$(cat "${runtimeDir}/rasi-validate-$file_basename.err" 2>/dev/null | grep -v "^$" | head -5)
                    if [ -z "$errors" ]; then
                      errors="Validation failed with exit code $exit_code"
                    fi
                    add_check_result "rasi_syntax_$file_basename" "fail" "RASI syntax errors in $file_basename" "$errors"
                  fi
                fi

                # Check for common RASI issues
                has_import=false
                has_theme=false
                if grep -q "@import" "$file" 2>/dev/null; then
                  has_import=true
                  log_message "  ℹ Uses @import statements"
                fi

                if grep -q "@theme" "$file" 2>/dev/null; then
                  has_theme=true
                  log_message "  ℹ Uses @theme directive"
                fi

                # Count selectors and properties
                selectors=$(grep -c '^[[:space:]]*[a-zA-Z#.*-][^{]*{' "$file" 2>/dev/null || echo 0)
                log_message "  Selectors found: $selectors"

                if [ "$JSON_OUTPUT" = true ]; then
                  file_info="{\"selectors\": $selectors, \"has_import\": $has_import, \"has_theme\": $has_theme}"
                  ${getExe pkgs.jq} --arg file "$file_basename" --argjson info "$file_info" \
                    '.info.rasi_files[$file] = $info' \
                    "${runtimeDir}/result.json" > "${runtimeDir}/result.json.tmp" && \
                    mv "${runtimeDir}/result.json.tmp" "${runtimeDir}/result.json"
                fi
              fi
            done
          fi

          # === COMMON CONFIGURATION CHECKS ===
          log_message ""
          log_message "=== COMMON CONFIGURATION CHECKS ==="

          # Check for deprecated options
          log_message "Checking for deprecated options..."
          if [ -n "$config_file" ] && grep -q -E "(line-margin|line-padding|hide-scrollbar)" "$config_file" 2>/dev/null; then
            deprecated=$(grep -E "(line-margin|line-padding|hide-scrollbar)" "$config_file" | head -5)
            add_check_result "deprecated_options" "warning" "Deprecated options detected - these should be moved to theme" "$deprecated"
          else
            add_check_result "deprecated_options" "pass" "No deprecated options found" ""
          fi

          # Check theme completeness
          log_message ""
          log_message "Checking theme completeness..."
          essential_elements="window mainbox inputbar entry listview element element-text"
          missing_elements=""

          for element in $essential_elements; do
            if [ -n "$theme_file" ]; then
              if ! grep -q "^[[:space:]]*$element[[:space:]]*{" "$theme_file" 2>/dev/null && \
                 ! ${getExe homeConfig.programs.rofi.finalPackage} -dump-theme 2>/dev/null | grep -q "^[[:space:]]*$element[[:space:]]*{"; then
                missing_elements="$missing_elements $element"
              fi
            fi
          done

          if [ -z "$missing_elements" ]; then
            add_check_result "theme_completeness" "pass" "All essential theme elements are defined" ""
          else
            add_check_result "theme_completeness" "warning" "Missing theme elements" "Missing:$missing_elements"
          fi

          # === FUNCTIONALITY TESTS ===
          log_message ""
          log_message "=== FUNCTIONALITY TESTS ==="

          # Test basic rofi functionality
          log_message "Testing rofi help output..."
          if ${getExe homeConfig.programs.rofi.finalPackage} -version >/dev/null 2>&1; then
            version=$(${getExe homeConfig.programs.rofi.finalPackage} -version 2>&1 | head -1)
            add_check_result "rofi_binary" "pass" "Rofi binary is functional" "Version: $version"
            add_info "rofi_version" "$version"
          else
            add_check_result "rofi_binary" "fail" "Rofi binary test failed" ""
          fi

          # Check configuration files directly
          log_message ""
          log_message "Checking configuration structure..."
          if [ -n "$config_file" ] && [ -f "$config_file" ]; then
            add_check_result "config_structure" "pass" "Configuration file exists" ""
          elif ${lib.boolToString (homeConfig.programs.rofi.theme != null)}; then
            add_check_result "config_structure" "pass" "Using Nix-managed theme configuration" ""
          else
            add_check_result "config_structure" "warning" "No configuration file found" ""
          fi

          # === VALIDATION SUMMARY ===
          log_message ""
          log_message "=== VALIDATION SUMMARY ==="
          log_message "Rofi configuration check completed for host: ${name}"

          # Summary based on what we could check
          log_message "Note: Full validation requires a display environment"
          log_message "Basic configuration structure has been verified"

          log_message ""
          log_message "=== RECOMMENDATIONS ==="
          log_message "1. Ensure all custom modi/plugins are properly installed"
          log_message "2. Verify theme colors are defined using proper RASI syntax"
          log_message "3. Check that font names match installed system fonts"
          log_message "4. Test all configured keybindings in actual usage"
          log_message "5. Consider using 'rofi -dump-config' to see effective configuration"

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
