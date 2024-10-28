local desc_1v2 = [[
  # 欢乐斗地主模式简介

  ___

  总体规则类似身份局。游戏由三人进行，一人扮演地主（主公），其他两人扮演农民（反贼）。

  地主选将框+2，增加一点体力上限和体力，且拥有以下额外技能：

  - **飞扬**：判定阶段开始时，你可以弃置两张手牌并弃置自己判定区内的一张牌。

  - **跋扈**：锁定技，准备阶段，你摸一张牌；出牌阶段，你可以多使用一张杀。

  当农民被击杀后，另一名农民可以选择：摸两张牌，或者回复一点体力。

  *击杀农民的人没有摸三张牌的奖励。*

  胜利规则与身份局一致。
]]

-- Because packages are loaded before gamelogic.lua loaded
-- so we can not directly create subclass of gamelogic in the top of lua
local m_1v2_getLogic = function()
  local m_1v2_logic = GameLogic:subclass("m_1v2_logic")

  function m_1v2_logic:initialize(room)
    GameLogic.initialize(self, room)
    self.role_table = {nil, nil, {"lord", "rebel", "rebel"}}
  end

  function m_1v2_logic:chooseGenerals()
    local room = self.room ---@type Room
    local generalNum = room.settings.generalNum
    for _, p in ipairs(room.players) do
      room:setPlayerProperty(p, "role_shown", true)
      room:broadcastProperty(p, "role")
    end

    local lord = room:getLord()
    room.current = lord
    local players = room.players
    -- 地主多发俩武将
    local generals = room:getNGenerals(#players * generalNum + 2)
    local req = Request:new(players, "AskForGeneral")
    for i, p in ipairs(players) do
      local arg = table.slice(generals, (i - 1) * generalNum + 1, i * generalNum + 1)
      if p.role == "lord" then
        local count = #generals
        table.insert(arg, generals[count])
        table.insert(arg, generals[count - 1])
      end
      req:setData(p, { arg, 1 })
      req:setDefaultReply(p, { arg[1] })
    end
    req:ask()
    local selected = {}
    for _, p in ipairs(players) do
      local general_ret
      general_ret = req:getResult(p)[1]
      room:setPlayerGeneral(p, general_ret, true, true)
      table.insertIfNeed(selected, general_ret)
    end
    generals = table.filter(generals, function(g) return not table.contains(selected, g) end)
    room:returnToGeneralPile(generals)
    for _, g in ipairs(selected) do
      room:findGeneral(g)
    end
    room:askForChooseKingdom(players)

    for _, p in ipairs(players) do
      room:broadcastProperty(p, "general")
    end
    room:setTag("SkipNormalDeathProcess", true)
  end


  function m_1v2_logic:attachSkillToPlayers()
    local room = self.room
    local players = room.players
  
    local addRoleModSkills = function(player, skillName)
      local skill = Fk.skills[skillName]
      if not skill then
        fk.qCritical("Skill: "..skillName.." doesn't exist!")
        return
      end
      if skill.lordSkill then
        return
      end
      if #skill.attachedKingdom > 0 and not table.contains(skill.attachedKingdom, player.kingdom) then
        return
      end
  
      room:handleAddLoseSkills(player, skillName, nil, false)
    end
    for _, p in ipairs(room.alive_players) do
      for _, s in ipairs(Fk.generals[p.general]:getSkillNameList(false)) do
        addRoleModSkills(p, s)
      end
      if p.role == "lord" then
        room:handleAddLoseSkills(p, "m_feiyang|m_bahu", nil, false)
      end
    end
  end

  return m_1v2_logic
end

local m_feiyang = fk.CreateTriggerSkill{
  name = "m_feiyang",
  anim_type = "control",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and
      player.phase == Player.Judge and
      #player:getCardIds(Player.Hand) >= 2 and
      #player:getCardIds(Player.Judge) > 0
  end,
  on_cost = function (self, event, target, player, data)
    local cards = player.room:askForDiscard(player, 2, 2, false, self.name, true, ".", "#m_feiyang-invoke", true)
    if #cards == 2 then
      self.cost_data = cards
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:throwCard(self.cost_data, self.name, player, player)
    local jcards = player:getCardIds("j")
    if #jcards == 0 then return end
    local card = #jcards == 1 and jcards[1] or room:askForCardChosen(player, player, "j", self.name)
    room:throwCard({card}, self.name, player, player)
  end
}
Fk:addSkill(m_feiyang)
local m_bahubuff = fk.CreateTargetModSkill{
  name = "#m_bahubuff",
  residue_func = function(self, player, skill, scope)
    if player:hasSkill(self) and skill.trueName == "slash_skill"
      and scope == Player.HistoryPhase then
      return 1
    end
  end,
}
local m_bahu = fk.CreateTriggerSkill{
  name = "m_bahu",
  anim_type = "drawcard",
  frequency = Skill.Compulsory,
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase == Player.Start
  end,
  on_use = function(self, event, target, player, data)
    player:drawCards(1, self.name)
  end,
}
m_bahu:addRelatedSkill(m_bahubuff)
Fk:addSkill(m_bahu)
local m_1v2_rule = fk.CreateTriggerSkill{
  name = "#m_1v2_rule",
  priority = 0.001,
  mute = true,
  events = {fk.BuryVictim},
  can_trigger = function(self, event, target, player, data)
    return target ~= player and target.rest == 0 and target.role == "rebel" and player.role == "rebel" and not player.dead
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local choices = {"m_1v2_draw2", "Cancel"}
    if player:isWounded() then
      table.insert(choices, 2, "m_1v2_heal")
    end
    local choice = room:askForChoice(player, choices, self.name)
    if choice == "m_1v2_draw2" then
      player:drawCards(2, self.name)
    else
      room:recover{ who = player, num = 1, skillName = self.name }
    end
  end,
}
Fk:addSkill(m_1v2_rule)
local m_1v2_mode = fk.CreateGameMode{
  name = "m_1v2_mode",
  minPlayer = 3,
  maxPlayer = 3,
  main_mode = "1v2_mode",
  rule = m_1v2_rule,
  logic = m_1v2_getLogic,
  surrender_func = function(self, playedTime)
    local surrenderJudge = { { text = "time limitation: 2 min", passed = playedTime >= 120 } }
    if Self.role ~= "lord" then
      table.insert(
        surrenderJudge,
        { text = "1v2: left you alive", passed = #table.filter(Fk:currentRoom().players, function(p) return p.rest > 0 or not p.dead end) == 2 }
      )
    end

    return surrenderJudge
  end,
  get_adjusted = function (self, player)
    if player.role == "lord" then
      return {hp = player.hp + 1, maxHp = player.maxHp + 1}
    end
    return {}
  end
}

Fk:loadTranslationTable{
  ["m_1v2_mode"] = "欢乐斗地主",
  ["m_feiyang"] = "飞扬",
  [":m_feiyang"] = "判定阶段开始时，你可以弃置两张手牌，然后弃置自己判定区的一张牌。",
  ["#m_feiyang-invoke"] = "飞扬：你可以弃置两张手牌，弃置自己判定区的一张牌",
  ["m_bahu"] = "跋扈",
  [":m_bahu"] = "锁定技，准备阶段，你摸一张牌；出牌阶段，你可以多使用一张【杀】。",
  ["#m_1v2_rule"] = "挑选遗产",
  ["m_1v2_draw2"] = "摸两张牌",
  ["m_1v2_heal"] = "回复1点体力",

  ["time limitation: 2 min"] = "游戏时长达到2分钟",
  ["1v2: left you alive"] = "仅剩你和地主存活",

  [":m_1v2_mode"] = desc_1v2,
}

return m_1v2_mode
