{
  pkgs,
  lib,
  config,
  osConfig,
  self,
  ...
}@modArgs:
let
  inherit (pkgs)
    stdenv
    ;
  inherit (stdenv)
    isLinux
    ;
  inherit (lib)
    optional
    optionals
    mkIf
    mkMerge
    getAttrFromPath
    ;
  inherit (self.lib.modules)
    filterMkIfFromAttrs
    ;
  inherit (config.env) profiles;
  isEditor = editorName: config.programs.vscode.package.pname == editorName;
  isCodium = isEditor "vscodium";
  isCursor = isEditor "cursor";
  themeExt =
    with marketplace-extensions;
    if isCodium then ankitpati.vscodium-amoled else t3m1n4l.amoled-github;
  theme =
    if (!isCursor) then
      builtins.readFile "${themeExt}/share/vscode/extensions/${themeExt.vscodeExtUniqueId}/package.json"
      |> builtins.fromJSON
      |> getAttrFromPath [
        "contributes"
        "themes"
      ]
      |> builtins.head
      |> builtins.getAttr "label"
    else
      "Cursor Dark High Contrast";
  marketplace-extensions = if isCodium then pkgs.open-vsx else pkgs.vscode-marketplace;
  mcpSettings = import ./mcp.nix modArgs;
in
mkIf profiles.graphical.enable {
  programs.vscode = {
    enable = true;
    package = pkgs.code-cursor;
    profiles.default = {
      enableUpdateCheck = false;
      enableExtensionUpdateCheck = false;
      extensions = mkMerge (
        with marketplace-extensions;
        [
          [
            # AI
            kilocode.kilo-code

            # Python
            (if isCodium then ms-pyright.pyright else ms-python.vscode-pylance)
            ms-python.python
            ms-python.debugpy

            charliermarsh.ruff
            ms-toolsai.jupyter
            ms-toolsai.jupyter-renderers
            ms-toolsai.vscode-jupyter-cell-tags
            fill-labs.dependi

            # Nix
            jnoortheen.nix-ide

            # Cloud
            hashicorp.terraform

            # Rust
            rust-lang.rust-analyzer
            #vadimcn.vscode-lldb
            tamasfe.even-better-toml
            fill-labs.dependi

            # Haskell
            haskell.haskell

            # Databases
            ms-ossdata.vscode-pgsql

            # Languages
            redhat.vscode-xml
            redhat.vscode-yaml

            # Other
            gruntfuggly.todo-tree
            esbenp.prettier-vscode
            hediet.vscode-drawio
            nopeslide.vscode-drawio-plugin-mermaid
            ruschaaf.extended-embedded-languages
            bierner.markdown-mermaid

            # Themes
            penumbratheme.penumbra
            davidbwaters.macos-modern-theme
          ]
          (mkIf (!isCursor) [
            continue.continue
            themeExt
          ])
          (mkIf (!isCodium) [
            ms-vsliveshare.vsliveshare
            ms-vscode-remote.remote-ssh
          ])

        ]

      );
      userSettings = mkMerge [
        {
          # AI
          "kilo-code.allowedCommands" = [
            "cat"
            "cd"
            "chmod"
            "chown"
            "cp"
            "dig"
            "find"
            "git diff"
            "git log"
            "git show"
            "grep"
            "head"
            "jq"
            "ls"
            "mkdir"
            "mv"
            "nix"
            "npm install"
            "npm test"
            "python"
            "tail"
            "tsc"
            "yq"
          ];

          # Python
          "[python]"."editor.defaultFormatter" = "charliermarsh.ruff";
          "ruff.path" = lib.getExe pkgs.ruff;

          # Nix
          "[nix]"."editor.defaultFormatter" = "jnoortheen.nix-ide";
          "nix.formatterPath" = lib.getExe pkgs.nixfmt-rfc-style;
          "nix.enableLanguageServer" = true;
          "nix.serverPath" = lib.getExe pkgs.nil;
          "nix.hiddenLanguageServerErrors" = [ ];
          "nix.serverSettings".nil = {
            nix = {
              binary = "/run/current-system/sw/bin/nix";
              maxMemoryMb = 16 * 1024; # 16GB
              flake = {
                autoArchive = true;
                autoEvalInputs = false;
                nixpkgsInputName = "nixpkgs";
              };
            };
            formatting.command = [ (lib.getExe pkgs.nixfmt-rfc-style) ];
          };

          # Cloud
          "[terraform]"."editor.defaultFormatter" = "hashicorp.terraform";
          "terraform.experimentalFeatures.validateOnSave" = true;

          # Rust
          "rust-analyzer.checkOnSave" = true;
          "rust-analyzer.restartServerOnConfigChange" = true;

          "editor.fontFamily" = "'${osConfig.env.theme.fonts.editor.buffer.name}', monospace";
          "editor.fontSize" = 14;
          "editor.fontVariations" = "'wght' 350";
          "editor.inlineSuggest.fontFamily" = "'${osConfig.env.theme.fonts.editor.suggest.name}', monospace";
          "editor.fontLigatures" =
            "'calt', 'liga', 'ss01', 'ss02', 'ss03', 'ss04', 'ss05', 'ss06', 'ss07', 'ss08', 'ss09'";
          "editor.renderWhitespace" = "selection";
          "editor.cursorStyle" = "line";
          "editor.multiCursorModifier" = "alt";
          "editor.detectIndentation" = true;
          "editor.insertSpaces" = true;
          "terminal.integrated.fontFamily" = "${osConfig.env.theme.fonts.terminal.name}, monospace";
          "terminal.integrated.fontSize" = 13;
          "terminal.integrated.fontWeight" = 500;
          "terminal.integrated.fontWeightBold" = 800;

          "workbench.colorTheme" = theme;
          "workbench.preferredDarkColorTheme" = theme;
          "workbench.commandPalette.preserveInput" = true;

          "files.autoSave" = "afterDelay";
          "files.autoSaveDelay" = 1000;
          "files.exclude" = {
            "**/.git" = true;
            "**/.jj" = true;
            "**/.svn" = true;
            "**/.hg" = true;
            "**/.DS_Store" = true;
            "**/Thumbs.db" = true;
          };
          "files.participants.timeout" = 15 * 1000; # 15s
          "files.readonlyFromPermissions" = true;
          "files.saveConflictResolution" = "askUser";
          "files.watcherExclude" = {
            "**/.git/objects/**" = true;
            "**/.git/subtree-cache/**" = true;
            "**/.hg/store/**" = true;
            "**/.jj/**" = true;
          };
          "window.autoDetectColorScheme" = false;
          "window.autoDetectHighContrast" = false;
          "window.closeWhenEmpty" = false;
          "editor.formatOnSave" = true;
          "window.title" =
            "$${dirty}$${activeEditorShort}$${separator}$${rootName}$${separator}$${profileName}$${separator}$${appName}";

          "[xml]"."editor.defaultFormatter" = "redhat.vscode-xml";
          "[yaml]"."editor.defaultFormatter" = "redhat.vscode-yaml";
          "[html]"."editor.defaultFormatter" = "esbenp.prettier-vscode";
          "[json]"."editor.defaultFormatter" = "esbenp.prettier-vscode";
          "[jsonc]"."editor.defaultFormatter" = "esbenp.prettier-vscode";
          "[markdown]"."editor.defaultFormatter" = "esbenp.prettier-vscode";

          "yaml.schemas" = {
            "${config.home.homeDirectory}/.cursor/extensions/continue.continue/config-yaml-schema.json" = [
              ".continue/**/*.yaml"
            ];
          };

          # Turn off garbo
          "redhat.telemetry.enabled" = false;
          "telemetry.telemetryLevel" = "off";
          "telemetry.feedback.enabled" = false;
          "workbench.enableExperiments" = false;
          "workbench.cloudChanges.continueOn" = "off";
          "workbench.experimental.cloudChanges.autoStore" = "off";
          "workbench.experimental.cloudChanges.partialMatches.enabled" = false;
        }
        (mkIf (!isCursor) {
          "continue.telemetryEnabled" = false;
          "cline.chromeExecutablePath" = lib.getExe pkgs.chromium;
        })

        (mkIf isCursor {
          "cursor.cpp.enablePartialAccepts" = true;
          "cursor.composer.shouldAllowCustomModes" = true;
        })
      ];
    };

    mutableExtensionsDir = false;
  };
  home = {
    packages = mkIf (stdenv.hostPlatform.isx86 && isLinux) (
      with pkgs;
      [
        # Live share
        desktop-file-utils
        libsecret

        xorg.xprop
        gnome-keyring
        xorg.libX11
      ]
    );
    file = mkMerge [
      (mkIf (!isCursor) {
        ".config/Code/User/globalStorage/kilocode.kilo-code/settings/mcp_settings.json".text =
          builtins.toJSON mcpSettings;
        ".config/Code/User/globalStorage/kilocode.kilo-code/settings/custom_modes.json".text =
          builtins.toJSON
            {
              "customModes" = [
                {
                  "slug" = "brainstorm";
                  "name" = "Brainstorm";
                  "roleDefinition" =
                    "You are a specialized software specification writer and technical documenter. Your purpose is to transform brainstorming sessions into detailed, actionable technical specifications that bridge the gap between product vision and development implementation.";
                  "whenToUse" = "When brainstorming solutions to complex technical problems";
                  "customInstructions" = builtins.readFile ../../../ai/prompts/data/001-brainstorm.xml;
                  "groups" = [
                    "read"
                    "edit"
                    "browser"
                    "command"
                    "mcp"
                  ];
                  "source" = "global";
                }
              ];
            };
      })
      (mkIf isCursor {
        ".cursor/mcp.json".text = builtins.toJSON mcpSettings;
      })
    ];
  };
}
