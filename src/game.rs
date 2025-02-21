use std::sync::Mutex;

use lazy_static::lazy_static;

use mlua::{FromLua, Lua, Value};
use serde::{Deserialize, Serialize};

use crate::lua::LuaBinder;

#[derive(Debug, Default, Serialize, Deserialize)]
pub struct GameAction {
    pub name: String,
    pub description: String,
}

#[derive(Debug, Default)]
pub struct GameState {
    pub logs: Vec<String>,
    pub actions: Vec<GameAction>,
    pub info: String,
}

impl FromLua for GameAction {
    fn from_lua(value: Value, _lua: &Lua) -> mlua::Result<Self> {
        let table = value.as_table().unwrap();
        Ok(GameAction {
            name: table.get("name")?,
            description: table.get("description")?,
        })
    }
}

lazy_static! {
    static ref GAME_STATE: Mutex<GameState> = Mutex::new(GameState::default());
}

pub fn with_game(callcack: impl FnOnce(&mut GameState)) {
    let mut game = GAME_STATE.lock().unwrap();
    callcack(&mut game);
}

pub fn register_lua_functions(b: &LuaBinder) {
    b.reg("log", lua_log);
    b.reg("set_info_line", lua_set_info_line);
    b.reg("set_actions", lua_set_actions);
    b.reg("sleep", lua_sleep);
}

fn lua_log(msg: String) {
    with_game(|game| {
        for line in msg.split('\n') {
            game.logs.push(line.to_string());
        }
    });
}

fn lua_set_info_line(info: String) {
    with_game(|game| {
        game.info = info;
    });
}

fn lua_set_actions(actions: Vec<GameAction>) {
    with_game(|game| {
        game.actions = actions;
    });
}

fn lua_sleep(duration: u64) {
    crate::app::App::redraw();
    std::thread::sleep(std::time::Duration::from_millis(duration));
}
