use anyhow::Result;
use chrono::{DateTime, Local};
use clap::Parser;
use color_eyre::eyre::WrapErr;
use crossterm::event::{self, Event, KeyCode, KeyEventKind};
use ratatui::{
    layout::{Constraint, Direction, Layout, Rect},
    style::{Color, Modifier, Style},
    text::{Line, Span, Text},
    widgets::{Block, Borders, List, ListItem, ListState, Paragraph, Wrap},
    DefaultTerminal, Frame,
};
use serde::{Deserialize, Serialize};
use std::process::Command;
use tokio::process::Command as AsyncCommand;

#[derive(Parser)]
#[command(name = "nixos-rollback-tui")]
#[command(about = "A TUI for rolling back to different NixOS generations")]
struct Cli {
    /// Show system generations instead of user generations
    #[arg(short, long)]
    system: bool,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
struct Generation {
    id: u32,
    date: DateTime<Local>,
    current: bool,
    description: String,
    kernel_version: Option<String>,
    nixos_version: Option<String>,
}

#[derive(Debug)]
struct App {
    generations: Vec<Generation>,
    list_state: ListState,
    selected_generation: Option<Generation>,
    show_help: bool,
    show_confirmation: bool,
    is_system: bool,
    status_message: Option<String>,
}

impl App {
    fn new(is_system: bool) -> Self {
        let mut list_state = ListState::default();
        list_state.select(Some(0));
        
        Self {
            generations: Vec::new(),
            list_state,
            selected_generation: None,
            show_help: false,
            show_confirmation: false,
            is_system,
            status_message: None,
        }
    }

    async fn load_generations(&mut self) -> Result<()> {
        self.generations = if self.is_system {
            get_system_generations().await?
        } else {
            get_user_generations().await?
        };
        
        // Select the current generation by default
        if let Some(current_idx) = self.generations.iter().position(|g| g.current) {
            self.list_state.select(Some(current_idx));
        }
        
        self.update_selected_generation();
        Ok(())
    }

    fn update_selected_generation(&mut self) {
        if let Some(selected) = self.list_state.selected() {
            self.selected_generation = self.generations.get(selected).cloned();
        }
    }

    fn next(&mut self) {
        let i = match self.list_state.selected() {
            Some(i) => {
                if i >= self.generations.len() - 1 {
                    0
                } else {
                    i + 1
                }
            }
            None => 0,
        };
        self.list_state.select(Some(i));
        self.update_selected_generation();
    }

    fn previous(&mut self) {
        let i = match self.list_state.selected() {
            Some(i) => {
                if i == 0 {
                    self.generations.len() - 1
                } else {
                    i - 1
                }
            }
            None => 0,
        };
        self.list_state.select(Some(i));
        self.update_selected_generation();
    }

    async fn rollback_to_selected(&mut self) -> Result<()> {
        if let Some(gen) = &self.selected_generation {
            if gen.current {
                self.status_message = Some("Already on this generation".to_string());
                return Ok(());
            }

            let result = if self.is_system {
                rollback_system_generation(gen.id).await
            } else {
                rollback_user_generation(gen.id).await
            };

            match result {
                Ok(_) => {
                    self.status_message = Some(format!("Successfully rolled back to generation {}", gen.id));
                    // Reload generations to update current status
                    self.load_generations().await?;
                }
                Err(e) => {
                    self.status_message = Some(format!("Failed to rollback: {}", e));
                }
            }
        }
        Ok(())
    }
}

async fn get_system_generations() -> Result<Vec<Generation>> {
    let output = AsyncCommand::new("nixos-rebuild")
        .args(["list-generations"])
        .output()
        .await
        .wrap_err("Failed to execute nixos-rebuild list-generations")?;

    if !output.status.success() {
        return Err(anyhow::anyhow!("nixos-rebuild list-generations failed"));
    }

    parse_nixos_generations(&String::from_utf8_lossy(&output.stdout))
}

async fn get_user_generations() -> Result<Vec<Generation>> {
    let output = AsyncCommand::new("nix-env")
        .args(["--list-generations"])
        .output()
        .await
        .wrap_err("Failed to execute nix-env --list-generations")?;

    if !output.status.success() {
        return Err(anyhow::anyhow!("nix-env --list-generations failed"));
    }

    parse_user_generations(&String::from_utf8_lossy(&output.stdout))
}

fn parse_nixos_generations(output: &str) -> Result<Vec<Generation>> {
    let mut generations = Vec::new();
    
    for line in output.lines() {
        if line.trim().is_empty() {
            continue;
        }
        
        // Parse lines like: "  123   2024-01-15 10:30:45   (current)"
        let parts: Vec<&str> = line.split_whitespace().collect();
        if parts.len() >= 3 {
            if let Ok(id) = parts[0].parse::<u32>() {
                let date_str = format!("{} {}", parts[1], parts[2]);
                if let Ok(date) = DateTime::parse_from_str(&date_str, "%Y-%m-%d %H:%M:%S") {
                    let current = line.contains("(current)");
                    let description = if current {
                        "Current generation".to_string()
                    } else {
                        format!("Generation {}", id)
                    };
                    
                    generations.push(Generation {
                        id,
                        date: date.with_timezone(&Local),
                        current,
                        description,
                        kernel_version: None,
                        nixos_version: None,
                    });
                }
            }
        }
    }
    
    // Sort by generation ID in descending order (newest first)
    generations.sort_by(|a, b| b.id.cmp(&a.id));
    Ok(generations)
}

fn parse_user_generations(output: &str) -> Result<Vec<Generation>> {
    let mut generations = Vec::new();
    
    for line in output.lines() {
        if line.trim().is_empty() {
            continue;
        }
        
        // Parse lines like: "  123   2024-01-15 10:30:45"
        let parts: Vec<&str> = line.split_whitespace().collect();
        if parts.len() >= 3 {
            if let Ok(id) = parts[0].parse::<u32>() {
                let date_str = format!("{} {}", parts[1], parts[2]);
                if let Ok(date) = DateTime::parse_from_str(&date_str, "%Y-%m-%d %H:%M:%S") {
                    let current = line.contains("(current)");
                    let description = if current {
                        "Current generation".to_string()
                    } else {
                        format!("Generation {}", id)
                    };
                    
                    generations.push(Generation {
                        id,
                        date: date.with_timezone(&Local),
                        current,
                        description,
                        kernel_version: None,
                        nixos_version: None,
                    });
                }
            }
        }
    }
    
    // Sort by generation ID in descending order (newest first)
    generations.sort_by(|a, b| b.id.cmp(&a.id));
    Ok(generations)
}

async fn rollback_system_generation(generation_id: u32) -> Result<()> {
    let output = AsyncCommand::new("sudo")
        .args(["nixos-rebuild", "switch", "--rollback-generation", &generation_id.to_string()])
        .output()
        .await
        .wrap_err("Failed to execute nixos-rebuild switch")?;

    if !output.status.success() {
        return Err(anyhow::anyhow!(
            "nixos-rebuild switch failed: {}",
            String::from_utf8_lossy(&output.stderr)
        ));
    }

    Ok(())
}

async fn rollback_user_generation(generation_id: u32) -> Result<()> {
    let output = AsyncCommand::new("nix-env")
        .args(["--switch-generation", &generation_id.to_string()])
        .output()
        .await
        .wrap_err("Failed to execute nix-env --switch-generation")?;

    if !output.status.success() {
        return Err(anyhow::anyhow!(
            "nix-env --switch-generation failed: {}",
            String::from_utf8_lossy(&output.stderr)
        ));
    }

    Ok(())
}

fn render_app(frame: &mut Frame, app: &App) {
    let chunks = Layout::default()
        .direction(Direction::Vertical)
        .constraints([
            Constraint::Length(3),  // Title
            Constraint::Min(10),    // Main content
            Constraint::Length(3),  // Status bar
        ])
        .split(frame.area());

    // Title
    let title = if app.is_system {
        "NixOS System Generations"
    } else {
        "Nix User Generations"
    };
    
    let title_block = Block::default()
        .borders(Borders::ALL)
        .title(title)
        .title_style(Style::default().fg(Color::Cyan).add_modifier(Modifier::BOLD));
    frame.render_widget(title_block, chunks[0]);

    // Main content area
    let main_chunks = Layout::default()
        .direction(Direction::Horizontal)
        .constraints([Constraint::Percentage(50), Constraint::Percentage(50)])
        .split(chunks[1]);

    // Generation list
    render_generation_list(frame, app, main_chunks[0]);
    
    // Details panel
    render_details_panel(frame, app, main_chunks[1]);

    // Status bar
    render_status_bar(frame, app, chunks[2]);

    // Overlays
    if app.show_help {
        render_help_popup(frame);
    }
    
    if app.show_confirmation {
        render_confirmation_popup(frame, app);
    }
}

fn render_generation_list(frame: &mut Frame, app: &App, area: Rect) {
    let items: Vec<ListItem> = app
        .generations
        .iter()
        .map(|gen| {
            let style = if gen.current {
                Style::default().fg(Color::Green).add_modifier(Modifier::BOLD)
            } else {
                Style::default()
            };
            
            let content = vec![Line::from(vec![
                Span::styled(format!("{:3}", gen.id), style),
                Span::raw("  "),
                Span::styled(
                    gen.date.format("%Y-%m-%d %H:%M").to_string(),
                    style
                ),
                if gen.current {
                    Span::styled(" (current)", Style::default().fg(Color::Green))
                } else {
                    Span::raw("")
                },
            ])];
            
            ListItem::new(content).style(style)
        })
        .collect();

    let list = List::new(items)
        .block(
            Block::default()
                .borders(Borders::ALL)
                .title("Generations")
                .title_style(Style::default().fg(Color::Yellow))
        )
        .highlight_style(
            Style::default()
                .bg(Color::DarkGray)
                .add_modifier(Modifier::BOLD)
        )
        .highlight_symbol(">> ");

    frame.render_stateful_widget(list, area, &mut app.list_state.clone());
}

fn render_details_panel(frame: &mut Frame, app: &App, area: Rect) {
    let content = if let Some(gen) = &app.selected_generation {
        let mut lines = vec![
            Line::from(vec![
                Span::styled("Generation ID: ", Style::default().add_modifier(Modifier::BOLD)),
                Span::raw(gen.id.to_string()),
            ]),
            Line::from(vec![
                Span::styled("Date: ", Style::default().add_modifier(Modifier::BOLD)),
                Span::raw(gen.date.format("%Y-%m-%d %H:%M:%S").to_string()),
            ]),
            Line::from(vec![
                Span::styled("Status: ", Style::default().add_modifier(Modifier::BOLD)),
                if gen.current {
                    Span::styled("Current", Style::default().fg(Color::Green))
                } else {
                    Span::styled("Available", Style::default().fg(Color::Yellow))
                },
            ]),
            Line::from(""),
            Line::from(vec![
                Span::styled("Description: ", Style::default().add_modifier(Modifier::BOLD)),
            ]),
            Line::from(gen.description.clone()),
        ];

        if let Some(kernel) = &gen.kernel_version {
            lines.push(Line::from(""));
            lines.push(Line::from(vec![
                Span::styled("Kernel: ", Style::default().add_modifier(Modifier::BOLD)),
                Span::raw(kernel.clone()),
            ]));
        }

        if let Some(nixos) = &gen.nixos_version {
            lines.push(Line::from(vec![
                Span::styled("NixOS: ", Style::default().add_modifier(Modifier::BOLD)),
                Span::raw(nixos.clone()),
            ]));
        }

        Text::from(lines)
    } else {
        Text::from("No generation selected")
    };

    let paragraph = Paragraph::new(content)
        .block(
            Block::default()
                .borders(Borders::ALL)
                .title("Details")
                .title_style(Style::default().fg(Color::Yellow))
        )
        .wrap(Wrap { trim: true });

    frame.render_widget(paragraph, area);
}

fn render_status_bar(frame: &mut Frame, app: &App, area: Rect) {
    let status_text = if let Some(msg) = &app.status_message {
        msg.clone()
    } else {
        "↑/↓: Navigate | Enter: Rollback | h: Help | q: Quit".to_string()
    };

    let paragraph = Paragraph::new(status_text)
        .block(
            Block::default()
                .borders(Borders::ALL)
                .title("Status")
                .title_style(Style::default().fg(Color::Cyan))
        );

    frame.render_widget(paragraph, area);
}

fn render_help_popup(frame: &mut Frame) {
    let area = centered_rect(60, 70, frame.area());
    
    let help_text = Text::from(vec![
        Line::from(""),
        Line::from(vec![
            Span::styled("Navigation:", Style::default().add_modifier(Modifier::BOLD)),
        ]),
        Line::from("  ↑/k    - Move up"),
        Line::from("  ↓/j    - Move down"),
        Line::from(""),
        Line::from(vec![
            Span::styled("Actions:", Style::default().add_modifier(Modifier::BOLD)),
        ]),
        Line::from("  Enter  - Rollback to selected generation"),
        Line::from("  r      - Refresh generation list"),
        Line::from(""),
        Line::from(vec![
            Span::styled("Other:", Style::default().add_modifier(Modifier::BOLD)),
        ]),
        Line::from("  h/?    - Show/hide this help"),
        Line::from("  q/Esc  - Quit"),
        Line::from(""),
        Line::from(vec![
            Span::styled("Warning:", Style::default().fg(Color::Red).add_modifier(Modifier::BOLD)),
        ]),
        Line::from("Rolling back will change your system state."),
        Line::from("Make sure you understand the implications."),
    ]);

    let paragraph = Paragraph::new(help_text)
        .block(
            Block::default()
                .borders(Borders::ALL)
                .title("Help")
                .title_style(Style::default().fg(Color::Cyan).add_modifier(Modifier::BOLD))
        )
        .wrap(Wrap { trim: true });

    frame.render_widget(paragraph, area);
}

fn render_confirmation_popup(frame: &mut Frame, app: &App) {
    let area = centered_rect(50, 30, frame.area());
    
    let gen_info = if let Some(gen) = &app.selected_generation {
        format!("generation {} ({})", gen.id, gen.date.format("%Y-%m-%d %H:%M"))
    } else {
        "selected generation".to_string()
    };

    let confirmation_text = Text::from(vec![
        Line::from(""),
        Line::from(vec![
            Span::styled("Are you sure you want to rollback to", Style::default()),
        ]),
        Line::from(vec![
            Span::styled(gen_info, Style::default().fg(Color::Yellow).add_modifier(Modifier::BOLD)),
            Span::raw("?"),
        ]),
        Line::from(""),
        Line::from("This will change your system state."),
        Line::from(""),
        Line::from(vec![
            Span::styled("y", Style::default().fg(Color::Green).add_modifier(Modifier::BOLD)),
            Span::raw(" - Yes, rollback"),
        ]),
        Line::from(vec![
            Span::styled("n/Esc", Style::default().fg(Color::Red).add_modifier(Modifier::BOLD)),
            Span::raw(" - No, cancel"),
        ]),
    ]);

    let paragraph = Paragraph::new(confirmation_text)
        .block(
            Block::default()
                .borders(Borders::ALL)
                .title("Confirm Rollback")
                .title_style(Style::default().fg(Color::Red).add_modifier(Modifier::BOLD))
        )
        .wrap(Wrap { trim: true });

    frame.render_widget(paragraph, area);
}

fn centered_rect(percent_x: u16, percent_y: u16, r: Rect) -> Rect {
    let popup_layout = Layout::default()
        .direction(Direction::Vertical)
        .constraints([
            Constraint::Percentage((100 - percent_y) / 2),
            Constraint::Percentage(percent_y),
            Constraint::Percentage((100 - percent_y) / 2),
        ])
        .split(r);

    Layout::default()
        .direction(Direction::Horizontal)
        .constraints([
            Constraint::Percentage((100 - percent_x) / 2),
            Constraint::Percentage(percent_x),
            Constraint::Percentage((100 - percent_x) / 2),
        ])
        .split(popup_layout[1])[1]
}

async fn run_app(mut terminal: DefaultTerminal, mut app: App) -> Result<()> {
    // Load generations on startup
    app.load_generations().await?;

    loop {
        terminal.draw(|frame| render_app(frame, &app))?;

        if let Event::Key(key) = event::read()? {
            if key.kind == KeyEventKind::Press {
                // Clear status message on any key press
                if app.status_message.is_some() {
                    app.status_message = None;
                }

                if app.show_confirmation {
                    match key.code {
                        KeyCode::Char('y') | KeyCode::Char('Y') => {
                            app.show_confirmation = false;
                            app.rollback_to_selected().await?;
                        }
                        KeyCode::Char('n') | KeyCode::Char('N') | KeyCode::Esc => {
                            app.show_confirmation = false;
                        }
                        _ => {}
                    }
                } else if app.show_help {
                    match key.code {
                        KeyCode::Char('h') | KeyCode::Char('?') | KeyCode::Esc => {
                            app.show_help = false;
                        }
                        _ => {}
                    }
                } else {
                    match key.code {
                        KeyCode::Char('q') | KeyCode::Esc => break,
                        KeyCode::Char('h') | KeyCode::Char('?') => {
                            app.show_help = true;
                        }
                        KeyCode::Char('r') => {
                            app.load_generations().await?;
                            app.status_message = Some("Generations refreshed".to_string());
                        }
                        KeyCode::Down | KeyCode::Char('j') => {
                            app.next();
                        }
                        KeyCode::Up | KeyCode::Char('k') => {
                            app.previous();
                        }
                        KeyCode::Enter => {
                            if app.selected_generation.is_some() {
                                app.show_confirmation = true;
                            }
                        }
                        _ => {}
                    }
                }
            }
        }
    }

    Ok(())
}

#[tokio::main]
async fn main() -> Result<()> {
    color_eyre::install()?;
    let cli = Cli::parse();
    
    let terminal = ratatui::init();
    let app = App::new(cli.system);
    let result = run_app(terminal, app).await;
    ratatui::restore();
    
    result
}