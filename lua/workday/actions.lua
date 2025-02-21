G = G or {}

G.ActionNextDay = { name="下一天", description="不知道会迎来怎样的一天" }
G.ActionInspect = { name="查看骰子", description="查看所有骰子的信息" }
G.ActionForceRest = { name="强制休息", description="已经被榨干。" }
G.ActionEmpower = { name="赋能", description="消耗" .. WD_UPGRADE_COST .. "业绩点，选择一个骰子进行强化，其中随机的一个面会被强化。" }
G.ActionLeverage = { name="杠杆" }

G.ActionGacha1 = { name="抽一次", description="每一次抽取可以让一个随机骰面获得一个随机效果。" }
G.ActionGacha10 = { name="十连抽", description="必出金（雾" }

function G.set_actions_next_day()
  game.set_actions( {G.ActionNextDay, G.ActionInspect} )
end

function G.set_actions_force_rest()
  game.set_actions( {G.ActionForceRest} )
end

function G.set_actions_upgrade()
  G.ActionLeverage.cost = math.pow(4, #G.dice) * 100
  G.ActionLeverage.get_description = function(self)
    return "消耗" .. self.cost .. "业绩点，获得一个新的骰子。\n骰子增加之后，各种行动的费用也会相应增加。\n在所有需要掷点的时候，都会同时投掷所有骰子，无论是正面效果还是负面效果。"
  end
  game.set_actions( {G.ActionEmpower, G.ActionLeverage, G.ActionNextDay } )
end

function G.set_actions_comicon()
  game.set_actions( {G.ActionGacha1, G.ActionGacha10, G.ActionNextDay } )
end

function G.ActionInspect:execute()
  game.log("")
  for _, die in ipairs(G.dice) do
    game.log("-------------------------")
    for _, face in ipairs(die) do
      game.log( "骰子" .. die.index .. "" .. face:get_description() )
    end
  end
end
