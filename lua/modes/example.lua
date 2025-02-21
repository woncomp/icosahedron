local G = {}
G.pt = 0
G.face_power = {
  1, 2, 3, 4, 5, 6,
}

local ACTIONS = {
    { name = "投掷一次", description = "简单的投掷一次，增加对应分数。" },
    { name = "投掷两次", description = "简单的投掷两次，增加对应分数。" },
    { name = "强化骰子", description = "选择骰子的一个面，让这个面奖励的分数增加一个随机值。" },
}

-- G.game_setup 游戏模式必须实现这个函数，用来设置游戏初始状态
function G.game_setup()
  game.log("你好，世界！") -- log 向日志窗口添加一条消息

  -- set_actions 设置玩家可以执行的动作列表。每一个动作至少有一个 name 和一个 description 字段。
  -- 当代码执行完当前阶段，控制权交回给玩家的时候，玩家就可以从这个列表中选择一个动作执行。
  game.set_actions(ACTIONS)
end

-- G.game_tick 游戏模式必须实现这个函数，用来处理每次的玩家指令
function G.game_tick(action)
  local name = action.name
  if name == "投掷一次" then
    local roll = math.random(1, 6)
    local bonus = G.face_power[roll]
    game.log("掷出了 " .. roll .. "，获得分数 " .. bonus)
    G.pt = G.pt + bonus
  elseif name == "投掷两次" then
    game.set_actions() -- 清空动作列表，在一个复杂动作的执行过程中，禁掉玩家可以选择动作的UI。
    local sum = 0
    for i = 1, 2 do
      local roll = math.random(1, 6)
      local bonus = G.face_power[roll]
      game.log("掷出了 " .. roll .. "，获得分数 " .. bonus)
      game.sleep(1000) -- sleep 会触发刷新UI，并短时间等待（毫秒）。在一个Action包含多个步骤时，可以用来制造节奏感。
      sum = sum + bonus
    end
    G.pt = G.pt + sum
    game.log("一共获得分数" .. sum)
    game.set_actions(ACTIONS) -- 执行动作完成后，别忘了恢复动作列表。
  elseif name == "强化骰子" then
    -- 可选动作列表可以根据当前状态的需要动态改变。
    game.set_actions({
      { name="第一面", description="选择这个面进行强化。此面当前的奖励分数是" .. G.face_power[1], id=1 },
      { name="第二面", description="选择这个面进行强化。此面当前的奖励分数是" .. G.face_power[2], id=2 },
      { name="第三面", description="选择这个面进行强化。此面当前的奖励分数是" .. G.face_power[3], id=3 },
      { name="第四面", description="选择这个面进行强化。此面当前的奖励分数是" .. G.face_power[4], id=4 },
      { name="第五面", description="选择这个面进行强化。此面当前的奖励分数是" .. G.face_power[5], id=5 },
      { name="第六面", description="选择这个面进行强化。此面当前的奖励分数是" .. G.face_power[6], id=6 },
    })

    game.log("选择一个面进行强化。")
  else
    G.upgrade_die_face(action)
  end

  game.set_info_line("当前分数：" .. G.pt) -- set_info_line 用来修改UI上 Info 框里的内容
end

function G.upgrade_die_face(action)
  local face = action.id
  local face_power = G.face_power[face]
  local grow = math.random(2, 4)
  local new_face_power = face_power + grow
  G.face_power[face] = new_face_power
  game.log("强化了第" .. face .. "面，掷出了" .. grow .. "，新的奖励分数是" .. new_face_power)
  game.set_actions(ACTIONS) -- 回到主菜单
end

return G
