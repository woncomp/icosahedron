local function fibonacci_recursive(n)
    if n <= 0 then
        return 0
    elseif n == 1 then
        return 1
    else
        return fibonacci_recursive(n - 1) + fibonacci_recursive(n - 2)
    end
end

local function fib(n)
  return fibonacci_recursive(n)
end

local function resolve_work( score, cost )
  local bonus = score * G.rank
  G.pt = G.pt + bonus
  G.hp = G.hp - cost
  return "总得点" .. score .. " 乘以职级系数" .. G.rank .. " => 业绩+" .. bonus .. " 能量-" .. cost
end

local function day_work()
  local cost = 10 * #G.dice
  if G.hp <= cost then
    game.log( "能量余额已不足，无法工作" )
    G.set_actions_force_rest()
    return
  end
  local roll = G.dice:roll()
  local report = resolve_work( roll, cost )
  game.log( report )
end


local function day_work_ot()
  local cost = 20 * #G.dice
  if G.hp <= cost then
    game.log( "能量余额已不足，无法工作" )
    G.set_actions_force_rest()
    return
  end
  local roll = G.dice:roll()
  local report = resolve_work( roll, cost )
  game.log( report .. "（三倍工资）" )
end

local function day_work_996()
  local cost = 15 * #G.dice
  if G.hp <= cost then
    game.log( "能量余额已不足，无法工作" )
    G.set_actions_force_rest()
    return
  end
  local roll = G.dice:roll()
  local report = resolve_work( roll, cost )
  game.log( report .. "（1.5倍消耗）")
end

local function day_accessment()
  local roll = G.dice:roll()
  local score = roll * 10
  local requirement = fib(G.rank)
  local pass = score > requirement
  if pass then
    G.rank = G.rank + 1
  end
  game.log( "评估成绩 " .. score .. "，需求：" .. requirement .. "，" .. (pass and "。通过，职级上升！" or "未通过" ) )
end

local function day_sick()
  local roll = G.dice:roll()
  local mod = roll * 5
  G.hp = G.hp - mod
  game.log( "消耗能量 " .. mod )
end

local function day_rest()
  local roll = math.random(1, 6)
  local mod = math.tointeger(math.ceil( G.max_hp * (20 + roll * 5) / 100 ))
  G.hp = G.hp + mod
  game.log( "恢复能量 " .. mod )
  G.set_actions_next_day()
end

local function day_workout()
  local cost = 40
  local exhasted = G.hp < cost
  local half = G.hp < (cost / 2)
  local gain = 20
  if exhasted then
    G.hp = 0
    if half then
      G.max_hp = G.max_hp + gain / 2
      game.log( "自律的锻炼给你带来强健的体魄。但因体力不支，晕倒在健身房。最大能量值少许提升。你现在最需要的是休息。" )
    else
      G.max_hp = G.max_hp + gain
      game.log( "自律的锻炼给你带来强健的体魄，最大能量值提升。但你已经筋疲力尽，明天恐怕是没办法上班了。" )
    end
    G.set_actions_force_rest()
  else
    G.hp = G.hp - cost
    G.max_hp = G.max_hp + gain
    game.log( "自律的锻炼给你带来强健的体魄，最大能量提升 " .. gain .. "，消耗能量 " .. cost )
  end
end

local function day_upgrade()
  game.log( "今天的老师又讲得干货满满。但更重要得是，培训的时候可以不干活。" )
  G.set_actions_upgrade()
end

local function day_comicon()
  game.log( "抢本子，买谷子，排长队，吃泡面。Oops，又开了个盲盒，我怎么就管不住这手呢。" )
  G.set_actions_comicon()
end


local days =  {
  { 20, "牛马的一天", day_work }, -- 正常roll点，10点消耗每骰子
  { 20, "法定节假日加班", day_work_ot }, -- 三倍工资，20点消耗每骰子
  { 10, "996就是福报", day_work_996 }, -- 正常roll点，15点消耗每骰子
  { 10, "职级评审", day_accessment }, -- roll点得到随机数，如果超过当前职级需要的点数则职级提升1
  { 5, "生病了", day_sick }, -- 根据roll点结果消耗能量
  { 10, "躺平", day_rest }, -- 根据roll点结果恢复能量
  { 5, "撸铁", day_workout }, -- 消耗能量提升能量上限，如果能量不足效果会打折扣
  { 10, "漫展", day_comicon }, -- 消耗一定数量的资源，为一个随机的骰子面抽取额外效果
  { 10, "培训", day_upgrade }, -- 升级
}

local function random_day()
  local total_weight = 0
  for _, day in ipairs(days) do
    total_weight = total_weight + day[1]
  end
  local idx = math.random(1, total_weight)
  for i, day in ipairs(days) do
    idx = idx - day[1]
    if idx <= 0 then
      return day
    end
  end
  return nil
end


function G.ActionNextDay:execute()
  G.set_actions_next_day()
  G.day = G.day + 1
  local day = random_day()
  game.log( "\n【 第" .. G.day .. "天 - " .. day[2] .. " 】" )
  day[3]()
  if G.hp < 0 then
    G.hp = 0
  elseif G.hp > 100 then 
    G.hp = 100
  end
end

function G.ActionForceRest:execute()
  G.day = G.day + 1
  game.log( "\n【 第" .. G.day .. "天 - " .. "被迫休息" .. " 】" )
  day_rest()
end
