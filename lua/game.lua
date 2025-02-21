-- native calls


game = game or {}

local current_game_mode = nil

function native_call_game_setup()
  game.log("游戏启动，按ESC退出游戏。先选择一个游戏模式。")

  game.set_actions({
    {
      name = "Hello World",
      description = "(example.lua) 简单的roll点。用于演示代码如何工作。",
      entry = "example",
    },
    {
      name = "牛马的一天",
      description = "(workday.lua) 稍微有点游戏规则的范例。",
      entry = "workday",
    }
  })
end

function native_call_game_tick(action_index)
  action = game.cached_actions[action_index];
  if current_game_mode == nil then
    current_game_mode = require( "modes/" .. action.entry )
    current_game_mode.game_setup()
    else
    current_game_mode.game_tick(action)
  end
end

local F = game.native_functions

function game.log( message )
  F.log( message )
end

function game.set_info_line( info )
  F.set_info_line( info )
end

function game.set_actions( actions )
  actions = actions or {}
  game.cached_actions = actions
  local list = {}
  for idx, action in ipairs( actions ) do
    local a = {}
    if action.name then
      a.name = action.name
    elseif action.get_name then
      a.name = action:get_name()
    else
      a.name = "行动" .. idx
    end
    if action.description then
      a.description = action.description
    elseif action.get_description then
      a.description = action:get_description()
    else
      a.description = ""
    end
    table.insert( list, a )
  end
  F.set_actions( list )
end

function game.sleep( time )
  F.sleep( time )
end
