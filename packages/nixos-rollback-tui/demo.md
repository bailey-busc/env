# NixOS Rollback TUI Demo

This document shows what the TUI interface looks like and how to use it.

## Interface Layout

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                          NixOS System Generations                          │
└─────────────────────────────────────────────────────────────────────────────┘
┌─────────────────────────────────┬─────────────────────────────────────────┐
│ Generations                     │ Details                                 │
│                                 │                                         │
│ >> 123  2024-01-15 10:30 (curr)│ Generation ID: 123                      │
│    122  2024-01-14 09:15        │ Date: 2024-01-15 10:30:45               │
│    121  2024-01-13 14:22        │ Status: Current                         │
│    120  2024-01-12 16:45        │                                         │
│    119  2024-01-11 11:30        │ Description:                            │
│    118  2024-01-10 13:20        │ Current generation                      │
│    117  2024-01-09 15:10        │                                         │
│    116  2024-01-08 12:00        │                                         │
│    115  2024-01-07 10:45        │                                         │
│                                 │                                         │
└─────────────────────────────────┴─────────────────────────────────────────┘
┌─────────────────────────────────────────────────────────────────────────────┐
│ Status: ↑/↓: Navigate | Enter: Rollback | h: Help | q: Quit                │
└─────────────────────────────────────────────────────────────────────────────┘
```

## Key Features

### 1. Generation List (Left Panel)
- Shows all available generations in descending order (newest first)
- Current generation is highlighted in green with "(current)" indicator
- Selected generation is highlighted with ">>" marker
- Shows generation ID and creation timestamp

### 2. Details Panel (Right Panel)
- Shows detailed information about the selected generation
- Displays generation ID, date, and status
- Shows description and any additional metadata
- Future versions could show package differences

### 3. Status Bar (Bottom)
- Shows available keyboard shortcuts
- Displays operation feedback and error messages
- Updates with real-time status information

## Usage Examples

### Basic Navigation
1. Launch the application:
   ```bash
   nixos-rollback-tui --system
   ```

2. Use arrow keys or vim-style navigation (j/k) to select a generation

3. Press Enter to initiate rollback (shows confirmation dialog)

4. Press 'r' to refresh the generation list

5. Press 'h' or '?' to show help

6. Press 'q' or Esc to quit

### Confirmation Dialog
When you press Enter to rollback, a confirmation dialog appears:

```
┌─────────────────────────────────────────┐
│              Confirm Rollback           │
│                                         │
│ Are you sure you want to rollback to    │
│ generation 122 (2024-01-14 09:15)?      │
│                                         │
│ This will change your system state.     │
│                                         │
│ y - Yes, rollback                       │
│ n/Esc - No, cancel                      │
└─────────────────────────────────────────┘
```

### Help Dialog
Press 'h' or '?' to show the help dialog:

```
┌─────────────────────────────────────────┐
│                  Help                   │
│                                         │
│ Navigation:                             │
│   ↑/k    - Move up                      │
│   ↓/j    - Move down                    │
│                                         │
│ Actions:                                │
│   Enter  - Rollback to selected gen    │
│   r      - Refresh generation list     │
│                                         │
│ Other:                                  │
│   h/?    - Show/hide this help          │
│   q/Esc  - Quit                         │
│                                         │
│ Warning:                                │
│ Rolling back will change your system    │
│ state. Make sure you understand the     │
│ implications.                           │
└─────────────────────────────────────────┘
```

## Command Line Options

```bash
# View system generations (requires sudo for rollback)
nixos-rollback-tui --system

# View user generations (default)
nixos-rollback-tui

# Show help
nixos-rollback-tui --help
```

## Safety Features

1. **Confirmation Required**: Always asks for confirmation before rolling back
2. **Clear Current Indicator**: Shows which generation is currently active
3. **Status Feedback**: Provides clear feedback on operations
4. **Error Handling**: Shows helpful error messages if operations fail
5. **Read-only by Default**: Only performs changes when explicitly confirmed

## Technical Implementation

- Built with Rust and Ratatui for the TUI interface
- Uses `nixos-rebuild list-generations` for system generations
- Uses `nix-env --list-generations` for user generations
- Executes rollback commands asynchronously with proper error handling
- Supports both system and user generation management

## Future Enhancements

- Show package differences between generations
- Add search/filter functionality
- Support for generation descriptions/tags
- Integration with generation metadata
- Backup verification before rollback
- Support for remote system management