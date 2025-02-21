use mlua::{FromLuaMulti, IntoLuaMulti, Lua, Table};

#[derive(Debug, Default)]
pub struct GameLua {
    lua: Lua,
}

impl GameLua {
    pub fn init(&mut self) -> mlua::Result<()> {
        let lua = &mut self.lua;

        let custom_print = lua.create_function(|_, msg: String| {
            tracing::info!("[LUA] {}", msg); // Redirect print to tracing
            Ok(())
        })?;
        lua.globals().set("print", custom_print)?;

        {
            let game: Table = lua.create_table()?;
            let funcs = lua.create_table()?;
            let binder = LuaBinder { lua, table: &funcs };
            crate::game::register_lua_functions(&binder);
            game.set("native_functions", funcs)?;
            lua.globals().set("game", game)?;
        }

        let package: Table = lua.globals().get("package")?;

        let path1: String = package.get("path")?;
        let path2: String = format!(
            "{}/?.lua;{}",
            std::env::current_dir()?.join("lua").display(),
            path1
        );
        tracing::info!("[mlua] package.path={:?}", path2);
        package.set("path", path2)?;

        match lua.load("require('game')").exec() {
            Ok(()) => (),
            Err(err) => {
                tracing::info!("[mlua] {}", err.to_string());
                return Err(err);
            }
        }

        Ok(())
    }

    // pub fn lua_init(&mut self) -> mlua::Result<()> {
    //     // Call the module function
    //     let init_func: mlua::Function = self.lua.globals().get("native_call_lua_init")?;
    //     match init_func.call(()) {
    //         Ok(()) => Ok(()),
    //         Err(err) => {
    //             tracing::info!("[mlua] {}", err.to_string());
    //             return Err(err);
    //         }
    //     }
    // }

    pub fn lua_setup(&mut self) {
        let lua = &self.lua;
        let func: mlua::Function = lua.globals().get("native_call_game_setup").unwrap();
        match func.call(()) {
            Ok(()) => (),
            Err(err) => {
                tracing::info!("[mlua] {}", err.to_string());
                panic!("{}", err.to_string());
            }
        };
    }

    pub fn lua_tick(&mut self, action: usize) {
        let lua = &self.lua;
        let func: mlua::Function = lua.globals().get("native_call_game_tick").unwrap();
        match func.call::<()>(action + 1) {
            Ok(()) => (),
            Err(err) => {
                tracing::info!("[mlua] {}", err.to_string());
                panic!("{}", err.to_string());
            }
        };
    }
}

pub struct LuaBinder<'a> {
    lua: &'a Lua,
    table: &'a Table,
}

impl<'a> LuaBinder<'a> {
    pub fn reg<F, A, R>(&self, name: &str, func: F)
    where
        F: Fn(A) -> R + 'static,
        A: FromLuaMulti,
        R: IntoLuaMulti,
    {
        let lua_func = self
            .lua
            .create_function(move |_, args| Ok(func(args)))
            .unwrap();
        self.table.set(name, lua_func).unwrap();
    }
}
