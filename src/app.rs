use std::sync::Mutex;
use std::u16;

// use color_eyre::eyre::bail;
// use color_eyre::owo_colors::OwoColorize;
use color_eyre::Result;
use crossterm::event::{self, Event, KeyCode, KeyEvent, KeyEventKind};
use lazy_static::lazy_static;
use ratatui::prelude::*;
use ratatui::widgets::{List, ListItem, ListState};
use ratatui::{
    style::Stylize,
    text::Line,
    widgets::{Block, Paragraph},
    DefaultTerminal, Frame,
};

use crate::game::with_game;
use crate::{game::GameAction, lua::GameLua};

#[derive(Debug, Default)]
enum Focus {
    #[default]
    Actions,
    #[allow(dead_code)]
    Logs,
}

#[derive(Debug, Default)]
pub struct App {
    /// Is the application running?
    running: bool,
    request_lua_tick: bool,

    // GUI Variables
    focus: Focus,
    scroll_logs: u16,
    scroll_wnd_height: u16,
    action_list_state: ListState,
}

lazy_static! {
    static ref TERMINAL: Mutex<DefaultTerminal> = Mutex::new(ratatui::init());
    static ref APP: Mutex<App> = Mutex::new(App::default());
}

pub fn with_app<F, R>(callcack: F) -> R
where
    F: FnOnce(&mut App) -> R,
{
    let mut app = APP.lock().unwrap();
    callcack(&mut app)
}

impl App {
    /// Run the application's main loop.
    pub fn run() -> Result<()> {
        let mut lua = GameLua::default();
        lua.init().unwrap();
        lua.lua_setup();

        with_app(|app| {
            app.running = true;
            app.scroll_logs = u16::MAX;
        });
        fn is_running() -> bool {
            with_app(|app| app.running)
        }
        while is_running() {
            with_app(|app| -> Result<()> {
                if app.action_list_state.selected().is_none() {
                    app.action_list_state.select_next();
                }
                let mut terminal = TERMINAL.lock().unwrap();
                terminal.draw(|frame| app.draw(frame))?;
                app.handle_crossterm_events()?;
                if app.request_lua_tick {
                    app.scroll_logs = u16::MAX;
                }
                Ok(())
            })?;

            // }
            let request_lua_tick = with_app(|app| {
                let temp = app.request_lua_tick;
                app.request_lua_tick = false;
                temp
            });
            if request_lua_tick {
                if let Some(index) = with_app(|app| app.action_list_state.selected()) {
                    lua.lua_tick(index);
                }
            }
        }
        Ok(())
    }

    pub fn redraw() {
        let mut terminal = TERMINAL.lock().unwrap();
        with_app(|app| terminal.draw(|frame| app.draw(frame)).unwrap());
    }

    /// Renders the user interface.
    ///
    /// This is where you add new widgets. See the following resources for more information:
    /// - <https://docs.rs/ratatui/latest/ratatui/widgets/index.html>
    /// - <https://github.com/ratatui/ratatui/tree/master/examples>
    fn draw(&mut self, frame: &mut Frame) {
        let layout = Layout::default()
            .direction(Direction::Vertical)
            .constraints(vec![Constraint::Min(0), Constraint::Length(12)])
            .split(frame.area());
        let area_log_window = layout[0];
        let layout2 = Layout::default()
            .direction(Direction::Vertical)
            .constraints(vec![Constraint::Min(5), Constraint::Length(3)])
            .split(layout[1]);
        let area_status = layout2[1];
        let layout3 = Layout::default()
            .direction(Direction::Horizontal)
            .constraints(vec![Constraint::Length(30), Constraint::Min(30)])
            .split(layout2[0]);
        let area_actions = layout3[0];
        let area_action_des = layout3[1];

        self.scroll_wnd_height = area_log_window.height as u16;
        self.scroll_log_to_bottom();

        with_game(|game| {
            {
                let mut text = "";
                if let Some(index) = self.action_list_state.selected() {
                    if index < game.actions.len() {
                        let action = &game.actions[index];
                        text = &action.description;
                    }
                }
                frame.render_widget(
                    Paragraph::new(text).block(Block::bordered()).centered(),
                    area_action_des,
                )
            }
            {
                let color = if let Focus::Logs = self.focus {
                    Color::Blue
                } else {
                    Color::Reset
                };
                let title = Line::from(" Logs ").bold().style(color).left_aligned();
                let lines: Vec<Line> = game.logs.iter().map(Line::raw).collect();
                let paragraph = Paragraph::new(lines)
                    .block(Block::bordered().title(title))
                    .left_aligned()
                    .scroll((self.scroll_logs, 0));
                frame.render_widget(paragraph, area_log_window);
            }
            {
                const SELECTED_STYLE: Style = Style::new()
                    .bg(Color::DarkGray)
                    .add_modifier(Modifier::BOLD);
                let color = if let Focus::Actions = self.focus {
                    Color::Blue
                } else {
                    Color::Reset
                };
                let title = Line::from(" Actions ").bold().style(color).left_aligned();
                fn gen_list_item(item: &GameAction) -> ListItem {
                    let text = format!(" * {}", item.name);
                    let item: ListItem = Line::from(text).into();
                    item
                }
                let list_items: Vec<_> = game.actions.iter().map(gen_list_item).collect();
                let list = List::new(list_items)
                    .highlight_style(SELECTED_STYLE)
                    .highlight_symbol(">")
                    .highlight_spacing(ratatui::widgets::HighlightSpacing::Always)
                    .block(Block::bordered().title(title));
                frame.render_stateful_widget(list, area_actions, &mut self.action_list_state);
            }
            {
                let title = Line::from(" Info ").bold().left_aligned();
                frame.render_widget(
                    Paragraph::new(game.info.as_str())
                        .block(Block::bordered().title(title))
                        .centered(),
                    area_status,
                );
            }
        });
    }

    /// Reads the crossterm events and updates the state of [`App`].
    ///
    /// If your application needs to perform work in between handling events, you can use the
    /// [`event::poll`] function to check if there are any events available with a timeout.
    fn handle_crossterm_events(&mut self) -> Result<()> {
        match event::read()? {
            // it's important to check KeyEventKind::Press to avoid handling key release events
            Event::Key(key) if key.kind == KeyEventKind::Press => self.on_key_event(key),
            Event::Mouse(_) => {}
            Event::Resize(_, _) => {}
            _ => {}
        }
        Ok(())
    }

    /// Handles the key events and updates the state of [`App`].
    fn on_key_event(&mut self, key: KeyEvent) {
        match (key.modifiers, key.code) {
            (_, KeyCode::Char('q')) => self.quit(),
            // Add other key handlers here.
            (_, KeyCode::Esc) => {}
            _ => {}
        }
        match self.focus {
            Focus::Actions => match key.code {
                KeyCode::Up => {
                    with_game(|game| {
                        if self.action_list_state.selected().unwrap_or(0) == 0 {
                            self.action_list_state.select(Some(game.actions.len() - 1));
                        } else {
                            self.action_list_state.select_previous();
                        }
                    });
                }
                KeyCode::Down => {
                    with_game(|game| {
                        if self
                            .action_list_state
                            .selected()
                            .unwrap_or(game.actions.len() - 1)
                            == game.actions.len() - 1
                        {
                            self.action_list_state.select_first();
                        } else {
                            self.action_list_state.select_next();
                        }
                    });
                }
                KeyCode::Enter => {
                    self.request_lua_tick = true;
                }
                _ => {}
            },
            Focus::Logs => {}
        }
    }

    fn scroll_log_to_bottom(&mut self) {
        with_game(|game| {
            let max_height = game.logs.len() as u16 + 2;
            let max_height = if max_height > self.scroll_wnd_height {
                max_height - self.scroll_wnd_height
            } else {
                0
            };
            if self.scroll_logs > max_height {
                self.scroll_logs = max_height;
            }
        });
    }

    /// Set running to false to quit the application.
    fn quit(&mut self) {
        self.running = false;
    }
}
