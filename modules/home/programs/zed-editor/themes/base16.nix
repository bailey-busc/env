{ scheme, ... }:
let
  inherit (scheme) scheme-name scheme-variant;
  inherit (scheme.withHashtag)
    base00
    base01
    base02
    base03
    base04
    base05
    base06
    base07
    red
    bright-red
    orange
    yellow
    bright-yellow
    green
    bright-green
    cyan
    bright-cyan
    blue
    bright-blue
    base0E
    magenta
    bright-magenta
    ;
in
{
  name = scheme-name;
  appearance = scheme-variant;
  style = {
    border = base03;
    "border.variant" = base03;
    "border.focused" = cyan;
    "border.selected" = base03;
    "border.transparent" = base03;
    "border.disabled" = base03;
    "elevated_surface.background" = base00;
    "surface.background" = base02;
    background = base01;
    "element.background" = base00;
    "element.hover" = base02;
    "element.active" = base03;
    "element.selected" = base06;
    "element.disabled" = null;
    "drop_target.background" = base02;
    "ghost_element.background" = null;
    "ghost_element.hover" = base02;
    "ghost_element.active" = null;
    "ghost_element.selected" = base06;
    "ghost_element.disabled" = null;
    text = base04;
    "text.muted" = base04;
    "text.placeholder" = null;
    "text.disabled" = null;
    "text.accent" = base05;
    icon = null;
    "icon.muted" = null;
    "icon.disabled" = null;
    "icon.placeholder" = null;
    "icon.accent" = null;
    "status_bar.background" = base00;
    "title_bar.background" = base01;
    "toolbar.background" = base01;
    "tab_bar.background" = base00;
    "tab.inactive_background" = base00;
    "tab.active_background" = base01;
    "search.match_background" = null;
    "panel.background" = base00;
    "panel.focused_border" = null;
    "pane.focused_border" = null;
    "scrollbar.thumb.background" = base02;
    "scrollbar.thumb.hover_background" = base03;
    "scrollbar.thumb.border" = base02;
    "scrollbar.track.background" = base01;
    "scrollbar.track.border" = "${base03}4d";
    "editor.foreground" = base04;
    "editor.background" = base01;
    "editor.gutter.background" = base01;
    "editor.subheader.background" = null;
    "editor.active_line.background" = "${base06}10";
    "editor.highlighted_line.background" = null;
    "editor.line_number" = base03;
    "editor.active_line_number" = base04;
    "editor.invisible" = null;
    "editor.wrap_guide" = base03;
    "editor.active_wrap_guide" = base03;
    "editor.document_highlight.read_background" = null;
    "editor.document_highlight.write_background" = null;
    "terminal.background" = base01;
    "terminal.foreground" = base06;
    "terminal.bright_foreground" = base06;
    "terminal.dim_foreground" = null;
    "terminal.ansi.black" = base00;
    "terminal.ansi.bright_black" = base03;
    "terminal.ansi.dim_black" = null;
    "terminal.ansi.red" = red;
    "terminal.ansi.bright_red" = bright-red;
    "terminal.ansi.dim_red" = null;
    "terminal.ansi.green" = green;
    "terminal.ansi.bright_green" = bright-green;
    "terminal.ansi.dim_green" = null;
    "terminal.ansi.yellow" = yellow;
    "terminal.ansi.bright_yellow" = bright-yellow;
    "terminal.ansi.dim_yellow" = null;
    "terminal.ansi.blue" = blue;
    "terminal.ansi.bright_blue" = bright-blue;
    "terminal.ansi.dim_blue" = null;
    "terminal.ansi.magenta" = magenta;
    "terminal.ansi.bright_magenta" = bright-magenta;
    "terminal.ansi.dim_magenta" = null;
    "terminal.ansi.cyan" = cyan;
    "terminal.ansi.bright_cyan" = bright-cyan;
    "terminal.ansi.dim_cyan" = null;
    "terminal.ansi.white" = base06;
    "terminal.ansi.bright_white" = base07;
    "terminal.ansi.dim_white" = null;
    "link_text.hover" = null;
    conflict = blue;
    "conflict.background" = null;
    "conflict.border" = null;
    created = green;
    "created.background" = null;
    "created.border" = null;
    deleted = red;
    "deleted.background" = null;
    "deleted.border" = null;
    error = red;
    "error.background" = base00;
    "error.border" = red;
    hidden = base04;
    "hidden.background" = null;
    "hidden.border" = null;
    hint = "${base03}ff";
    "hint.background" = null;
    "hint.border" = null;
    ignored = base04;
    "ignored.background" = null;
    "ignored.border" = null;
    info = cyan;
    "info.background" = base00;
    "info.border" = cyan;
    modified = yellow;
    "modified.background" = null;
    "modified.border" = null;
    predictive = null;
    "predictive.background" = null;
    "predictive.border" = null;
    renamed = null;
    "renamed.background" = null;
    "renamed.border" = null;
    success = null;
    "success.background" = null;
    "success.border" = null;
    unreachable = null;
    "unreachable.background" = null;
    "unreachable.border" = null;
    warning = blue;
    "warning.background" = base00;
    "warning.border" = blue;
    players = [
      {
        selection = base03;
        cursor = base07;
      }
    ];
    syntax = {
      attribute = {
        color = yellow;
        font_style = null;
        font_weight = null;
      };
      boolean = {
        color = yellow;
        font_style = null;
        font_weight = null;
      };
      comment = {
        color = base03;
        font_style = null;
        font_weight = null;
      };
      "comment.doc" = {
        color = green;
        font_style = null;
        font_weight = null;
      };
      constant = {
        color = yellow;
        font_style = null;
        font_weight = null;
      };
      constructor = {
        color = red;
        font_style = null;
        font_weight = null;
      };
      enum = {
        color = yellow;
        font_style = null;
        font_weight = null;
      };
      embedded = {
        color = red;
        font_style = null;
        font_weight = null;
      };
      emphasis = {
        color = base04;
        font_style = "italic";
        font_weight = null;
      };
      "emphasis.strong" = {
        color = base05;
        font_style = "italic";
        font_weight = null;
      };
      function = {
        color = blue;
        font_style = null;
        font_weight = null;
      };
      "function.call" = {
        color = cyan;
        font_style = null;
        font_weight = null;
      };
      keyword = {
        color = base0E;
        font_style = null;
        font_weight = null;
      };
      label = {
        color = blue;
        font_style = null;
        font_weight = null;
      };
      link_text = {
        color = blue;
        font_style = "italic";
        font_weight = null;
      };
      link_uri = {
        color = red;
        font_style = null;
        font_weight = null;
      };
      number = {
        color = yellow;
        font_style = null;
        font_weight = null;
      };
      operator = {
        color = base04;
        font_style = null;
        font_weight = null;
      };
      predictive = {
        color = base03;
        font_style = "italic";
        font_weight = null;
      };
      property = {
        color = base04;
        font_style = null;
        font_weight = null;
      };
      "punctuation.bracket" = {
        color = red;
        font_style = null;
        font_weight = null;
      };
      "punctuation.delimiter" = {
        color = base04;
        font_style = null;
        font_weight = null;
      };
      "punctuation.special" = {
        color = red;
        font_style = null;
        font_weight = null;
      };
      string = {
        color = green;
        font_style = null;
        font_weight = null;
      };
      "string.escape" = {
        color = red;
        font_style = null;
        font_weight = null;
      };
      "string.regex" = {
        color = green;
        font_style = null;
        font_weight = null;
      };
      "string.special" = {
        color = cyan;
        font_style = null;
        font_weight = null;
      };
      "string.special.symbol" = {
        color = cyan;
        font_style = null;
        font_weight = null;
      };
      tag = {
        color = red;
        font_style = null;
        font_weight = null;
      };
      "text.literal" = {
        color = green;
        font_style = null;
        font_weight = null;
      };
      title = {
        color = cyan;
        font_style = null;
        font_weight = 600;
      };
      type = {
        color = orange;
        font_style = null;
        font_weight = null;
      };
      variable = {
        color = base04;
        font_style = null;
        font_weight = null;
      };
      "variable.member" = {
        color = red;
        font_style = null;
        font_weight = null;
      };
      "variable.special" = {
        color = orange;
        font_style = null;
        font_weight = null;
      };
    };
  };
}
