{
  pkgs,
  lib,
  config,
  osConfig,
  ...
}:
let
  inherit (lib)
    getExe
    getExe'
    hasSuffix
    findFirst
    toLower
    mkIf
    genAttrs
    ;
  inherit (config.env) profiles;

  weightFromFontName =
    fontName:
    let
      weights = rec {
        "Extra Light" = 200;
        ExtraLight = 200;
        Light = 300;
        Regular = 400;
        Medium = 500;
        Semibold = 600;
        Bold = 700;
        ExtraBold = 800;
        "Extra Bold" = 800;
        # If variable font, default to light
        Var = Light;
      };
      fontFamilyWeight = findFirst (weight: hasSuffix (toLower weight) (toLower fontName)) "Regular" (
        builtins.attrNames weights
      );
    in
    weights.${fontFamilyWeight};
in
{
  imports = [
    ./keybindings.nix
  ];
  programs = mkIf profiles.graphical.enable {
    zed-editor = {
      enable = true;
      package = pkgs.zed-editor-preview;
      installRemoteServer = true;
      extensions = [
        # Languages
        "csv"
        "docker-compose"
        "dockerfile"
        "elisp"
        "env"
        "git-firefly"
        "graphql"
        "graphviz"
        "haskell"
        "html"
        "ini"
        # "jinja2"
        # "jsonnet"
        "log"
        # "make"
        "mermaid"
        "nix"
        "nu"
        # "plantuml"
        "powershell"
        # "purescript"
        "proto"
        "sql"
        "scss"
        "ssh-config"
        "strace"
        "terraform"
        "toml"
        "xml"
        "qml"

        # Extensions
        "basedpyright"
        "basher"
        "cargo-tom"
        #"codebook"
        "discord-presence"
        "markdown-oxide"
        "python-refactoring"
        "python-requirements"
        "ruff"
        "snippets"
        "ty"
        "typos"

        # Themes
        "vscode-dark-polished"
        "vscode-dark-modern"
      ];
      extraPackages = with pkgs; [
        # Python
        (python3.withPackages (ps: with ps; [ debugpy ]))
        basedpyright
        ruff

        # Nix
        nil
        statix

        # Haskell
        # haskell.compiler.ghc910
        haskell.compiler.native-bignum.ghc910
        haskellPackages.haskell-language-server
        haskellPackages.stack
        haskellPackages.cabal-install

        # Rust
        rust-analyzer
        rustc
        cargo
        clippy
        rustfmt

        # Terraform
        terraform-ls

        # Plaintext + Markdown
        marksman
        vale
        proselint
        languagetool

        # Shell
        nodePackages.bash-language-server
        shellcheck

        # Structured formats (toml, yaml, etc)
        taplo
        yaml-language-server
        jsonnet
        jsonnet-language-server

        # Webshit
        vscode-langservers-extracted
        nodePackages.eslint_d
        nodePackages.prettier
        nodePackages.diagnostic-languageserver
        nodePackages.typescript-language-server
        nodePackages."@tailwindcss/language-server"

        # QML
        kdePackages.qtdeclarative

        # C/C++
        # ???
      ];
      themes.${config.scheme.slug} = {
        name = config.scheme.scheme-name;
        author = config.scheme.scheme-author;
        "$schema" = "https://zed.dev/schema/themes/v0.2.0.json";
        themes = [
          (import ./themes/base16.nix { inherit (config) scheme; })
        ];
      };
      userSettings = {
        auto_update = false;
        telemetry = {
          diagnostics = true;
          metrics = false;
        };
        projects_online_by_default = false;

        vim_mode = false;
        vim = {
          default_mode = "helix_normal";
          use_system_clipboard = "always";
          use_multiline_find = true;
          use_smartcase_find = true;
        };

        icon_theme = {
          mode = "dark";
          dark = "JetBrains New UI Icons (Dark)";
          light = "JetBrains New UI Icons (Light)";
        };
        theme = {
          mode = "dark";
          dark = "VSCode Dark Modern";
          light = "One Light";
        };

        journal = {
          path = "~";
          hour_format = "hour12";
        };

        ui_font_family = osConfig.env.theme.fonts.editor.ui.name;
        ui_font_size = 17;
        ui_font_weight = weightFromFontName osConfig.env.theme.fonts.editor.ui.name;
        ui_font_features.calt = false;

        buffer_font_family = osConfig.env.theme.fonts.editor.buffer.name;
        buffer_font_weight = weightFromFontName osConfig.env.theme.fonts.editor.buffer.name;
        buffer_font_size = 14;
        buffer_line_height = "comfortable";
        buffer_font_features = genAttrs [
          "calt"
          "liga"
          "zero"
          "ss01"
          "ss02"
          "ss03"
          "ss04"
          "ss05"
          "ss06"
          "ss07"
          "ss08"
          "ss09"
        ] (_: true);

        agent = {
          enabled = true;
          version = "2";
          always_allow_tool_actions = true;
          default_model = {
            provider = "openrouter";
            model = "anthropic/claude-sonnet-4";
          };
        };
        edit_predictions = {
          mode = "subtle";
          disabled_globs = [
            "**/.env*"
            "**/*.pem"
            "**/*.key"
            "**/*.cert"
            "**/*.crt"
            "**/.dev.vars"
            "**/secrets.yml"
            "**/*.lock"
          ];
        };
        edit_predictions_disabled_in = [
          "comment"
          "string"
        ];
        git = {
          gutter_debounce = 150; # milliseconds
          inline_blame = {
            enabled = true;
            delay_ms = 500;
          };
        };

        inlay_hints = {
          enabled = true;
          show_type_hints = true;
          show_parameter_hints = true;
          show_other_hints = true;
          show_background = false;
          edit_debounce_ms = 700;
          scroll_debounce_ms = 50;
          toggle_on_modifiers_press = null;
        };
        diagnostics = {
          use_rendered = true;
          update_with_cursor = true;
          include_warnings = true;
          inline = {
            enabled = true;
            padding = 8;
            min_column = 80;
            update_debounce_ms = 150;
          };
        };

        autosave = "on_focus_change";
        remove_trailing_whitespace_on_save = true;

        search = {
          whole_word = false;
          case_sensitive = true;
          include_ignored = false;
          regex = false;
        };
        file_scan_exclusions = [
          "**/*.lock"
          # Defaults
          "**/.git"
          "**/.svn"
          "**/.hg"
          "**/.jj"
          "**/CVS"
          "**/.DS_Store"
          "**/Thumbs.db"
          "**/.classpath"
          "**/.settings"
        ];
        seed_search_query_from_cursor = "selection";
        use_smartcase_search = true;

        completions = {
          words = "fallback";
          lsp = true;
          lsp_fetch_timeout_ms = 0;
          lsp_insert_mode = "insert";
        };
        show_completions_on_input = true;
        show_completion_documentation = true;
        show_edit_predictions = true;

        show_whitespaces = "selection";
        soft_wrap = "none";

        current_line_highlight = "gutter";

        terminal = {
          alternate_scroll = "off";
          blinking = "terminal_controlled";
          copy_on_select = true;
          dock = "bottom";
          default_width = 640;
          default_height = 320;
          detect_venv.on = {
            directories = [
              ".nix-venv"
              "nix-venv"
              ".venv"
              "venv"
            ];
            activate_script = "default";
          };
          env = {
            TERM_PROGRAM = "zed";
            ZED = "1";
            EDITOR = config.home.sessionVariables.VISUAL;
          };
          font_family = osConfig.env.theme.fonts.terminal.name;
          line_height = "comfortable";
          option_as_meta = false;
          button = true;
          shell = "system";
          toolbar.breadcrumbs = true;
          working_directory = "current_project_directory";
          scrollbar.show = null;
        };
        features = {
          # edit_prediction_provider = "copilot";
          # edit_prediction_provider = "supermaven";
        };
        preview_tabs = {
          enabled = true;
          enable_preview_from_file_finder = false;
          enable_preview_from_code_navigation = false;
        };
        tabs = {
          file_icons = true;
          git_status = true;
          activate_on_close = "left_neighbour";
          show_diagnostics = "errors";
        };
        load_direnv = "direct";
        minimap = {
          show = "auto";
          thumb = "always";
          thumb_border = "left_open";
          current_line_highlight = "line";
          display_in = "active_editor";
        };
        indent_guides = {
          enabled = true;
          line_width = 1;
          active_line_width = 1;
          coloring = "indent_aware";
          background_coloring = "disabled";
        };

        calls.mute_on_join = true;

        unnecessary_code_fade = 0.5;
        inline_code_actions = true;
        lsp_document_colors = "inlay";
        lsp = {
          json-language-server = {
            binary = {
              path = getExe pkgs.nodePackages_latest.vscode-json-languageserver;
              arguments = [ "--stdio" ];
            };
          };
          qml.binary = {
            path = getExe' pkgs.kdePackages.qtdeclarative "qmlls";
            arguments = [ "-E" ];
          };
          nil = {
            binary.path = getExe pkgs.nil;
            initialization_options = {
              formatting.command = [ (getExe pkgs.nixfmt-rfc-style) ];
              nix = {
                binary = "/run/current-system/sw/bin/nix";
                maxMemoryMb = 64 * 1024; # 64GB
                flake = {
                  autoArchive = true;
                  autoEvalInputs = true;
                  nixpkgsInputName = "nixpkgs";
                };
              };
            };
          };
          discord_presence.initialization_options = {
            # base_icons_url = "https://raw.githubusercontent.com/xhyrom/zed-discord-presence/main/assets/icons/";
            state = "Working on {filename}";
            details = "In {workspace}";
            # large_image = "{base_icons_url}/{language:lo}.png"; # :lo lowercase the language name
            # large_text = "{language:u}"; # :u capitalizes the first letter
            # URL for the small image
            # small_image = "{base_icons_url}/zed.png";
            # small_text = "Zed";

            # Idle settings - when you're inactive
            idle = {
              timeout = 5 * 60; # Idle timeout in seconds (300 seconds = 5 minutes)
              # Action to take when idle
              # `change_activity` - changes the activity to idle with the following details
              # `clear_activity` - clears the activity (hides it)
              action = "change_activity";

              state = "Idling";
              details = "In Zed";
              # large_image = "{base_icons_url}/zed.png";
              large_text = "Zed";
              # small_image = "{base_icons_url}/idle.png";
              small_text = "Idle";
            };

            # Rules to disable presence in specific workspaces
            # rules = {
            #   mode = "blacklist"; # Can also be "whitelist"
            #   paths = [ ];
            # };

            git_integration = false;
          };
          typos.binary.path = getExe pkgs.typos-lsp;
          ty.binary = {
            path = getExe pkgs.ty;
            arguments = [ "server" ];
          };
          ruff.binary = {
            path = getExe pkgs.ruff;
            arguments = [ "server" ];
          };
          rust-analyzer = {
            initialization_options = {
              checkOnSave = true;
              check.workspace = false;
              hover.actions.references.enable = true;
              completion = {
                fullFunctionSignatures.enable = true;
              };
            };
          };
        };

        languages = {
          Markdown = {
            format_on_save = "on";
            preferred_line_length = 120;
            soft_wrap = "preferred_line_length";
          };
          Nix.language_servers = [
            "nil"
            "!nixd"
          ];
          Nu = {
            format_on_save = "off";
            # formatter.external = {
            #   command = getExe pkgs.nufmt;
            #   arguments = [ "--stdin" ];
            # };
          };
          QML = {
            format_on_save = "on";
            formatter.external = {
              command =
                getExe
                <| pkgs.writeShellApplication {
                  name = "qmlformat";
                  runtimeInputs = with pkgs; [
                    kdePackages.qtdeclarative
                    coreutils
                    gnused
                  ];
                  text = ''
                    tmp=$(mktemp --suffix=.qml)
                    cat - > "$tmp"
                    qmlformat --normalize --objects-spacing --functions-spacing "$tmp"
                    rm "$tmp"
                  '';
                };
              arguments = [

                "/dev/stdin"
              ];
            };
          };
          Python = {
            language_servers = [
              "!pyright"
              "basedpyright"
              "ruff"
              "ty"
            ];
            formatter = [
              {
                code_actions = {
                  "source.organizeImports.ruff" = true;
                  "source.fixAll.ruff" = true;
                };
              }
              {
                language_server.name = "ruff";
              }
            ];
            format_on_save = "on";
          };
        };
        dap = {
          CodeLLDB = {
            binary = "";
          };
          Debugpy = {
            binary = "";
          };
        };
      };
      snippets = {
        typescript = {
          desc = {
            body = [
              "describe('${"1:name"}', () => {"
              "  $0"
              "})"
            ];
          };
        };
        nix = {
          svc = {
            body = [
              "$1 = {"
              "  enable = true;"
              "};"
            ];
          };
        };
      };
      tasks = [
        {
          label = "NixOS Rebuild";
          command = "nrb";
          use_new_terminal = true;
          allow_concurrent_runs = false;
          # What to do with the terminal pane and tab, after the command was started:
          # * `always` — always show the task's pane, and focus the corresponding tab in it (default)
          # * `no_focus` — always show the task's pane, add the task's tab in it, but don't focus it
          # * `never` — do not alter focus, but still add/reuse the task's tab in its pane
          reveal = "always";
          hide = "on_success";
          shell = "system";
          show_summary = true;
          show_output = true;
          tags = [ "nix" ];
        }
      ];
      context-servers.enable = true;
    };
    git.ignores = [
      ".helix/"
      ".zed/"
    ];
  };
}
