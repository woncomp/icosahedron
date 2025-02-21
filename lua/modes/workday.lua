WD_UPGRADE_COST = 200
WD_GACHA_COST = 100

require( "workday/dice" )
require( "workday/actions" )
require( "workday/days" )
require( "workday/upgrades" )

G = G or {}


function update_info_line()
  local line = "第" .. G.day .. "天 | 心情：" .. G.hp .. "/" .. G.max_hp ..  " | 业绩：" .. G.pt .. " | 职级：" .. G.rank
  game.set_info_line(line)
end

function G.game_setup()
  G.day = 0
  G.hp = 100
  G.max_hp = 100
  G.pt = 0
  G.rank = 10
  G.dice = dice.Dice.new()

  game.log("偶尔在人生的大道上驻足休息一下，惊讶的发现，已经有若干年记不清自己的年龄了。")
  game.log("向后看看，你曾经留下了数不清的社畜的脚印，向前看看，依然是数不清的社畜的日子。")
  game.log("刚离开校园时那种对大城市打拼的憧憬与热情早已在日复一日的勤恳工作中磨灭殆尽。")
  game.log("俗话说得好，只要能吃苦，就有吃不完的苦。")
  game.log("这社畜的人生何时是个尽头，又有什么在前路等待？")
  game.log("但你并没有游刃有余到可以在这件事上伤感太久。生活的重压告诉你，你的眼睛还不能从业绩上移开。")

  G.set_actions_next_day()
  
  update_info_line()
end

function G.game_tick(action)
  action:execute()
  update_info_line()
end

return G
