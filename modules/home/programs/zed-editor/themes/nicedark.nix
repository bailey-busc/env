{ config, ... }:
{
  inherit (config.colorScheme) name;
  appearance = "dark";
  style =
    let
      # Main colors
      bg = "#3b414dff";
      bg2 = "#2f343eff";
      bg3 = "#2e343eff";
      bg4 = "#282c33ff";
      fg = "#dce0e5ff";
      fg2 = "#acb2beff";
      fg3 = "#a9afbcff";

      # Accent colors
      blue = "#74ade8ff";
      blue2 = "#73ade9ff";
      red = "#d07277ff";
      green = "#a1c181ff";
      yellow = "#dec184ff";
      orange = "#bf956aff";
      purple = "#b477cfff";
      cyan = "#6eb4bfff";

      # Border colors
      border1 = "#464b57ff";
      border2 = "#363c46ff";
      border3 = "#414754ff";
      border4 = "#293b5bff";

      # Other colors
      muted = "#878a98ff";
      transparent = "#00000000";

      # Alpha variants
      blueAlpha = "#74ade81a";
      blueAlpha2 = "#74ade83d";
      blueAlpha3 = "#74ade866";
      redAlpha = "#d072771a";
      redAlpha2 = "#d072773d";
      greenAlpha = "#a1c1811a";
      greenAlpha2 = "#a1c1813d";
      yellowAlpha = "#dec1841a";
      yellowAlpha2 = "#dec1843d";
      orangeAlpha = "#bf956a3d";
      purpleAlpha = "#b477cf3d";
      cyanAlpha = "#6eb4bf3d";
      mutedAlpha = "#696b771a";
    in
    {
      border = border1;
      "border.variant" = border2;
      "border.focused" = "#47679eff";
      "border.selected" = border4;
      "border.transparent" = transparent;
      "border.disabled" = border3;
      "elevated_surface.background" = bg2;
      "surface.background" = bg2;
      background = bg;
      "element.background" = bg3;
      "element.hover" = border2;
      "element.active" = "#454a56ff";
      "element.selected" = "#454a56ff";
      "element.disabled" = bg3;
      "drop_target.background" = "#83899480";
      "ghost_element.background" = transparent;
      "ghost_element.hover" = border2;
      "ghost_element.active" = "#454a56ff";
      "ghost_element.selected" = "#454a56ff";
      "ghost_element.disabled" = bg3;
      text = fg;
      "text.muted" = fg3;
      "text.placeholder" = muted;
      "text.disabled" = muted;
      "text.accent" = blue;
      icon = fg;
      "icon.muted" = fg3;
      "icon.disabled" = muted;
      "icon.placeholder" = fg3;
      "icon.accent" = blue;
      "status_bar.background" = bg;
      "title_bar.background" = bg;
      "title_bar.inactive_background" = bg3;
      "toolbar.background" = bg4;
      "tab_bar.background" = bg2;
      "tab.inactive_background" = bg2;
      "tab.active_background" = bg4;
      "search.match_background" = blueAlpha3;
      "panel.background" = bg2;
      "panel.focused_border" = null;
      "pane.focused_border" = null;
      "scrollbar.thumb.background" = "#c8ccd44c";
      "scrollbar.thumb.hover_background" = border2;
      "scrollbar.thumb.border" = border2;
      "scrollbar.track.background" = transparent;
      "scrollbar.track.border" = "#2e333cff";
      "editor.foreground" = fg2;
      "editor.background" = bg4;
      "editor.gutter.background" = bg4;
      "editor.subheader.background" = bg2;
      "editor.active_line.background" = "#2f343ebf";
      "editor.highlighted_line.background" = bg2;
      "editor.line_number" = "#4e5a5f";
      "editor.active_line_number" = "#d0d4da";
      "editor.hover_line_number" = "#acb0b4";
      "editor.invisible" = muted;
      "editor.wrap_guide" = "#c8ccd40d";
      "editor.active_wrap_guide" = "#c8ccd41a";
      "editor.document_highlight.read_background" = blueAlpha;
      "editor.document_highlight.write_background" = "#555a6366";
      "terminal.background" = bg4;
      "terminal.foreground" = fg;
      "terminal.bright_foreground" = fg;
      "terminal.dim_foreground" = bg4;
      "terminal.ansi.black" = bg4;
      "terminal.ansi.bright_black" = "#525561ff";
      "terminal.ansi.dim_black" = fg;
      "terminal.ansi.red" = red;
      "terminal.ansi.bright_red" = "#673a3cff";
      "terminal.ansi.dim_red" = "#eab7b9ff";
      "terminal.ansi.green" = green;
      "terminal.ansi.bright_green" = "#4d6140ff";
      "terminal.ansi.dim_green" = "#d1e0bfff";
      "terminal.ansi.yellow" = yellow;
      "terminal.ansi.bright_yellow" = "#e5c07bff";
      "terminal.ansi.dim_yellow" = "#f1dfc1ff";
      "terminal.ansi.blue" = blue;
      "terminal.ansi.bright_blue" = "#385378ff";
      "terminal.ansi.dim_blue" = "#bed5f4ff";
      "terminal.ansi.magenta" = "#be5046ff";
      "terminal.ansi.bright_magenta" = "#5e2b26ff";
      "terminal.ansi.dim_magenta" = "#e6a79eff";
      "terminal.ansi.cyan" = cyan;
      "terminal.ansi.bright_cyan" = "#3a565bff";
      "terminal.ansi.dim_cyan" = "#b9d9dfff";
      "terminal.ansi.white" = fg;
      "terminal.ansi.bright_white" = fg;
      "terminal.ansi.dim_white" = "#575d65ff";
      "link_text.hover" = blue;
      "version_control.added" = "#27a657ff";
      "version_control.modified" = "#d3b020ff";
      "version_control.deleted" = "#e06c76ff";
      "version_control.conflict_marker.ours" = greenAlpha;
      "version_control.conflict_marker.theirs" = blueAlpha;
      conflict = yellow;
      "conflict.background" = yellowAlpha;
      "conflict.border" = "#5d4c2fff";
      created = green;
      "created.background" = greenAlpha;
      "created.border" = "#38482fff";
      deleted = red;
      "deleted.background" = redAlpha;
      "deleted.border" = "#4c2b2cff";
      error = red;
      "error.background" = redAlpha;
      "error.border" = "#4c2b2cff";
      hidden = muted;
      "hidden.background" = mutedAlpha;
      "hidden.border" = border3;
      hint = "#788ca6ff";
      "hint.background" = "#5a6f891a";
      "hint.border" = border4;
      ignored = muted;
      "ignored.background" = mutedAlpha;
      "ignored.border" = border1;
      info = blue;
      "info.background" = blueAlpha;
      "info.border" = border4;
      modified = yellow;
      "modified.background" = yellowAlpha;
      "modified.border" = "#5d4c2fff";
      predictive = "#5a6a87ff";
      "predictive.background" = "#5a6a871a";
      "predictive.border" = "#38482fff";
      renamed = blue;
      "renamed.background" = blueAlpha;
      "renamed.border" = border4;
      success = green;
      "success.background" = greenAlpha;
      "success.border" = "#38482fff";
      unreachable = fg3;
      "unreachable.background" = "#8389941a";
      "unreachable.border" = border1;
      warning = yellow;
      "warning.background" = yellowAlpha;
      "warning.border" = "#5d4c2fff";
      players = [
        {
          cursor = blue;
          background = blue;
          selection = blueAlpha2;
        }
        {
          cursor = "#be5046ff";
          background = "#be5046ff";
          selection = "#be50463d";
        }
        {
          cursor = orange;
          background = orange;
          selection = orangeAlpha;
        }
        {
          cursor = purple;
          background = purple;
          selection = purpleAlpha;
        }
        {
          cursor = cyan;
          background = cyan;
          selection = cyanAlpha;
        }
        {
          cursor = red;
          background = red;
          selection = redAlpha2;
        }
        {
          cursor = yellow;
          background = yellow;
          selection = yellowAlpha2;
        }
        {
          cursor = green;
          background = green;
          selection = greenAlpha2;
        }
      ];
      syntax = {
        attribute = {
          color = blue;
          font_style = null;
          font_weight = null;
        };
        boolean = {
          color = orange;
          font_style = null;
          font_weight = null;
        };
        comment = {
          color = "#5d636fff";
          font_style = null;
          font_weight = null;
        };
        "comment.doc" = {
          color = "#878e98ff";
          font_style = null;
          font_weight = null;
        };
        constant = {
          color = "#dfc184ff";
          font_style = null;
          font_weight = null;
        };
        constructor = {
          color = blue2;
          font_style = null;
          font_weight = null;
        };
        embedded = {
          color = fg;
          font_style = null;
          font_weight = null;
        };
        emphasis = {
          color = blue;
          font_style = null;
          font_weight = null;
        };
        "emphasis.strong" = {
          color = orange;
          font_style = null;
          font_weight = 700;
        };
        enum = {
          color = red;
          font_style = null;
          font_weight = null;
        };
        function = {
          color = blue2;
          font_style = null;
          font_weight = null;
        };
        hint = {
          color = "#788ca6ff";
          font_style = null;
          font_weight = 700;
        };
        keyword = {
          color = purple;
          font_style = null;
          font_weight = null;
        };
        label = {
          color = blue;
          font_style = null;
          font_weight = null;
        };
        link_text = {
          color = blue2;
          font_style = "normal";
          font_weight = null;
        };
        link_uri = {
          color = cyan;
          font_style = null;
          font_weight = null;
        };
        namespace = {
          color = fg;
          font_style = null;
          font_weight = null;
        };
        number = {
          color = orange;
          font_style = null;
          font_weight = null;
        };
        operator = {
          color = cyan;
          font_style = null;
          font_weight = null;
        };
        predictive = {
          color = "#5a6a87ff";
          font_style = "italic";
          font_weight = null;
        };
        preproc = {
          color = fg;
          font_style = null;
          font_weight = null;
        };
        primary = {
          color = fg2;
          font_style = null;
          font_weight = null;
        };
        property = {
          color = red;
          font_style = null;
          font_weight = null;
        };
        punctuation = {
          color = fg2;
          font_style = null;
          font_weight = null;
        };
        "punctuation.bracket" = {
          color = "#b2b9c6ff";
          font_style = null;
          font_weight = null;
        };
        "punctuation.delimiter" = {
          color = "#b2b9c6ff";
          font_style = null;
          font_weight = null;
        };
        "punctuation.list_marker" = {
          color = red;
          font_style = null;
          font_weight = null;
        };
        "punctuation.special" = {
          color = "#b1574bff";
          font_style = null;
          font_weight = null;
        };
        selector = {
          color = "#dfc184ff";
          font_style = null;
          font_weight = null;
        };
        "selector.pseudo" = {
          color = blue;
          font_style = null;
          font_weight = null;
        };
        string = {
          color = green;
          font_style = null;
          font_weight = null;
        };
        "string.escape" = {
          color = "#878e98ff";
          font_style = null;
          font_weight = null;
        };
        "string.regex" = {
          color = orange;
          font_style = null;
          font_weight = null;
        };
        "string.special" = {
          color = orange;
          font_style = null;
          font_weight = null;
        };
        "string.special.symbol" = {
          color = orange;
          font_style = null;
          font_weight = null;
        };
        tag = {
          color = blue;
          font_style = null;
          font_weight = null;
        };
        "text.literal" = {
          color = green;
          font_style = null;
          font_weight = null;
        };
        title = {
          color = red;
          font_style = null;
          font_weight = 400;
        };
        type = {
          color = cyan;
          font_style = null;
          font_weight = null;
        };
        variable = {
          color = fg2;
          font_style = null;
          font_weight = null;
        };
        "variable.special" = {
          color = orange;
          font_style = null;
          font_weight = null;
        };
        variant = {
          color = blue2;
          font_style = null;
          font_weight = null;
        };
      };
    };
}
