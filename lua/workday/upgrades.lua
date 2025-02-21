----------------------------------------------------------------
--- Upgrades

local function set_actions_select_die()
  local UPGRADE_COST = WD_UPGRADE_COST 
  if G.pt < UPGRADE_COST then
    game.log( "已经没有足够的业绩用来升级" )
    G.set_actions_next_day()
    return
  end

  local actions = {}
  for i = 1, #G.dice do
    local d = G.dice[i]
    local a = { name = "骰子" .. d.index, description = d:get_description() }
    a.execute = function(self)
      local cost = UPGRADE_COST
      if G.pt < cost then
        game.log( "所需消耗的业绩点不足" )
        G.set_actions_upgrade()
      else
        G.pt = G.pt - cost
        d:upgrade()
        set_actions_select_die()
      end
    end
    table.insert(actions, a)
  end
  local back = { name = "返回" }
  back.execute = function(self)
    G.set_actions_upgrade()
  end
  table.insert(actions, back)
  game.set_actions( actions )
end

function G.ActionEmpower:execute()
  set_actions_select_die()
end

function G.ActionLeverage:execute()
  local cost = math.tointeger(self.cost)
  if G.pt < cost then
    game.log( "所需消耗的业绩点不足" )
  else
    G.pt = G.pt - cost
    G.dice:add()
    game.log( "消耗" .. cost .. "业绩点，获得一个新的骰子" )
  end
  G.set_actions_upgrade()
end


----------------------------------------------------------------
--- Perks

local function make_perk_simple_bonus( value )
  return { name="平平无奇加" .. value .. "分", apply=function( roll )
    return roll + value
  end }
end

local function make_perk_zero()
  return { name="降本增笑（点数无效化）", apply=function( roll )
    return 0
  end }
end

local function make_perk_mul_2()
  return { name="直击痛点（双倍）", apply=function( roll )
    return roll * 2
  end }
end

local function make_perk_mul_3()
  return { name="打通链路（三倍）", apply=function( roll )
    return roll * 3
  end }
end

local function make_perk_mul_4()
  return { name="抓住风口（四倍）", apply=function( roll )
    return roll * 4
  end }
end

local function make_perk_mul_5()
  return { name="形成闭环（五倍）", apply=function( roll )
    return roll * 5
  end }
end

local function make_perk_mul_10()
  return { name="格局打开（十倍）", apply=function( roll )
    return roll * 10
  end }
end

local perks = {
  { 40, make_perk_simple_bonus(1) },
  { 30, make_perk_simple_bonus(2) },
  { 20, make_perk_simple_bonus(3) },
  { 10, make_perk_zero() },
  { 8, make_perk_mul_2() },
  { 8, make_perk_mul_3() },
  { 4, make_perk_mul_4() },
  { 2, make_perk_mul_5() },
  { 1, make_perk_mul_10() },
}

local function random_perk()
  local total_weight = 0
  for _, perk in ipairs(perks) do
    total_weight = total_weight + perk[1]
  end
  local idx = math.random(1, total_weight)
  for i, perk in ipairs(perks) do
    idx = idx - perk[1]
    if idx <= 0 then
      return perk[2]
    end
  end
  return nil
end

local function gacha( times )
  local cost = WD_GACHA_COST * times
  if G.pt < cost then
    game.log( "所需消耗的业绩点不足" )
  else
    G.pt = G.pt - cost
    for i = 1, times do
      local perk = random_perk()
      local die = G.dice[math.random(1, #G.dice)]
      local face = die[math.random(1, 6)]
      game.log( "骰子" .. die.index .. face:get_description() .. " <= " .. perk.name )
      face.perk = perk
    end
  end
end

function G.ActionGacha1:execute()
  gacha(1)
end

function G.ActionGacha10:execute()
  gacha(10)
end
