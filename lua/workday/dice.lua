local DieFace = {}

function DieFace.new(die_idx, face)
  local obj = { face=face, die_index=die_idx, value=face, perk={} }

  function obj:eval()
    local score = self.value
    local perk_msg = ""
    if self.perk.apply then
      score = self.perk.apply(score)
      perk_msg = " (" .. self.perk.name .. "生效)"
    end
    game.log( "骰子" .. self.die_index .. "掷出了" .. self.face .. " - 分数为：" .. score .. perk_msg )
    return score
  end

  function obj:get_description()
    local desc = "面" .. self.face .. " 值：" .. self.value .. " 特效：" .. (self.perk.name or "无")
    return desc
  end

  return obj
end

local Die = {}

function Die.new(idx)
  local obj = {
    DieFace.new(idx, 1),
    DieFace.new(idx, 2),
    DieFace.new(idx, 3),
    DieFace.new(idx, 4),
    DieFace.new(idx, 5),
    DieFace.new(idx, 6),
    index = idx,
  }

  function obj:roll()
    local idx = math.random(1, 6)
    return self[idx]
  end

  function obj:upgrade()
    local idx = math.random(1, 6)
    local gain = math.random(3, 6)
    self[idx].value = self[idx].value + gain
    game.log( "骰子面" .. idx .. "分数提升了" .. gain .. "点，现在是" .. self[idx].value .. "点" )
  end

  function obj:get_description()
    local desc = ""
    for _, face in ipairs(self) do
      desc = desc .. face:get_description() .. "\n"
    end
    return desc
  end

  return obj
end

local Dice = {}

function Dice.new()
  local obj = { Die.new(1) }

  function obj:roll()
    local sum = 0
    for _, die in ipairs(self) do
      local face = die:roll()
      sum = sum + face:eval()
    end
    return sum
  end

  function obj:add()
    table.insert(self, Die.new(#self + 1))
  end

  return obj
end

dice = {
  Dice = Dice,
  Die = Die,
  DieFace = DieFace,
}

return dice;
