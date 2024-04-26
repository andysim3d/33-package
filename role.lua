
-- 准备多个角色的武将/性别/势力（会判断隐匿）
---@param players table<ServerPlayer> @ 需要准备的角色表
---@param generals table<string> @ 角色对应的武将表
---@param reveal boolean|nil @ 是否解除隐匿
local prepareHiddenGeneral = function (players, generals, reveal)
  local room = players[1].room
  for i, player in ipairs(players) do
    local general = generals[i]
    player.general = general
    if not reveal and table.find(Fk.generals[general]:getSkillNameList(player.role == "lord"), function (s)
      return Fk.skills[s].isHiddenSkill
    end) then
      room:setPlayerMark(player, "__hidden_general", general)
      player.general = "hiddenone"
    end
    player.gender = Fk.generals[player.general].gender
    player.kingdom = Fk.generals[player.general].kingdom
  end
  room:askForChooseKingdom(players)
  for _, player in ipairs(players) do
    room:broadcastProperty(player, "gender")
    room:broadcastProperty(player, "general")
    room:broadcastProperty(player, "kingdom")
  end
end


local role_mode = fk.CreateGameMode{
  name = "aab_role_mode", -- just to let it at the top of list
  minPlayer = 8,
  maxPlayer = 8,
  logic = function()
    local l = GameLogic:subclass("aab_role_mode_logic")
    function l:run()
      self.room.settings.enableDeputy = false
      GameLogic.run(self)
    end

    function l:chooseGenerals()
      local room = self.room---@type Room
      local generalNum = room.settings.generalNum
      local lord = room:getLord()
      if not lord then
        local temp = room.players[1]
        temp.role = "lord"
        lord =  temp
      end
      room.current = lord

      local lord_general_num = 3
      local lord_generals = table.connect(room:findGenerals(function(g)
        return table.find(Fk.generals[g].skills, function(s) return s.lordSkill end)
      end, lord_general_num), room:getNGenerals(generalNum))
      if #room.general_pile < (#room.players - 1) * generalNum then
        room:gameOver("")
      end

      local lord_general = room:askForGeneral(lord, lord_generals, 1)---@type string
      table.removeOne(lord_generals, lord_general)
      room:returnToGeneralPile(lord_generals)
      room:findGeneral(lord_general)

      prepareHiddenGeneral({lord}, {lord_general})

      local lord_skills = Fk.generals[lord.general]:getSkillNameList(true)
      for _, sname in ipairs(lord_skills) do
        local skill = Fk.skills[sname]
        if #skill.attachedKingdom == 0 or table.contains(skill.attachedKingdom, lord.kingdom) then
          room:doBroadcastNotify("AddSkill", json.encode{ lord.id, sname })
        end
      end
  
      local nonlord = room:getOtherPlayers(lord, true)
      local generals = room:getNGenerals(#nonlord * generalNum)
      if #generals < #nonlord * generalNum then
        room:gameOver("")
      end
      table.shuffle(generals)
      for i, p in ipairs(nonlord) do
        local arg = table.slice(generals, (i - 1) * generalNum + 1, i * generalNum + 1)
        p.request_data = json.encode{ arg, 1 }
        p.default_reply = table.random(arg, 1)
      end
  
      room:notifyMoveFocus(nonlord, "AskForGeneral")
      room:doBroadcastRequest("AskForGeneral", nonlord)
  
      local selected = {}
      for _, p in ipairs(nonlord) do
        local general
        if p.general == "" and p.reply_ready then
          local general_ret = json.decode(p.client_reply)
          general = general_ret[1]
        else
          general = p.default_reply[1]
        end
        p.default_reply = ""
        table.insert(selected, general)
        room:findGeneral(general)
      end
      generals = table.filter(generals, function(g) return not table.contains(selected, g) end)
      room:returnToGeneralPile(generals)
      prepareHiddenGeneral(nonlord, selected)

    end

    function l:broadcastGeneral()
      local room = self.room
      local players = room.players
      for _, p in ipairs(players) do
        assert(p.general ~= "")
        local general = Fk.generals[p.general]
        p.maxHp = p:getGeneralMaxHp()
        p.hp = general.hp
        p.shield = math.min(general.shield, 5)
        -- TODO: setup AI here
        if p.role == "lord" and p.general ~= "hiddenone" then
          p.maxHp = p.maxHp + 1
          p.hp = p.hp + 1
        end
        room:broadcastProperty(p, "maxHp")
        room:broadcastProperty(p, "hp")
        room:broadcastProperty(p, "shield")
      end
    end

    return l
  end,
  surrender_func = Fk.game_modes["aaa_role_mode"].surrenderFunc
}

Fk:loadTranslationTable{
  ["aab_role_mode"] = "单将军八",
  [":aab_role_mode"] = "就是禁用了副将且人数必须为8的身份模式。这个模式创立的目的是便于统计数据。",
  ["#aab_role_rule"] = "单将军八规则",
}

return role_mode
