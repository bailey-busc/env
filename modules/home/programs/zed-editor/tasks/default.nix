{
  lib,
  config,
  pkgs,
  ...
}:
let
  inherit (lib)
    mkIf
    mkOption
    types
    ;
in
{
  options.programs.zed-editor.tasks = mkOption {
    description = "List of tasks for Zed Editor";
    type = types.listOf (
      types.submodule {
        options = {
          label = mkOption {
            type = types.str;
            default = "";
            description = "Label for the task";
          };
          command = mkOption {
            type = types.str;
            default = "";
            description = "Command to execute";
          };
          args = mkOption {
            type = types.listOf types.str;
            default = [ ];
            description = "Arguments to pass to the command";
          };
          env = mkOption {
            type = types.attrsOf types.str;
            default = { };
            description = "Environment variables to set for the task";
          };
          cwd = mkOption {
            type = types.str;
            default = "";
            description = "Current working directory to spawn the command into, defaults to current project root.";
          };
          use_new_terminal = mkOption {
            type = types.bool;
            default = false;
            description = "Whether to use a new terminal tab or reuse the existing one to spawn the process.";
          };
          allow_concurrent_runs = mkOption {
            type = types.bool;
            default = false;
            description = "Whether to allow multiple instances of the same task to be run, or rather wait for the existing ones to finish.";
          };
          reveal = mkOption {
            type = types.enum [
              "always"
              "never"
              "on_error"
            ];
            default = "always";
            description = ''
              What to do with the terminal pane and tab, after the command was started:
              * `always` — always show the task's pane, and focus the corresponding tab in it (default)
              * `no_focus` — always show the task's pane, add the task's tab in it, but don't focus it
              * `never` — do not alter focus, but still add/reuse the task's tab in its pane
            '';
          };
          hide = mkOption {
            type = types.enum [
              "always"
              "never"
              "on_success"
            ];
            default = "never";
            description = ''
              What to do with the terminal pane and tab, after the command has finished:
              * `never` — Do nothing when the command finishes (default)
              * `always` — always hide the terminal tab, hide the pane also if it was the last tab in it
              * `on_success` — hide the terminal tab on task success only, otherwise behaves similar to `always`
            '';
          };
          shell = mkOption {
            type =
              let
                program = mkOption {
                  type = types.either types.package types.str;
                  description = "The shell program to use";
                };
              in
              types.oneOf [
                (types.enum [ "system" ])
                (types.submodule {
                  options = {
                    inherit program;
                  };
                })
                (types.submodule {
                  options = {
                    with_arguments = mkOption {
                      type = types.submodule {
                        options = {
                          inherit program;
                          args = mkOption {
                            type = types.listOf types.str;
                            description = "Arguments to pass to the shell program";
                            default = [ ];
                          };
                        };
                      };
                    };
                  };
                })
              ];
            default = "always";
            description = ''
              Which shell to use when running a task inside the terminal.
              May take 3 values:
              1. (default) Use the system's default terminal configuration in /etc/passwd
                   shell = "system";
              2. A program:
                   shell = {
                     program = "sh";
                   };
              3. A program with arguments:
                  shell = {
                      with_arguments = {
                        program = "/bin/bash";
                        args = ["--login"];
                      };
                  };
            '';
          };
          show_summary = mkOption {
            type = types.bool;
            default = true;
            description = ''
              Whether to show a summary of the task's output in the terminal.
            '';
          };
          show_output = mkOption {
            type = types.bool;
            default = true;
            description = ''
              Whether to show the task's output in the terminal.
            '';
          };
          tags = mkOption {
            type = types.listOf types.str;
            default = [ ];
            description = ''
              Tags to categorize the task.
            '';
          };
        };
      }
    );
    default = [ ];
  };
  # https:#zed.dev/docs/tasks
  config = mkIf (config.programs.zed-editor.tasks != [ ]) {
    xdg.configFile."zed/tasks.json".source =
      config.programs.zed-editor.tasks |> builtins.toJSON |> pkgs.writeText "tasks.json";
  };
}
