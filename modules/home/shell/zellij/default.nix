{
  lib,
  pkgs,
  osConfig,
  config,
  self,
  ...
}:
let
  inherit (lib)
    getExe
    getExe'
    isDerivation
    toList
    ;
  inherit (lib.cli) toGNUCommandLine;
  inherit (self.lib) filterNullAttrs filterNulls mapAttrVals;

  toKDL = self.lib.generators.toKDL { };
  inherit (pkgs.stdenv) isDarwin;
  inherit (pkgs)
    symlinkJoin
    writeTextDir
    ;
  inherit (osConfig.env.hardware) gpu;

  writeShellApplication' =
    name: runtimeInputs: text:
    getExe <| name.writeShellApplication { inherit name runtimeInputs text; };

  #sudo = if osConfig.security.polkit.enable then "pkexec --user ${config.env.username}" else "sudo";
  sudo' = "sudo"; # nixos-rebuild doesn't work under pkexec --user bailey...
  top' = getExe config.programs.btop.package;
  nvtop' =
    getExe
    <| pkgs.nvtopPackages.nvidia.override {
      nvidia = gpu.nvidia.enable;
      amd = gpu.amd.enable;
      apple = isDarwin;
    };
  cat' = getExe pkgs.bat;
  nixfmt' = getExe pkgs.nixfmt-rfc-style;
  fd' = getExe config.programs.fd.package;
  nixos-rebuild' = getExe osConfig.system.build.nixos-rebuild;
  zellij' = getExe config.programs.zellij.package;

  global_session_name = osConfig.networking.hostName;

  element =
    {
      name,
      props ? { },
      args ? [ ],
      children ? [ ],
      config ? { },
    }:
    let
      fixDrv = val: if isDerivation val then getExe val else val;
      fixDrvAttrs = mapAttrVals fixDrv;
      fixDrvs = map fixDrv;
    in
    {
      ${name} = {
        _args = args |> filterNulls |> fixDrvs;
        _children = children |> filterNulls |> fixDrvs;
        _props = props |> filterNullAttrs |> fixDrvAttrs;
      }
      // (config |> filterNullAttrs |> fixDrvAttrs);
    };

  element_ = name: { ${name} = { }; };

  layout =
    children:
    element {
      inherit children;
      name = "layout";
    };

  writeLayout =
    name: layoutContents: layoutContents |> toList |> layout |> toKDL |> writeTextDir "${name}.kdl";

  plugin =
    location: config:
    element {
      inherit config;
      name = "plugin";
      props.location = location;
    };

  plugin' = location: plugin location { };

  pkgPlugin =
    pkg: wasmName: config:
    plugin "file://${getExe' pkg "${wasmName}.wasm"}" config;

  pkgPlugin' = pkg: wasmName: pkgPlugin pkg wasmName { };

  tab =
    {
      name ? null,
      cwd ? null,
    }@props:
    children:
    element {
      inherit props children;
      name = "tab";
    };

  tab_ = name: child: tab { inherit name; } [ child ];

  pane =
    {
      borderless ? false,
      cwd ? null,
      command ? null,
      size ? null,
      split_direction ? null,
    }@props:
    children:
    element {
      inherit props children;
      name = "pane";
    };

  pane' = props: pane props [ ];

  pane_ = props: child: pane props [ child ];

  default_tab_template = element {
    name = "default_tab_template";
    children = [
      (
        pane_ {
          borderless = true;
          size = 1;
        }
        <| plugin' "zellij:tab-bar"
      )
      (element_ "children")
      (
        pane_ {
          borderless = true;
          size = 1;
        }
        <| plugin' "zellij:status-bar"
      )
    ];
  };
  zjframes = pkgPlugin pkgs.zjstatus "zjframes";
  zjstatus = pkgPlugin pkgs.zjstatus "zjstatus";
  zjstatus_tab_template = element {
    name = "default_tab_template";
    children = [
      (
        pane_ {
          borderless = true;
          size = 1;
        }
        <| plugin' "zellij:tab-bar"
      )
      (element_ "children")
      (
        pane_ {
          borderless = true;
          size = 1;
        }
        <| zjstatus {
          format_left = "{mode} #[fg=#89B4FA,bold]{session}";
          format_center = "{tabs}";
          format_right = "{command_git_branch} {datetime}";
          format_space = "";
          border_enabled = "false";
          border_char = "─";
          border_format = "#[fg=#6C7086]{char}";
          border_position = "top";

          hide_frame_for_single_pane = "true";

          mode_normal = "#[bg=blue] ";
          mode_tmux = "#[bg=#ffc387] ";

          tab_normal = "#[fg=#6C7086] {name} ";
          tab_active = "#[fg=#9399B2,bold,italic] {name} ";

          command_git_branch_command = "git rev-parse --abbrev-ref HEAD";
          command_git_branch_format = "#[fg=blue] {stdout} ";
          command_git_branch_interval = "10";
          command_git_branch_rendermode = "static";

          datetime = "#[fg=#6C7086,bold] {format} ";
          datetime_format = "%A, %d %b %Y %H:%M";
          datetime_timezone = osConfig.time.timeZone;
        }
      )
    ];
  };
in
{
  home =
    let
      nrb = pkgs.writeShellScriptBin "nrb" ''
        ${fd'} ".*\.nix$" ${config.programs.nh.flake} -t f -x ${nixfmt'} {}
        ${
          builtins.concatStringsSep " "
          <| lib.flatten
          <| [
            sudo'
            nixos-rebuild'
            "switch"
            (toGNUCommandLine { } {
              accept-flake-config = true;
              flake = "$HOME/env";
            })
            "$@"
          ]
        }
      '';
      nrbb = pkgs.writeShellScriptBin "nrbb" ''
        ${fd'} ".*\.nix$" ${config.programs.nh.flake} -t f -x ${nixfmt'} {}
        ${getExe config.programs.nh.package} os switch --ask $@
      '';
    in
    {
      packages = [
        nrb
        nrbb
        (pkgs.writeShellScriptBin "multitask" ''
          ${zellij'} action start-or-reload-plugin "file://${
            pkgs.fetchurl {
              url = "https://github.com/imsnif/multitask/releases/download/0.41.2/multitask.wasm";
              sha256 = "sha256-J7IH3n1ERtPNg33XsV+2qkOSbW8tsViW1at//ygsOKg=";
            }
          }" --configuration "shell=''${SHELL},ccwd=$(pwd),multitask_file_name=multitask.sh,layout=$(${cat'} ${
            pkgs.fetchurl {
              url = "https://raw.githubusercontent.com/leakec/multitask/f682757eaf5b45b28a84c8bd66b5ed244fa9ee85/src/assets/multitask_layout.kdl";
              sha256 = "sha256-ZKmwTSjlHkEacnaWnCTLW4dzMnqYjkJq7Gs9XOHWL/c=";
            }
          })"
          ${zellij'} action close-pane
        '')
      ];
      shellAliases = {
        nrbzl = "${zellij'} --layout nrb";
        nrbbzl = "${zellij'} --layout nrbb";
      };
      sessionVariables = {
        ZELLIJ_AUTO_EXIT = "false";
      };
      file = {
        ".config/zellij/layouts".source = symlinkJoin {
          name = "zellij-layouts";
          paths = [
            (writeLayout "empty" default_tab_template)
            (writeLayout "nrb" [
              (pane' {
                borderless = true;
                command = nrb;
              })
              (pane' {
                borderless = true;
                command = top';
              })
            ])
            (writeLayout "nrbb" [
              (pane' {
                borderless = true;
                command = nrbb;
              })
              (pane' {
                borderless = true;
                command = top';
              })
            ])
            (writeLayout "default" [
              default_tab_template
              (
                tab_ "env"
                <| pane' {
                  cwd = "~/env";
                }
              )
              (
                tab_ "glimpse"
                <| pane' {
                  cwd = "~/dev/glimpse-engineering/glimpse";
                }
              )
              (
                tab_ "emacs"
                <| pane' {
                  command = pkgs.writeShellScriptBin "magit" "${getExe' config.programs.doom-emacs.finalEmacsPackage "emacsclient"} -nw -e '(magit-status)'";
                  cwd = "~/env";
                }
              )
              (
                tab_ "jj"
                <| pane' {
                  command = getExe pkgs.lazyjj;
                  cwd = "~/dev/glimpse-engineering/glimpse";
                }
              )
              (
                tab_ "nvtop"
                <| pane' {
                  borderless = true;
                  command = nvtop';
                }
              )
              (
                tab_ "top"
                <| pane' {
                  borderless = true;
                  command = top';
                }
              )
              (
                tab_ "sys"
                <|
                  pane
                    {
                      split_direction = "vertical";
                    }
                    [
                      (pane' {
                        borderless = true;
                        command = nvtop';
                      })
                      (pane' {
                        borderless = true;
                        command = top';
                      })
                    ]
              )
            ])
          ];
        };
      };
    };
  programs.zsh = {
    initContent = lib.mkOrder 200 ''
      if [[ "$TERM" == "xterm-ghostty" ]] && [ -z "$ZELLIJ_ATTACHED" ]; then
          export ZELLIJ_ATTACHED=1
          ${zellij'} attach ${global_session_name} || ${zellij'} --session ${global_session_name}
      fi
    '';
  };

  programs.zellij = {
    enable = true;
    enableZshIntegration = false;
    settings = {
      copy_clipboard = "primary";
      copy_command = if isDarwin then "pbcopy" else getExe' pkgs.wl-clipboard "wl-copy";
      pane_frames = false;
      show_release_notes = false;
      show_startup_tips = false;
      support_kitty_keyboard_protocol = false;
      theme = "ansi";
      ui.pane_frames.rounded_corners = true;
      default_shell = "nu";
    };
  };
}
