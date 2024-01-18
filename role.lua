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
      local room = self.room
      local generalNum = room.settings.generalNum
      local lord = room:getLord()
      if not lord then
        local temp = room.players[1]
        temp.role = "lord"
        lord =  temp
      end
      room.current = lord
      
      local lord_generals = room:getNGenerals(generalNum)
      local lord_general_num = 3
      local all_lords = table.filter(room.general_pile, function (name)
        return table.find(Fk.generals[name]:getSkillNameList(true), function(s)
          return Fk.skills[s].lordSkill
        end)
      end)
      if #all_lords > 0 then
        for _, g in ipairs(table.random(all_lords, lord_general_num)) do
          table.removeOne(room.general_pile, g)
          table.insert(lord_generals, g)
        end
      end

      local lord_general = room:askForGeneral(lord, lord_generals, 1)
      table.removeOne(lord_generals, lord_general)
      room:returnToGeneralPile(lord_generals)

      room:setPlayerGeneral(lord, lord_general, true)
      room:askForChooseKingdom({lord})
      room:broadcastProperty(lord, "general")
      room:broadcastProperty(lord, "kingdom")

      local lord_skills = Fk.generals[lord.general]:getSkillNameList(true)
      room:handleAddLoseSkills(lord, table.concat(lord_skills, "|"), nil, false, true)
  
  
      local nonlord = room:getOtherPlayers(lord, true)
      local generals = room:getNGenerals(#nonlord * generalNum)
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
        table.insertIfNeed(selected, general)
        room:setPlayerGeneral(p, general, true, true)
        p.default_reply = ""
      end
      generals = table.filter(generals, function(g) return not table.contains(selected, g) end)
      room:returnToGeneralPile(generals)
  
      room:askForChooseKingdom(nonlord)

      room:handleAddLoseSkills(lord, "-"..table.concat(lord_skills, "|-"), nil, false ,true)
    end

    return l
  end,
  surrender_func = Fk.game_modes["aaa_role_mode"].surrenderFunc
}

Fk:loadTranslationTable{
  ["aab_role_mode"] = "单将军八",
  [":aab_role_mode"] = "就是禁用了副将且人数必须为8的身份模式。这个模式创立的目的是便于统计数据。",
}

return role_mode
