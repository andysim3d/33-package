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

-- 从武将池中移除指定武将。若无法移除，则移去第一个武将
local function removeGeneral(generals, g)
  local gt = Fk.generals[g].trueName
  for i, v in ipairs(generals) do
    if Fk.generals[v].trueName == gt then
      return table.remove(generals, i)
    end
  end
  return table.remove(generals, 1)
end

local m_1v1_getLogic = function()
  local m_1v1_logic = GameLogic:subclass("m_1v1_logic")

  function m_1v1_logic:prepareDrawPile()
    local room = self.room ---@type Room
    local allCardIds = Fk:getAllCardIds()

    for i = #allCardIds, 1, -1 do
      local id = allCardIds[i]
      local card = Fk:getCardById(id)
      if card.is_derived then
        table.removeOne(allCardIds, id)
        table.insert(room.void, id)
        room:setCardArea(id, Card.Void, nil)
      elseif card.name == "dismantlement" then
        table.insert(room.void, id)
        room:setCardArea(id, Card.Void, nil)
        local newCard = room:printCard("v11__dismantlement", card.suit, card.number)
        allCardIds[i] = newCard.id
      end
    end

    table.shuffle(allCardIds)
    room.draw_pile = allCardIds
    for _, id in ipairs(room.draw_pile) do
      room:setCardArea(id, Card.DrawPile, nil)
    end
  end

  function m_1v1_logic:chooseGenerals()
    local room = self.room ---@type Room
    local generalNum = 12

    local lord = room.players[1]
    room.current = lord
    local nonlord = room.players[2]

    nonlord.role_shown = true
    room:broadcastProperty(nonlord, "role")

    local lord_generals = {}
    local nonlord_generals = {}
    local all_generals = room:getNGenerals(12)
    local first_selected, second_selected = {}, {}
    -- 用于储存双方已选择武将的序号（从0开始），不用字符串储存是考虑替换武将的情况

    local updataGeneralPile = function(p)
      if p == lord then
        room:setBanner("@&firstGenerals", lord_generals)
      else
        room:setBanner("@&secondGenerals", nonlord_generals)
      end
    end

    local function chooseGeneral(p, n)
      local prompt = "#1v1_mode-choose:::"..(p == lord and "firstPlayer" or "secondPlayer")..":"..n
      local my_selected = (p == lord) and first_selected or second_selected
      local ur_selected = (p == lord) and second_selected or first_selected
      local my_genrals = (p == lord) and lord_generals or nonlord_generals
      local result = room:askForCustomDialog(p, "m_1v1_mode", "packages/gamemode/qml/1v1.qml",
      { all_generals, n, my_selected, ur_selected, prompt } )
      local selected = {}
      if result ~= "" then
        result = json.decode(result)
        for i, id in ipairs(result.ids) do
          local g = result.generals[i]
          -- 更新武将替换
          all_generals[id+1] = g
          table.insert(my_selected, id)
          table.insert(my_genrals, g)
          table.insert(selected, g)
        end
      else
        local selected_list = table.connect(my_selected, ur_selected)
        for i, g in ipairs(all_generals) do
          if not table.contains(selected_list, i-1) then
            table.insert(my_selected, i-1)
            table.insert(my_genrals, g)
            table.insert(selected, g)
            if #selected == n then break end
          end
        end
      end
      room:sendLog{
        type = "#1v1ChooseGeneralsLog",
        arg = p == lord and "firstPlayer" or "secondPlayer",
        arg2 = selected[1],
        arg3 = selected[2] or "",
        toast = true,
      }
      updataGeneralPile(p)
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
      local chosen = ""
      if p.general == "" and p.reply_ready then
        chosen = json.decode(p.client_reply)[1]
      else
        chosen = p.default_reply
      end
      room:setPlayerGeneral(p, chosen, true, true)
      removeGeneral(tab, chosen)
      p.default_reply = ""
    end

    room:broadcastProperty(lord, "role")
    room:broadcastProperty(nonlord, "role")
    room:broadcastProperty(lord, "general")
    room:broadcastProperty(nonlord, "general")
    room:broadcastProperty(lord, "kingdom")
    room:broadcastProperty(nonlord, "kingdom")
    room:setBanner("@firstFallen", "0 / 3")
    room:setBanner("@secondFallen", "0 / 3")
    updataGeneralPile(lord)
    updataGeneralPile(nonlord)
    room:askForChooseKingdom(room.players)
  end

  return m_1v1_logic
end

local function drawInit(room, player, n)
  -- TODO: need a new function to call the UI
  local cardIds = room:getNCards(n)
  player:addCards(Player.Hand, cardIds)
  for _, id in ipairs(cardIds) do
    Fk:filterCard(id, player)
  end
  local move_to_notify = {}   ---@type CardsMoveStruct
  move_to_notify.toArea = Card.PlayerHand
  move_to_notify.to = player.id
  move_to_notify.moveInfo = {}
  move_to_notify.moveReason = fk.ReasonDraw
  for _, id in ipairs(cardIds) do
    table.insert(move_to_notify.moveInfo,
    { cardId = id, fromArea = Card.DrawPile })
  end
  room:notifyMoveCards(nil, {move_to_notify})

  for _, id in ipairs(cardIds) do
    room:setCardArea(id, Card.PlayerHand, player.id)
  end
end

local m_1v1_rule = fk.CreateTriggerSkill{
  name = "#m_1v1_rule",
  priority = 0.001,
  refresh_events = {fk.DrawInitialCards, fk.DrawNCards, fk.GameOverJudge, fk.BuryVictim, fk.GameStart},
  can_refresh = function(self, event, target, player, data)
    return target == player
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    if event == fk.DrawInitialCards then
      data.num = math.min(player.maxHp, 5)
    elseif event == fk.DrawNCards then
      if player.role == "lord" and player.tag[self.name] == nil then
        player.tag[self.name] = 1
        data.n = data.n - 1
      end
    elseif event == fk.GameOverJudge then
      room:setTag("SkipGameRule", true)
      local body = room:getPlayerById(data.who)
      if body.rest > 0 then return end
      local num, num2 = tonumber(room:getBanner("@firstFallen")[1]), tonumber(room:getBanner("@secondFallen")[1])
      if body.role == "lord" then num = num + 1 else num2 = num2 + 1 end
      room:setBanner("@firstFallen", tostring(num) .. " / 3")
      room:setBanner("@secondFallen", tostring(num2) .. " / 3")
      room:sendLog{
        type = "#1v1Score",
        arg = num,
        arg2 = num2,
        toast = true,
      }
      if num < 3 and num2 < 3 then return end
      room:gameOver(body.next.role)
      return true
    elseif event == fk.GameStart then
      room.logic:trigger("fk.Debut", player, player.general, false)
      room.logic:trigger("fk.Debut", player.next, player.general, false)
    elseif event == fk.BuryVictim then
      room:setTag("SkipGameRule", true)
      local body = room:getPlayerById(data.who)
      local generals = room:getBanner(body.role == "lord" and "@&firstGenerals" or "@&secondGenerals")
      body:bury()
      if body.rest > 0 then return end
      local exiled_name = body.role == "lord" and "@&firstExiled" or "@&secondExiled"
      local exiled_generals = room:getBanner(exiled_name) or  {}
      table.insert(exiled_generals, body.general)
      room:setBanner(exiled_name, exiled_generals)
      if #generals == 0 then
        room:gameOver(body.next.role)
        return
      end
      local current = room.logic:getCurrentEvent()
      local last_event = nil
      if room.current.dead then
        last_event = current:findParent(GameEvent.Turn, true)
      end
      if last_event == nil then
        last_event = current
        if last_event.parent then
          repeat
            if table.contains({GameEvent.Round, GameEvent.Turn, GameEvent.Phase}, last_event.parent.event) then break end
            last_event = last_event.parent
          until (not last_event.parent)
        end
      end
      last_event:addCleaner(function()
        local g = room:askForGeneral(body, generals, 1)
        if type(g) == "table" then g = g[1] end
        removeGeneral(generals, g)
        room:setBanner(body.role == "lord" and "@&firstGenerals" or "@&secondGenerals", generals)

        local to_rm = table.filter(body.player_skills, function(s)
          return not s.attached_equip and s.name[#s.name] ~= "&" -- 不是装备技和按钮的全图图了
        end)
        room:handleAddLoseSkills(body, table.concat(
          table.map(to_rm, function(s) return "-" .. s.name end), "|"), nil, true)
        room:resumePlayerArea(target, {Player.WeaponSlot, Player.ArmorSlot, Player.OffensiveRideSlot, Player.DefensiveRideSlot, Player.TreasureSlot, Player.JudgeSlot}) -- 全部恢复

        room:changeHero(body, g, true, false, true)

        -- trigger leave

        room:setPlayerProperty(body, "shield", Fk.generals[g].shield)
        room:revivePlayer(body, false)
        drawInit(room, body, math.min(body.maxHp, 5))
        room.logic:trigger("fk.Debut", body, player.general, false)
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
    return { { text = "time limitation: 2 min", passed = playedTime >= 120 } }
  end,
}
-- extension:addGameMode(m_1v1_mode)
Fk:loadTranslationTable{
  ["m_1v1_mode"] = "1v1",
  ["#1v1ChooseGeneralsLog"] = "%arg 选择了 %arg2 %arg3",
  ["firstPlayer"] = "先手",
  ["secondPlayer"] = "后手",
  ["#1v1_mode-choose"] = "你是[%arg]，请选择 %arg2 张武将牌作为备选",
  ["1v1 choose general"] = "请选择第一名出战的武将",
  ["#1v1Score"] = "已阵亡武将数 先手 %arg : %arg2 后手",
  ["@firstFallen"] = "先手阵亡数",
  ["@secondFallen"] = "后手阵亡数",
  ["@&firstGenerals"] = "先手备选区",
  ["@&secondGenerals"] = "后手备选区",
  ["@&firstExiled"] = "先手流放区",
  ["@&secondExiled"] = "后手流放区",

  [":m_1v1_mode"] = desc_1v1,
}

return m_1v1_mode
