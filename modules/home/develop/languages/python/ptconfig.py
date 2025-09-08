from __future__ import unicode_literals

import sys
from ptpython.layout import CompletionVisualisation
from pygments.token import Token

"""
Configuration for ptpython REPL.

This module provides configuration for the ptpython REPL environment,
including key bindings, appearance settings, and behavior options.
"""

__all__ = ("configure",)


def configure(repl):
    """
    Configuration method. This is called during the start-up of ptpython.
    :param repl: `PythonRepl` instance.
    """
    # Show function signature (bool).
    repl.show_signature = True

    # Show docstring (bool).
    repl.show_docstring = True

    # Show the "[Meta+Enter] Execute" message when pressing [Enter] only
    # inserts a newline instead of executing the code.
    repl.show_meta_enter_message = True

    # Show completions. (NONE, POP_UP, MULTI_COLUMN or TOOLBAR)
    repl.completion_visualisation = CompletionVisualisation.POP_UP

    # When CompletionVisualisation.POP_UP has been chosen, use this
    # scroll_offset in the completion menu.
    repl.completion_menu_scroll_offset = 0

    # Show line numbers (when the input contains multiple lines.)
    repl.show_line_numbers = False

    # Show status bar.
    repl.show_status_bar = True

    # When the sidebar is visible, also show the help text.
    repl.show_sidebar_help = True

    # Swap light/dark colors on or off
    repl.swap_light_and_dark = False

    # Highlight matching parethesis.
    repl.highlight_matching_parenthesis = True

    # Line wrapping. (Instead of horizontal scrolling.)
    repl.wrap_lines = True

    # Mouse support.
    repl.enable_mouse_support = True

    # Complete while typing. (Don't require tab before the
    # completion menu is shown.)
    repl.complete_while_typing = True

    # Fuzzy and dictionary completion.
    repl.enable_fuzzy_completion = True
    repl.enable_dictionary_completion = True

    # Vi mode.
    repl.vi_mode = True

    # Paste mode. (When True, don't insert whitespace after new line.)
    repl.paste_mode = False

    # Use the classic prompt. (Display '>>>' instead of 'In [1]'.)
    repl.prompt_style = "classic"  # 'classic' or 'ipython'

    # Don't insert a blank line after the output.
    repl.insert_blank_line_after_output = True

    # History Search.
    # When True, going back in history will filter the history on the records
    # starting with the current input. (Like readline.)
    # Note: When enable, please disable the `complete_while_typing` option.
    #       otherwise, when there is a completion available, the arrows will
    #       browse through the available completions instead of the history.
    repl.enable_history_search = False

    # Enable auto suggestions. (Pressing right arrow will complete the input,
    # based on the history.)
    repl.enable_auto_suggest = False

    # Enable open-in-editor. Pressing C-X C-E in emacs mode or 'v' in
    # Vi navigation mode will open the input in the current editor.
    repl.enable_open_in_editor = True

    # Enable system prompt. Pressing meta-! will display the system prompt.
    # Also enables Control-Z suspend.
    repl.enable_system_bindings = True

    # Ask for confirmation on exit.
    repl.confirm_exit = True

    # Enable input validation. (Don't try to execute when the input contains
    # syntax errors.)
    repl.enable_input_validation = True

    # Use this colorscheme for the code.
    repl.use_code_colorscheme("monokai")

    # Set color depth (keep in mind that not all terminals support true color).

    # repl.color_depth = 'DEPTH_1_BIT'  # Monochrome.
    # repl.color_depth = 'DEPTH_4_BIT'  # ANSI colors only.
    # repl.color_depth = "DEPTH_8_BIT"  # The default, 256 colors.
    repl.color_depth = "DEPTH_24_BIT"  # True color.

    # Syntax.
    repl.enable_syntax_highlighting = True

    # Install custom colorscheme based on terminal theme
    activate_dark_theme(repl)

    # Add custom key binding for PDB.
    @repl.add_key_binding('p', 'd', 'b')
    def _(event):
        ' Pressing p-d-b will insert modern breakpoint() '
        event.cli.current_buffer.insert_text('\nbreakpoint()\n')

    # Typing ControlE twice should also execute the current command.
    # (Alternative for Meta-Enter.)
    """
    @repl.add_key_binding(Keys.ControlE, Keys.ControlE)
    def _(event):
        event.current_buffer.validate_and_handle()
    """

    # Typing 'jj' in Vi Insert mode, should send escape. (Go back to navigation
    # mode.)
    """
    @repl.add_key_binding('j', 'j', filter=ViInsertMode())
    def _(event):
        " Map 'jj' to Escape. "
        event.cli.key_processor.feed(KeyPress(Keys.Escape))
    """

    # Custom key binding for some simple autocorrection while typing.
    """
    corrections = {
        'impotr': 'import',
        'pritn': 'print',
    }
    @repl.add_key_binding(' ')
    def _(event):
        ' When a space is pressed. Check & correct word before cursor. '
        b = event.cli.current_buffer
        w = b.document.get_word_before_cursor()
        if w is not None:
            if w in corrections:
                b.delete_before_cursor(count=len(w))
                b.insert_text(corrections[w])
        b.insert_text(' ')
    """


# Custom colorscheme for the UI. See `ptpython/layout.py` and
# `ptpython/style.py` for all possible tokens.
_custom_ui_colorscheme = {
    # Blue prompt.
    Token.Layout.Prompt: "bg:#eeeeff #000000 bold",
    # Make the status toolbar red.
    Token.Toolbar.Status: "bg:#ff0000 #000000",
}

# Define a better color scheme for dark backgrounds
_dark_ui_colorscheme = {
    Token.Layout.Prompt: "bg:#333344 #ffffff bold",
    Token.Toolbar.Status: "bg:#772222 #ffffff",
    Token.Menu.Completions.Completion: "bg:#333333 #ffffff",
    Token.Menu.Completions.Completion.Current: "bg:#444444 #ffffff",
    Token.Toolbar.Search: "bg:#333344 #ffffff",
    Token.Toolbar.System: "bg:#333344 #ffffff",
}

def detect_dark_theme():
    """Attempt to detect if the terminal is using a dark theme."""
    import os
    # Check common environment variables
    color_term = os.environ.get('COLORFGBG', '')
    if color_term and ';' in color_term:
        bg_color = int(color_term.split(';')[1])
        return bg_color < 8  # Lower numbers typically indicate dark backgrounds
    
    # Check for common terminal themes
    term = os.environ.get('TERM', '')
    if 'dark' in term.lower():
        return True
    
    # Default to assuming a dark theme
    return True

# Add this to the configure function to use the dark theme
def activate_dark_theme(repl):
    """Activate the dark theme for the REPL if appropriate."""
    if detect_dark_theme():
        repl.install_ui_colorscheme('dark-theme', _dark_ui_colorscheme)
        repl.use_ui_colorscheme('dark-theme')


# Helper function for common imports
def import_common_modules():
    """Import commonly used modules in the REPL."""
    import os
    import sys
    import json
    import datetime
    import pathlib
    import re
    
    # Return a dict of the imported modules
    return {
        'os': os,
        'sys': sys,
        'json': json,
        'datetime': datetime,
        'pathlib': pathlib,
        're': re,
    }

# Only run embed if this file is executed directly
if __name__ == "__main__":
    try:
        from ptpython.repl import embed
        # Import common modules into the global namespace
        globals().update(import_common_modules())
        sys.exit(embed(globals(), locals(), configure=configure))
    except ImportError:
        print("ptpython is not available: falling back to standard prompt")
