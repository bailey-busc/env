{
  lib,
  config,
  ...
}:
let
  inherit (lib)
    mkIf
    ;
  inherit (config.env) profiles;
in
mkIf profiles.graphical.enable {
  programs.zed-editor.userKeymaps = [
    {
      context = "Editor";
      bindings = {
        # "ctrl-right" = [
        #   "editor::MoveToEndOfLine"
        #   { "stop_at_soft_wraps" = true; }
        # ];
        # "ctrl-left" = [
        #   "editor::MoveToBeginningOfLine"
        #   {
        #     "stop_at_soft_wraps" = true;
        #     "stop_at_indent" = true;
        #   }
        # ];
        "ctrl-shift-alt-l" = [
          "editor::SortLinesCaseSensitive"
          { }
        ];
      };
    }
  ];
}
