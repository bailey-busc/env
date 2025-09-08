# NixOS Rollback TUI

A Terminal User Interface (TUI) for easily rolling back to different NixOS generations.

## Features

- **Interactive Generation List**: Browse through available NixOS system or user generations
- **Detailed Information**: View generation details including date, status, and description
- **Safe Rollback**: Confirmation prompts before making changes
- **Dual Mode Support**: Switch between system generations and user generations
- **Keyboard Navigation**: Vim-like keybindings for efficient navigation
- **Real-time Status**: Live feedback on operations and errors

## Installation

This package is designed to be built with Nix. Add it to your NixOS configuration or install it directly:

```bash
# Build and run directly
nix build .#nixos-rollback-tui
./result/bin/nixos-rollback-tui

# Or install to your profile
nix profile install .#nixos-rollback-tui
```

## Usage

### Basic Usage

```bash
# View and rollback system generations (requires sudo for rollback)
nixos-rollback-tui --system

# View and rollback user generations
nixos-rollback-tui
```

### Keyboard Controls

| Key | Action |
|-----|--------|
| `↑`/`k` | Move up in the generation list |
| `↓`/`j` | Move down in the generation list |
| `Enter` | Rollback to selected generation (with confirmation) |
| `r` | Refresh the generation list |
| `h`/`?` | Show/hide help |
| `q`/`Esc` | Quit the application |

### Interface Layout

The TUI is divided into several sections:

1. **Title Bar**: Shows whether you're viewing system or user generations
2. **Generation List** (left panel): Lists all available generations with:
   - Generation ID
   - Creation date and time
   - Current generation indicator
3. **Details Panel** (right panel): Shows detailed information about the selected generation
4. **Status Bar**: Displays help text and operation feedback

## How It Works

### System Generations

When using `--system` flag, the tool:
- Uses `nixos-rebuild list-generations` to fetch available system generations
- Uses `sudo nixos-rebuild switch --rollback-generation <ID>` to perform rollbacks
- Requires sudo privileges for rollback operations

### User Generations

For user generations, the tool:
- Uses `nix-env --list-generations` to fetch available user generations
- Uses `nix-env --switch-generation <ID>` to perform rollbacks
- Operates on the current user's profile

## Safety Features

- **Confirmation Prompts**: Always asks for confirmation before rolling back
- **Current Generation Highlighting**: Clearly shows which generation is currently active
- **Error Handling**: Provides clear error messages if operations fail
- **Status Feedback**: Shows the result of operations

## Requirements

- NixOS or Nix package manager
- For system rollbacks: sudo privileges
- Terminal with color support (recommended)

## Development

This project is built with:
- **Rust**: Core application logic
- **Ratatui**: Terminal user interface framework
- **Crossterm**: Cross-platform terminal manipulation
- **Tokio**: Async runtime for command execution
- **Clap**: Command-line argument parsing

### Building from Source

```bash
# Using Nix (recommended)
nix build

# Using Cargo (requires Rust toolchain)
cargo build --release
```

## Contributing

Contributions are welcome! Please feel free to submit issues or pull requests.

## License

MIT License - see LICENSE file for details.