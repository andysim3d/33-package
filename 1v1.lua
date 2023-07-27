local desc_1v1 = [[
  # 1v1模式简介

  两人进行对战的竞技化模式，进行车轮战，先死亡第三张武将的玩家失败，对手获胜。

  ___

  ## 游戏流程

  1. **决定行动顺序**。随机决定先手角色和后手角色。

  2. **挑选武将**。抽取12张武将牌，正面朝上亮出，由后手玩家开始，按照1222221的顺序选择武将。（以下暂无）从所有武将中先每人随机分配3张武将牌作为暗将，暗将对对方保密。然后从剩余武将牌中随机抽取6张，正面朝上亮出，由后手玩家开始，按照1221的顺序选择武将。

  3. **选择第一名登场武将**。双方各从自己所拥有的6张武将牌中选择首发武将，同时正面朝上亮出。

  4. **分发起始手牌**。双方各自摸X张牌，作为其起始手牌（X为体力上限且至多为5）。

  5. **游戏开始**。由先手玩家先开始自己的回合，且首回合摸牌阶段摸牌数-1。后手玩家回合结束后，先手玩家回合开始，依次轮流直到游戏结束。

  6. **武将死亡**。当某一角色的武将死亡时，若游戏未结束，则弃置其区域内的所有牌，由该玩家选择下一名登场武将，然后并摸起始手牌。特别地，如果玩家在自己的回合内武将死亡，则其回合立即结束。

  7. **游戏结束**。当某一角色的第三名登场武将死亡时，游戏立即结束，对手获胜。

]]

local m_1v1_getLogic = function()
  local m_1v1_logic = GameLogic:subclass("m_1v1_logic")

  function m_1v1_logic:chooseGenerals()
    local room = self.room
    local generalNum = 12

    local lord = room.players[1]
    room.current = lord
    local nonlord = room.players[2]

    local lord_generals = {}
    local nonlord_generals = {}
    local all_generals = table.map(Fk:getGeneralsRandomly(12), function(g) return g.name end)
    
    local function removeSame(t, n)
      local same = Fk:getSameGenerals(n)
      for i, v in ipairs(t) do
        if table.contains(same, v) or (v == n) then
          table.remove(t, i)
          return
        end
      end
    end

    local function chooseGeneral(p, n)
      local g = room:askForGeneral(p, all_generals, n)
      if type(g) == "string" then g = {g} end
      local str = p == lord and "1v1 Lord choose" or "1v1 Rebel choose"
      local t = p == lord and lord_generals or nonlord_generals
      table.insertTable(t, g)
      removeSame(all_generals, g[1])
      if g[2] then removeSame(all_generals, g[2]) end
      room:doBroadcastNotify("ShowToast", Fk:translate(str) .. Fk:translate(g[1]) .. ' ' .. Fk:translate(g[2] or ""))
    end

    -- 1-2-2-2-2-2-1
    chooseGeneral(nonlord, 1)
    chooseGeneral(lord, 2)
    chooseGeneral(nonlord, 2)
    chooseGeneral(lord, 2)
    chooseGeneral(nonlord, 2)
    chooseGeneral(lord, 2)
    chooseGeneral(nonlord, 1)

    lord.request_data = json.encode({ lord_generals, 1 })
    lord.default_reply = lord_generals[1]
    nonlord.request_data = json.encode { nonlord_generals, 1 }
    nonlord.default_reply = nonlord_generals[1]

    room:doBroadcastNotify("ShowToast", Fk:translate("1v1 choose general"))
    room:doBroadcastRequest("AskForGeneral", room.players)
    for _, p in ipairs(room.players) do
      local tab = p == lord and lord_generals or nonlord_generals
      if p.general == "" and p.reply_ready then
        local general = json.decode(p.client_reply)[1]
        room:setPlayerGeneral(p, general, true, true)
        table.removeOne(tab, general)
      else
        room:setPlayerGeneral(p, p.default_reply, true, true)
        table.removeOne(tab, p.default_reply)
      end
      p.default_reply = ""
    end

    room:broadcastProperty(lord, "role")
    room:broadcastProperty(nonlord, "role")
    room:broadcastProperty(lord, "general")
    room:broadcastProperty(nonlord, "general")
    room:broadcastProperty(lord, "kingdom")
    room:broadcastProperty(nonlord, "kingdom")
    room:setPlayerMark(lord, "_1v1_generals", lord_generals)
    room:setPlayerMark(nonlord, "_1v1_generals", nonlord_generals)
    room:askForChooseKingdom()
  end

  return m_1v1_logic
end
local m_1v1_rule = fk.CreateTriggerSkill{
  name = "#m_1v1_rule",
  priority = 0.001,
  refresh_events = {fk.DrawInitialCards, fk.DrawNCards, fk.GameOverJudge, fk.BuryVictim},
  can_refresh = function(self, event, target, player, data)
    return target == player
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    if event == fk.DrawInitialCards then
      data.num = math.min(player.maxHp, 5)
    elseif event == fk.DrawNCards then
      if player.seat == 1 and player:getMark(self.name) == 0 then
        room:addPlayerMark(player, self.name, 1)
        room:setTag("SkipNormalDeathProcess", true)
        data.n = data.n - 1
      end
    elseif event == fk.GameOverJudge then
      room:setTag("SkipGameRule", true)
      local body = room:getPlayerById(data.who)
      local generals = body:getMark("_1v1_generals")
      local num, num2
      for _, p in ipairs(room.players) do
        local n = 5 - #p:getMark("_1v1_generals")
        if p == body then n = n + 1 end
        if p.role == "lord" then
          num = n
        else
          num2 = n
        end
      end
      room:doBroadcastNotify("ShowToast", Fk:translate("1v1 score") .. tostring(num) .. ":" .. tostring(num2) .. Fk:translate("_1v1 score"))
      if #generals > 3 then return end
      room:gameOver(body.next.role)
      return true
    else
      room:setTag("SkipGameRule", true)
      local body = room:getPlayerById(data.who)
      local generals = body:getMark("_1v1_generals")
      body:bury()

      local current = room.logic:getCurrentEvent()
      local last_event
      if room.current == body then
        last_event = current:findParent(GameEvent.Turn, true)
      elseif table.contains({GameEvent.Round, GameEvent.Turn}, current.event) then
        last_event = current
      else
        last_event = current
        repeat
          if last_event.parent.event == GameEvent.Phase then break end
          last_event = last_event.parent
        until not last_event
      end
      last_event:addExitFunc(function()
        local g = room:askForGeneral(body, generals, 1)
        if type(g) == "table" then g = g[1] end
        table.removeOne(generals, g)
        room:changeHero(body, g, true, false, true)

        -- trigger leave

        room:revivePlayer(body, false)
        room:setPlayerProperty(body, "kingdom", Fk.generals[g].kingdom)
        room:setPlayerProperty(body, "hp", Fk.generals[g].hp)
        body:drawCards(math.min(body.maxHp, 5), self.name)
        room:setPlayerMark(body, "_1v1_generals", generals)
      end)
    end
  end,
}
local m_1v1_mode = fk.CreateGameMode{
  name = "m_1v1_mode",
  minPlayer = 2,
  maxPlayer = 2,
  rule = m_1v1_rule,
  logic = m_1v1_getLogic,
  surrender_func = function(self, playedTime)
    return { { text = "1v1: left last one", passed = Self:getMark("_1v1_generals") ~= 0 and #Self:getMark("_1v1_generals") == 3 } }
  end,
  winner_getter = function(self, victim)
    local room = victim.room
    local alive = table.filter(room.alive_players, function(p)
      return not p.surrendered
    end)
    if #alive > 1 then return "" end
    return alive[1].role
  end,
}
-- extension:addGameMode(m_1v1_mode)
Fk:loadTranslationTable{
  ["m_1v1_mode"] = "1v1",
  ["1v1 Lord choose"] = "先手选择了：",
  ["1v1 Rebel choose"] = "后手选择了：",
  ["1v1 choose general"] = "请选择第一名出战的武将",
  ["1v1 score"] = "已阵亡武将数 先手 ",
  ["_1v1 score"] = " 后手",
  ["1v1: left last one"] = "只剩最后一名出场武将",

  [":m_1v1_mode"] = desc_1v1,
}

return m_1v1_mode
