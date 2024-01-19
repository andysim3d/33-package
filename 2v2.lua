local desc_2v2 = [[
  # 2v2简介

  游戏由两名忠臣和两名反贼进行，胜利目标为击杀所有敌人。

  座位排列可能是忠-反-反-忠或者忠-反-忠-反，以及对应的反贼在一号位的情况。

  一人死亡后，其队友会摸一张牌。

  第一回合角色摸牌阶段少摸一张牌。四号位多摸一张初始手牌。

  队友手牌可见。
]]

local m_2v2_getLogic = function()
  local m_2v2_logic = GameLogic:subclass("m_2v2_logic") ---@class GameLogic

  function m_2v2_logic:assignRoles()
    local room = self.room
    local n = #room.players
    local roles = table.random {
      { "loyalist", "rebel", "rebel", "loyalist" },
      { "rebel", "loyalist", "loyalist", "rebel"},
    }

    for i = 1, n do
      local p = room.players[i]
      p.role = roles[i]
      p.role_shown = true
      room:broadcastProperty(p, "role")
    end

    --[[
    room.players[1]:addBuddy(room.players[4])
    room.players[4]:addBuddy(room.players[1])
    room.players[2]:addBuddy(room.players[3])
    room.players[3]:addBuddy(room.players[2])
    --]]
    --
    self.start_role = roles[1]
    -- for adjustSeats
    room.players[1].role = "lord"
  end

  function m_2v2_logic:chooseGenerals()
    local room = self.room
    local generalNum = math.min(room.settings.generalNum, 9)

    local lord = room:getLord()
    room.current = lord
    lord.role = self.start_role

    local nonlord = room.players
    local generals = table.map(Fk:getGeneralsRandomly(#nonlord * generalNum), Util.NameMapper)
    table.shuffle(generals)
    local t1 = table.slice(generals, 1, generalNum + 1)
    local t2 = table.slice(generals, generalNum + 1, generalNum * 2 + 1)
    local t3 = table.slice(generals, generalNum * 2 + 1, generalNum * 3 + 1)
    local t4 = table.slice(generals, generalNum * 3 + 1, generalNum * 4 + 1)
    room:askForMiniGame(nonlord, "AskForGeneral", "2v2_sel", {
      [nonlord[1].id] = {
        friend_id = nonlord[4].id,
        me = t1, friend = t4,
      },
      [nonlord[2].id] = {
        friend_id = nonlord[3].id,
        me = t2, friend = t3,
      },
      [nonlord[3].id] = {
        friend_id = nonlord[2].id,
        me = t3, friend = t2,
      },
      [nonlord[4].id] = {
        friend_id = nonlord[1].id,
        me = t4, friend = t1,
      },
    })

    for _, p in ipairs(nonlord) do
      local general = json.decode(p.client_reply)
      room:setPlayerGeneral(p, general, true, true)
    end
    --[[
    for _, p in ipairs(nonlord) do
      local arg = {}
      for i = 1, generalNum do
        table.insert(arg, table.remove(generals, 1).name)
      end
      p.request_data = json.encode({ arg, 1 })
      p.default_reply = arg[1]
    end

    room:doBroadcastRequest("AskForGeneral", nonlord)
    for _, p in ipairs(nonlord) do
      if p.general == "" and p.reply_ready then
        local general = json.decode(p.client_reply)[1]
        room:setPlayerGeneral(p, general, true, true)
      else
        room:setPlayerGeneral(p, p.default_reply, true, true)
      end
      p.default_reply = ""
    end
    --]]

    room:askForChooseKingdom(nonlord)
    room:setTag("SkipNormalDeathProcess", true)
  end

  return m_2v2_logic
end
local m_2v2_rule = fk.CreateTriggerSkill{
  name = "#m_2v2_rule",
  priority = 0.001,
  refresh_events = {fk.DrawInitialCards, fk.DrawNCards, fk.GameOverJudge, fk.Deathed},
  can_refresh = function(self, event, target, player, data)
    return target == player
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    if event == fk.DrawNCards then
      if player.seat == 1 and player:getMark(self.name) == 0 then
        room:addPlayerMark(player, self.name, 1)
        data.n = data.n - 1
      end
    elseif event == fk.DrawInitialCards then
      if player.seat == 4 then
        data.num = data.num + 1
      end
    elseif event == fk.GameOverJudge then
      local winner = Fk.game_modes[room.settings.gameMode]:getWinner(player)
      if winner ~= "" then
        room:gameOver(winner)
        return true
      end
    else
      for _, p in ipairs(room.alive_players) do
        if p.role == player.role then
          p:drawCards(1)
        end
      end
    end
  end,
}
Fk:addSkill(m_2v2_rule)
local m_2v2_mode = fk.CreateGameMode{
  name = "m_2v2_mode",
  minPlayer = 4,
  maxPlayer = 4,
  rule = m_2v2_rule,
  logic = m_2v2_getLogic,
  surrender_func = function(self, playedTime)
    local surrenderJudge = { { text = "time limitation: 2 min", passed = playedTime >= 120 },
    { text = "2v2: left you alive", passed = table.find(Fk:currentRoom().players, function(p)
      return p.role == Self.role and p.dead and p.rest == 0
    end) and true } }
    return surrenderJudge
  end,
  winner_getter = function(self, victim)
    if victim.rest > 0 then
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
  ["m_2v2_mode"] = "2v2",
  [":m_2v2_mode"] = desc_2v2,
  ["time limitation: 2 min"] = "游戏时长达到2分钟",
  ["2v2: left you alive"] = "你所处队伍仅剩你存活",
}

Fk:addMiniGame{
  name = "2v2_sel",
  qml_path = "packages/gamemode/2v2",
  default_choice = function(player, data)
    return data.me[1]
  end,
  update_func = function(player, data)
    local room = player.room
    local d = player.mini_game_data.data
    local friend = room:getPlayerById(d.friend_id)
    friend:doNotify("UpdateMiniGame", json.encode(data))
  end,
}

return m_2v2_mode
