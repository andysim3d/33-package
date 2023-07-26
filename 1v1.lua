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
    askForChooseKingdom(room, room.players)
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
      data.n = math.min(player.maxHp, 5)
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
      if #generals > 3 then return end
      room:gameOver(body.next.role)
      return true
    else
      room:setTag("SkipGameRule", true)
      local body = room:getPlayerById(data.who)
      local generals = body:getMark("_1v1_generals")
      body:bury()

      local g = room:askForGeneral(body, generals, 1)
      if type(g) == "table" then g = g[1] end
      table.removeOne(generals, g)
      room:changeHero(body, g, true)

      -- trigger leave

      body.dead = false
      room:broadcastProperty(body, "dead")
      body.kingdom = Fk.generals[g].kingdom
      room:broadcastProperty(body, "kingdom")
      body:drawCards(math.min(body.maxHp, 5), self.name)
      room:setPlayerMark(body, "_1v1_generals", generals)

      if room.current == body then
        room.logic:breakTurn()
      end
    end
  end,
}
local m_1v1_mode = fk.CreateGameMode{
  name = "m_1v1_mode",
  minPlayer = 2,
  maxPlayer = 2,
  rule = m_1v1_rule,
  logic = m_1v1_getLogic,
}
-- extension:addGameMode(m_1v1_mode)
Fk:loadTranslationTable{
  ["m_1v1_mode"] = "1v1",
  ["1v1 Lord choose"] = "主公选择了：",
  ["1v1 Rebel choose"] = "反贼选择了：",
  ["1v1 choose general"] = "请选择出战的武将",
}

return m_1v1_mode
