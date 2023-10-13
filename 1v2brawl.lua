local desc_brawl = [[
  # 1v2大乱斗模式简介

  ___

  本模式为**斗地主模式的变种模式**，玩家需要自己搭配技能以取得游戏的胜利。游戏由三人进行，一人扮演地主（主公），其他两人扮演农民（反贼）。

  （暂无）游戏开始后，**每位玩家会随机到10个待选技能**，玩家需要根据这些技能，依次叫价1遍，**价高者为地主，额外抽取5个技能**。

  （暂行）随机一名玩家成为**地主**，随机抽取15个技能；2名农民各随机抽取10个技能。

  **地主从总计15个技能中挑选3个作为本局的技能；农民需要从10个技能中挑选2个作为本局的技能**。

  地主5点体力上限，农民4点体力上限。
  
  地主拥有以下额外技能：

  - **飞扬**：判定阶段开始时，你可以弃置两张手牌并弃置自己判定区内的一张牌。

  - **跋扈**：锁定技，准备阶段，你摸一张牌；出牌阶段，你可以多使用一张杀。

  当农民被击杀后，另一名农民可以选择：摸两张牌，或者回复一点体力。

  *击杀农民的人没有摸三张牌的奖励。*

  胜利规则与身份局一致。

  禁包、禁将之后其技能不会在技能池中出现。
]]

local ban_skills = {
  "fenyong",
  "duorui", "quanfeng", "zhongliu", "yongdi", "chuanwu", "tuogu", "zeyue",
}

local brawl_getLogic = function()
  local brawl_logic = GameLogic:subclass("brawl_logic")

  function brawl_logic:initialize(room)
    GameLogic.initialize(self, room)
    self.role_table = {nil, nil, {"lord", "rebel", "rebel"}}
  end

  function brawl_logic:chooseGenerals()
    local room = self.room
    local generalNum = room.settings.generalNum
    for _, p in ipairs(room.players) do
      p.role_shown = true
      room:broadcastProperty(p, "role")
    end

    local lord = room:getLord()
    room.current = lord
    local players = room.players
    local skill_pool = {}
    for _, general in pairs(Fk:getAllGenerals()) do
      for _, skill in ipairs(general.skills) do
        if not skill.lordSkill and #skill.attachedKingdom == 0 and not table.contains(ban_skills, skill.name) then
          table.insert(skill_pool, skill.name)
        end
      end
    end
    skill_pool = table.random(skill_pool, 35)

    for k, p in ipairs(players) do
      local avatar = p._splayer:getAvatar()
      if avatar == "anjiang" then avatar = table.random{ "blank_shibing", "blank_nvshibing" } end
      local avatar_general = Fk.generals[avatar] or Fk.generals["mouxusheng"]
      room:setPlayerGeneral(p, avatar_general.name, true)
      room:broadcastProperty(p, "general")
      room:setPlayerProperty(p, "shield", 0)
      room:setPlayerProperty(p, "maxHp", p.role == "lord" and 5 or 4)
      room:setPlayerProperty(p, "hp", p.role == "lord" and 5 or 4)

      local skills = table.slice(skill_pool, 10 * k - 9 , 10 * k + 1)
      if p.role == "lord" then table.insertTable(skills, table.slice(skill_pool, 31 , 36)) end
      local num = p.role == "lord" and 3 or 2
      p.request_data = json.encode({
        path = "packages/utility/qml/ChooseSkillBox.qml",
        data = {
          skills, num, num, "#brawl-choose:::" .. tostring(num)
        },
      })
      p.default_reply = table.random(skills, num)
    end

    room:doBroadcastRequest("CustomDialog", players)

    for _, p in ipairs(players) do
      local choice = p.reply_ready and json.decode(p.client_reply) or p.default_reply
      room:setPlayerMark(p, "_brawl_skills", choice)
      choice = table.map(choice, function(s) return Fk:translate(s) end)
      room:setPlayerMark(p, "@brawl_skills", "<font color='burlywood'>" .. table.concat(choice, " ") .. "</font>")
      p.default_reply = ""
    end

    --[[ 鸽！直接用头像，我写在最前面
    for _, p in ipairs(players) do
      local genders = {"male", "female"}
      local data = json.encode({ genders, genders, "AskForGender", "#ChooseGender" })
      p.request_data = data
      p.default_reply = table.random(genders)
    end

    room:notifyMoveFocus(players, "AskForGender")
    room:doBroadcastRequest("AskForChoice", players)

    for _, p in ipairs(players) do
      local genderChosen
      if p.reply_ready then
        genderChosen = p.client_reply
      else
        genderChosen = p.default_reply
      end
      room:setPlayerGeneral(p, genderChosen == "male" and "blank_shibing" or "blank_nvshibing", true, true)
      p.default_reply = ""
    end
    --]]
  end

  function brawl_logic:broadcastGeneral()
    return
    --[[
    local room = self.room
    local players = room.players

    for _, p in ipairs(players) do
      assert(p.general ~= "")
      -- room:broadcastProperty(p, "general")
      -- room:setPlayerProperty(p, "kingdom", "unknown")
      room:setPlayerProperty(p, "shield", 0)
      room:setPlayerProperty(p, "maxHp", p.role == "lord" and 5 or 4)
      room:setPlayerProperty(p, "hp", p.role == "lord" and 5 or 4)
    end
    --]]
  end

  function brawl_logic:attachSkillToPlayers()
    local room = self.room
    for _, p in ipairs(room.alive_players) do
      local skills = table.concat(p:getMark("_brawl_skills"), "|")
      if p.role == "lord" then
        skills = skills .."|m_feiyang|m_bahu"
      end
      room:handleAddLoseSkills(p, skills, nil, false)
    end
  end

  return brawl_logic
end

local brawl_rule = fk.CreateTriggerSkill{
  name = "#brawl_rule",
  priority = 0.001,
  refresh_events = {fk.GameStart, fk.Deathed},
  can_refresh = function(self, event, target, player, data)
    return event == fk.GameStart and player.role == "lord" or target == player
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    if event == fk.GameStart then
      room:setTag("SkipNormalDeathProcess", true)
    else
      for _, p in ipairs(room.alive_players) do
        if p.role == "rebel" then
          local choices = {"m_1v2_draw2", "Cancel"}
          if p:isWounded() then
            table.insert(choices, 2, "m_1v2_heal")
          end
          local choice = room:askForChoice(p, choices, self.name)
          if choice == "m_1v2_draw2" then p:drawCards(2, self.name)
          else room:recover{ who = p, num = 1, skillName = self.name } end
        end
      end
    end
  end,
}
Fk:addSkill(brawl_rule)
local brawl_mode = fk.CreateGameMode{
  name = "brawl_mode",
  minPlayer = 3,
  maxPlayer = 3,
  rule = brawl_rule,
  logic = brawl_getLogic,
  surrender_func = function(self, playedTime)
    local surrenderJudge = { { text = "time limitation: 2 min", passed = playedTime >= 120 } }
    if Self.role ~= "lord" then
      table.insert(surrenderJudge, { text = "1v2: left you alive", passed = #Fk:currentRoom().alive_players == 2 })
    end

    return surrenderJudge
  end,
}

Fk:loadTranslationTable{
  ["brawl_mode"] = "1v2大乱斗",
  ["#brawl_rule"] = "挑选遗产",
  ["#brawl-choose"] = "请选择%arg个技能出战",
  ["@brawl_skills"] = "",
  --[[
  ["AskForGender"] = "选择性别",
  ["#ChooseGender"] = "请选择你的性别",
  ["male"] = "男性",
  ["female"] = "女性",
  --]]

  [":brawl_mode"] = desc_brawl,
}

return brawl_mode