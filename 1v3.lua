local desc_1v3 = [[
  # 1v3简介

  虎牢关玩法，并基于目前的环境进行了一些魔改，目前处于测试中。

  座位：神吕布-中坚-先锋-大将

  胜利目标为击破全部敌方。

  ## 选择武将

  选将的顺序按照座位依次进行，即先锋-中坚-大将的顺序依次选将。
  
  若启用双将，则盟军选将之前吕布可以选择一名武将作为自己的副将。

  ## 分发初始手牌

  神吕布8张、中坚3张、先锋4张、大将5张。

  ## 阶段与行动顺序

  第一阶段中固定为中坚-吕布-先锋-吕布-大将-吕布，无视座位变化。

  当神吕布的体力值即将降低到4或者更低时或者牌堆首次洗切时，神吕布立刻进入第二阶段：（6血6上限，
  随机变更为暴怒战神或者神鬼无前（若启用双将则改为自选），复原并弃置判定区内所有牌，结束一切结算并
  终止本轮游戏，进入新一轮并由神吕布第一个行动）

  第二阶段后，按照座次正常进行行动。

  ## 其他

  撤退：被神吕布击杀的联军改为休整4轮（若启用双将则改为6轮）。第一阶段中，因休整而消耗的回合不会导致神吕布进行回合。
  
  重整：完成休整后的角色回满并摸6-X张牌（X为其体力值），复活的回合不能行动。

  特殊摸牌：有联军撤退或阵亡时，队友可以选择是否摸两张牌或回复一点体力（若启用双将则改为是否摸一张牌）。

  武器重铸：该模式下武器牌可重铸。

]]

local recastSkill = fk.CreateActiveSkill{
  name = "1v3_recast_weapon&",
  anim_type = "drawcard",
  card_num = 1,
  card_filter = function(self, to_select, selected)
    return Fk:getCardById(to_select).sub_type == Card.SubtypeWeapon and
      Fk:currentRoom():getCardArea(to_select) == Card.PlayerHand and
      not Self:prohibitDiscard(Fk:getCardById(to_select))
  end,
  target_filter = Util.FalseFunc,
  on_use = function(self, room, effect)
    room:recastCard(effect.cards, room:getPlayerById(effect.from))
  end,
}
Fk:addSkill(recastSkill)

local m_1v3_getLogic = function()
  ---@class Logic1v3: GameLogic
  local m_1v3_logic = GameLogic:subclass("m_1v3_logic")

  function m_1v3_logic:assignRoles()
    local room = self.room
    local n = #room.players
    local roles = { "lord", "rebel", "rebel", "rebel" }

    for i = 1, n do
      local p = room.players[i]
      p.role = roles[i]
    end
  end

  function m_1v3_logic:chooseGenerals()
    local room = self.room ---@type Room
    local generalNum = room.settings.generalNum
    local n = room.settings.enableDeputy and 2 or 1
    for _, p in ipairs(room.players) do
      p.role_shown = true
      room:broadcastProperty(p, "role")
    end

    local lord = room:getLord()
    room.current = lord
    for _, p in ipairs(room.players) do
      local general, deputy
      if p.role == "lord" then
        general = "hulao__godlvbu1"
        if n == 2 then
          local generals = Fk:getGeneralsRandomly(generalNum, nil, nil, function(g)
            return g.name:startsWith("hulao__")
          end)
          generals = table.map(generals, Util.NameMapper)
          deputy = room:askForGeneral(p, generals, 1)
        else
          -- TODO: 需要深入，目前头疼医头
          p.request_timeout = room.timeout
          local start = os.getms()
          p.request_start = start
        end
      else
        local generals = Fk:getGeneralsRandomly(generalNum, nil, nil, function(g)
          return g.name:startsWith("hulao__")
        end)
        generals = table.map(generals, Util.NameMapper)
        local g = room:askForGeneral(p, generals, n)
        if n == 1 then g = { g } end
        general, deputy = table.unpack(g)
      end
      room:setPlayerGeneral(p, general, true, true)
      if deputy then
        p.deputyGeneral = deputy
      end
      room:broadcastProperty(p, "general")
      room:broadcastProperty(p, "deputyGeneral")
      room:broadcastProperty(p, "kingdom")
    end
    room:askForChooseKingdom(room:getOtherPlayers(lord))
  end

  function m_1v3_logic:attachSkillToPlayers()
    local room = self.room
    local players = room.players

    local addRoleModSkills = function(player, skillName)
      local skill = Fk.skills[skillName]
      if not skill then return end
      if skill.lordSkill then return end

      if #skill.attachedKingdom > 0 and not table.contains(skill.attachedKingdom, player.kingdom) then
        return
      end

      room:handleAddLoseSkills(player, skillName, nil, false)
    end
    for _, p in ipairs(room.alive_players) do
      local general = Fk.generals[p.general]
      local deputy = Fk.generals[p.deputyGeneral]

      if p.role == "lord" then
        room:changeMaxHp(p, 8 - p.maxHp)
        room:changeHp(p, 8 - p.hp)
      end

      local skills = general.skills
      for _, s in ipairs(skills) do addRoleModSkills(p, s.name) end
      for _, sname in ipairs(general.other_skills) do
        addRoleModSkills(p, sname)
      end

      if deputy then
        skills = deputy.skills
        for _, s in ipairs(skills) do addRoleModSkills(p, s.name) end
        for _, sname in ipairs(deputy.other_skills) do
          addRoleModSkills(p, sname)
        end
      end

      room:handleAddLoseSkills(p, "1v3_recast_weapon&")
    end
  end

  ---@class HulaoRound: GameEvent.Round
  local hulaoRound = GameEvent.Round:subclass("HulaoRound")
  function hulaoRound:action()
    local room = self.room

    -- 行动顺序：反1->主->反2->主->反3->主，若已暴怒则正常逻辑
    if not room:getTag("m_1v3_phase2") then
      local p1 = room:getLord()
      room.current = p1 -- getOtherPlayers
      for _, p in ipairs(room:getOtherPlayers(p1, true, true)) do
        room.current = p
        GameEvent.Turn:create(p):exec()
        if room.game_finished then break end
        if not p.dead then
          room.current = p1
          GameEvent.Turn:create(p1):exec()
          if room.game_finished then break end
        end
      end
    else
      GameEvent.Round.action(self)
    end
  end

  function m_1v3_logic:action()
    self:trigger(fk.GamePrepared)
    local room = self.room
    room:setTag("SkipNormalDeathProcess", true)

    GameEvent.DrawInitial:create():exec()

    while true do
      hulaoRound:create():exec()
      if room.game_finished then break end
    end
  end

  return m_1v3_logic
end
local m_1v3_rule = fk.CreateTriggerSkill{
  name = "#m_1v3_rule",
  priority = 0.001,
  refresh_events = {
    fk.DrawInitialCards,
    fk.BeforeGameOverJudge, fk.Deathed, fk.AfterPlayerRevived,
    fk.BeforeHpChanged, fk.AfterDrawPileShuffle,
  },
  can_refresh = function(self, event, target, player, data)
    if target ~= player then return false end
    local room = player.room
    if event == fk.BeforeGameOverJudge then
      return player.role ~= "lord"
    elseif event == fk.AfterPlayerRevived then
      return player.tag["hulaoRest"] and player.hp < 6
    elseif event == fk.BeforeHpChanged then
      return player.role == "lord" and not room:getTag("m_1v3_phase2") and
        player.hp + data.num <= 4
    elseif event == fk.AfterDrawPileShuffle then
      return  not room:getTag("m_1v3_phase2")
    end
    return true
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    local n = room.settings.enableDeputy and 2 or 1
    if event == fk.DrawInitialCards then
      if player.seat == 1 then data.num = 8
      else data.num = player.seat + 1 end
    elseif event == fk.AfterPlayerRevived then
      player:drawCards(6 - player.hp, self.name)
    elseif event == fk.BeforeGameOverJudge then
      if data.damage and data.damage.from == room:getLord() then
        player._splayer:setDied(false)
        if n == 1 then 
         room:setPlayerRest(player, 4)
        else
          room:setPlayerRest(player, 6)
        end
        player.tag["hulaoRest"] = true
      end
      local onlyLvbu = #room:getOtherPlayers(room:getLord()) == 0
      if onlyLvbu then
        room:gameOver("lord")
      end
    elseif event == fk.Deathed then
      for _, p in ipairs(room.alive_players) do
        if p.role == player.role then
         if n == 2 then
           if room:askForSkillInvoke(p, self.name, nil, "#m_1v3_death_draw") then
              p:drawCards(1)
            end
          else
            local choices = {"#m_1v3_draw2", "Cancel"}
            if p:isWounded() then
              table.insert(choices, 2, "#m_1v3_heal")
            end
            local choice = room:askForChoice(p, choices, self.name)
            if choice == "#m_1v3_draw2" then p:drawCards(2, self.name)
            else room:recover{ who = p, num = 1, skillName = self.name } end
          end
        end
      end
    elseif event == fk.BeforeHpChanged or event == fk.AfterDrawPileShuffle then
      local round = room.logic:getCurrentEvent():findParent(GameEvent.Round)
      room:notifySkillInvoked(player, "m_1v3_convert", "big")
      room:setTag("m_1v3_phase2", true)
      local generals = { "hulao__godlvbu2", "hulao__godlvbu3" }
      local g = {}
      if n == 1 then 
        g = table.random(generals)
      else g = room:askForGeneral(player, generals, 1, true) end
      room:changeHero(player, g, false, false, true, false, false)
      room:changeMaxHp(player, 6 - player.maxHp)
      room:changeHp(player, 6 - player.hp, nil, self.name)
      player:throwAllCards('j')
      if player.chained then
        player:setChainState(false)
      end
      if not player.faceup then
        player:turnOver()
      end
      if round then
        room.current = player
        round:shutdown()
      end
    end
  end,

  events = {fk.BeforeTurnStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player.tag["hulaoRest"]
  end,
  on_trigger = function(self, event, target, player, data)
    player.tag["hulaoRest"] = false
    return true
  end
}
Fk:addSkill(m_1v3_rule)
local m_1v3_mode = fk.CreateGameMode{
  name = "m_1v3_mode",
  minPlayer = 4,
  maxPlayer = 4,
  rule = m_1v3_rule,
  logic = m_1v3_getLogic,
  surrender_func = function(self, playedTime)
    local surrenderJudge = { { text = "time limitation: 5 min", passed = playedTime >= 300 },
    { text = "2v2: left you alive", passed = not table.find(Fk:currentRoom().players, function(p)
      return p ~= Self and p.role == Self.role and not (p.dead and p.rest == 0)
    end) } }
    return surrenderJudge
  end,
  winner_getter = function(self, victim)
    if not victim.surrendered and victim.rest > 0 then
      return ""
    end
    local room = victim.room
    local alive = table.filter(room.players, function(p) ---@type Player[]
      return not p.surrendered and not (p.dead and p.rest == 0)
    end)
    local winner = alive[1].role
    for _, p in ipairs(alive) do
      if p.role ~= winner then
        return ""
      end
    end
    return winner
  end,
}
Fk:loadTranslationTable{
  ["m_1v3_mode"] = "虎牢关1v3",
  [":m_1v3_mode"] = desc_1v3,
  ["#m_1v3_death_draw"] = "是否摸一张牌？",
  ["#m_1v3_draw2"] = "摸两张牌",
  ["#m_1v3_heal"] = "回复1点体力",
  ["#m_1v3_rule"] = "虎牢关规则",
  ["m_1v3_convert"] = "暴怒",
  -- ["time limitation: 2 min"] = "游戏时长达到2分钟",
  -- ["2v2: left you alive"] = "你所处队伍仅剩你存活",
  ["1v3_recast_weapon&"] = "武器重铸",
  [":1v3_recast_weapon&"] = "你可以重铸手里的武器牌。",
}

return m_1v3_mode
