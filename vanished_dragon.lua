local desc_vanished_dragon = [[
  # 忠胆英杰（明忠模式）简介

  ---

  ## 身份说明

  游戏由八名玩家进行，身份分配和一般身份局一样，为1主2忠4反1内。

  其中一名忠臣改为「**明忠**」。抽取身份后，**主公不需要亮明身份，改为明忠亮明身份**。

  胜负判定：和一般身份局一致。

  ---

  ## 游戏流程

  1. **明忠如一般身份局的主公一样，先选将并展示**，其他人（包括主公）再选将。明忠的固定额外选将为 崔琰 和 皇甫嵩(若在房间禁表则不会出现)；

  2. 明忠根据体力上限(不计明忠血量上限加成)和性别获得相应的“**忠臣技**”，即：

  - 体力上限不大于3的男性武将获得〖**洞察**〗（游戏开始时，随机一名反贼的身份对你可见。准备阶段开始时，你可以弃置场上的一张牌）；

  - 体力上限不小于4的男性武将和所有女性武将获得〖**舍身**〗（锁定技，主公处于濒死状态即将死亡时，你令其体力上限+1，回复体力至X点（X为你的体力值），获得你所有牌，然后你死亡）；

  3. 如一般身份局的主公一样，**明忠体力上限和体力值+1**，且为一号位；

  4. **明忠死亡后，主公亮明身份**，获得武将牌上的主公技，但不增加体力上限。

  ---

  ## 击杀奖惩

  1. 任何角色击杀反贼，摸三张牌；

  2. 除主公外的角色击杀明忠，摸三张牌；

  3. 暗主击杀明忠，弃置所有牌；

  4. 暗主击杀暗忠，不弃牌；

  5. 明忠击杀暗忠，弃置所有牌。

  ---

  ## 专属游戏牌

  【**声东击西**】（替换【顺手牵羊】）普通锦囊：出牌阶段，对距离为1的一名角色使用。你交给目标角色一张手牌，然后其将两张牌交给一名由你选择的除其以外的角色。

  【**草木皆兵**】（替换【兵粮寸断】），延时锦囊：出牌阶段，对一名其他角色使用。将【草木皆兵】置于目标角色判定区里。若判定结果不为♣：摸牌阶段，少摸一张牌；摸牌阶段结束时，与其距离为1的角色各摸一张牌。

  【**增兵减灶**】（替换【无中生有】和【五谷丰登】），普通锦囊：出牌阶段，对一名角色使用。目标角色摸三张牌，然后选择一项：1. 弃置一张非基本牌；2. 弃置两张牌。

  【**弃甲曳兵**】（替换【借刀杀人】），普通锦囊：出牌阶段，对一名装备区里有牌的其他角色使用。目标角色选择一项：1. 弃置手牌区和装备区里所有的武器和进攻坐骑；2. 弃置手牌区和装备区里所有的防具和防御坐骑。

  【**金蝉脱壳**】（替换【无懈可击】），普通锦囊：当你成为其他角色使用牌的目标时，若你的手牌里只有【金蝉脱壳】，使目标锦囊牌或基本牌对你无效，你摸两张牌。当你因弃置而失去【金蝉脱壳】时，你摸一张牌。

  【**浮雷**】（替换【闪电】），延时锦囊：出牌阶段，对你使用。将【浮雷】放置于你的判定区里，若判定结果为♠，则目标角色受到X点雷电伤害（X为此牌判定结果为♠的次数）。判定完成后，将此牌移动到下家的判定区里。

  【**烂银甲**】（替换【八卦阵】），防具：你可以将一张手牌当【闪】使用或打出。【烂银甲】不会被无效或无视。当你受到【杀】造成的伤害时，你弃置装备区里的【烂银甲】。

  【**七宝刀**】（替换【青釭剑】），武器，攻击范围２：锁定技，你使用【杀】无视目标防具，若目标角色未损失体力值，此【杀】伤害+1。

  【**衠钢槊**】（替换【青龙偃月刀】），武器，攻击范围３：当你使用【杀】指定一名角色为目标后，你可令其弃置你的一张手牌，然后你弃置其一张手牌。
]]

-- 准备多个角色的武将/性别/势力（会判断隐匿）
---@param players table<ServerPlayer> @ 需要准备的角色表
---@param generals table<string> @ 角色表对应的主将武将表
---@param deputys table<string> @ 角色表对应的副将武将表
local prepareHiddenGeneral = function (players, generals, deputys)
  local room = players[1].room
  for i, player in ipairs(players) do
    local general = generals[i]
    local deputy = deputys[i]
    player.general = general
    local skills = Fk.generals[general]:getSkillNameList()
    if Fk.generals[deputy] then
      player.deputyGeneral = deputy
      table.insertTable(skills, Fk.generals[deputy]:getSkillNameList())
    end
    if table.find(skills, function (s) return Fk.skills[s].isHiddenSkill end) then
      room:setPlayerMark(player, "__hidden_general", general)
      if Fk.generals[deputy] then
        room:setPlayerMark(player, "__hidden_deputy", deputy)
        player.deputyGeneral = ""
      end
      player.general = "hiddenone"
    end
    player.gender = Fk.generals[player.general].gender
    player.kingdom = Fk.generals[player.general].kingdom
  end
  room:askForChooseKingdom(players)
  for _, player in ipairs(players) do
    room:broadcastProperty(player, "gender")
    room:broadcastProperty(player, "deputyGeneral")
    room:broadcastProperty(player, "general")
    room:broadcastProperty(player, "kingdom")
  end
end

local vanished_dragon_getLogic = function()
  local vanished_dragon_logic = GameLogic:subclass("vanished_dragon_logic")

  function vanished_dragon_logic:initialize(room)
    GameLogic.initialize(self, room)
    self.role_table = {nil, nil, nil, nil, nil, 
    {"hidden", "loyalist", "rebel", "rebel", "rebel", "renegade"},
    {"hidden", "loyalist", "loyalist", "rebel", "rebel", "rebel", "renegade"}, 
    {"hidden", "loyalist", "loyalist", "rebel", "rebel", "rebel", "rebel", "renegade"} }
  end

  function vanished_dragon_logic:assignRoles()
    local room = self.room
    local players = room.players
    local n = #players
    local roles = self.role_table[n]
    table.shuffle(roles)

    room:setTag("ShownLoyalist", nil)
    for i = 1, n do
      local p = players[i]
      p.role = roles[i]
      if p.role == "loyalist" and not room:getTag("ShownLoyalist") then
        room:setPlayerProperty(p, "role_shown", true)
        room:broadcastProperty(p, "role")
        room:setTag("ShownLoyalist", p.id)
        p.role = "lord"
      else
        room:notifyProperty(p, p, "role")
      end
    end
  end

  function vanished_dragon_logic:prepareDrawPile()
    local room = self.room
    local seed = math.random(2 << 32 - 1)
    local allCardIds = Fk:getAllCardIds()
    local blacklist = {"snatch", "supply_shortage", "ex_nihilo", "amazing_grace", "collateral", "nullification", "lightning", "eight_diagram", "qinggang_sword", "blade"}
    local whitelist = {"diversion", "paranoid", "reinforcement", "abandoning_armor", "crafty_escape", "floating_thunder", "glittery_armor", "seven_stars_sword", "steel_lance"}
    for i = #allCardIds, 1, -1 do
      local card = Fk:getCardById(allCardIds[i])
      local name = card.name
      if (card.is_derived and not table.contains(whitelist, name)) or table.contains(blacklist, name) then
        local id = allCardIds[i]
        table.removeOne(allCardIds, id)
        table.insert(room.void, id)
        room:setCardArea(id, Card.Void, nil)
      end
    end

    table.shuffle(allCardIds, seed)
    room.draw_pile = allCardIds
    for _, id in ipairs(room.draw_pile) do
      room:setCardArea(id, Card.DrawPile, nil)
    end

    room:doBroadcastNotify("PrepareDrawPile", seed)
  end

  function vanished_dragon_logic:chooseGenerals()
    local room = self.room

    local generals_blacklist = {
      "cuiyan", "vd__huangfusong", -- 明忠备选
      "js__caocao", "js__zhugeliang", "ol__dongzhao","std__yuanshu", "huanghao", -- 暴露暗主
    }
    local loyalist_list = {}
    for i = #room.general_pile, 1, -1 do
      local name = room.general_pile[i]
      if table.contains(generals_blacklist, name) then
        if name == "cuiyan" or name == "vd__huangfusong" then
          table.insert(loyalist_list, name)
        end
        table.remove(room.general_pile, i)
      end
    end

    local generalNum = room.settings.generalNum
    local n = room.settings.enableDeputy and 2 or 1
    local lord = room:getLord()
    room.current = lord
    lord.role = "loyalist"
    for _, p in ipairs(room.players) do
      if p.role == "hidden" then
        p.role = "lord"
        room:notifyProperty(p, p, "role")
      end
    end

    room:sendLog{type = "#VDIntro", arg = lord._splayer:getScreenName(), toast = true}

    if lord ~= nil then
      table.insertTable(loyalist_list, table.random(room.general_pile, generalNum))
      local lord_generals = room:askForGeneral(lord, loyalist_list, n)
      local lord_general, deputy
      if type(lord_generals) == "table" then
        deputy = lord_generals[2]
        lord_general = lord_generals[1]
      else
        lord_general = lord_generals
        lord_generals = {lord_general}
      end
      for _, g in ipairs(lord_generals) do
        room:findGeneral(g)
      end

      prepareHiddenGeneral({lord}, {lord_general}, {deputy})

      -- 显示技能
      local canAttachSkill = function(player, skillName)
        local skill = Fk.skills[skillName]
        if not skill then
          fk.qCritical("Skill: "..skillName.." doesn't exist!")
          return false
        end
        if #skill.attachedKingdom > 0 and not table.contains(skill.attachedKingdom, player.kingdom) then
          return false
        end
        return true
      end

      local lord_skills = {}
      local lord_gs = Fk.generals[lord_general]
      for _, s in ipairs(lord_gs:getSkillNameList()) do
        if canAttachSkill(lord, s) then
          table.insertIfNeed(lord_skills, s)
        end
      end
      local deputyGeneral = Fk.generals[lord.deputyGeneral]
      if deputyGeneral then
        for _, s in ipairs(deputyGeneral:getSkillNameList()) do
          if canAttachSkill(lord, s) then
            table.insertIfNeed(lord_skills, s)
          end
        end
      end
      local lord_maxhp = deputyGeneral and (lord_gs.maxHp + deputyGeneral.maxHp) // 2 or lord_gs.maxHp
      table.insert(lord_skills, (lord_maxhp <= 3 and lord_gs.gender == General.Male) and "vd_dongcha" or "vd_sheshen")
      for _, skill in ipairs(lord_skills) do
        room:doBroadcastNotify("AddSkill", json.encode{ lord.id, skill })
      end

    end

    local nonlord = room:getOtherPlayers(lord, true)
    local generals = table.random(room.general_pile, #nonlord * generalNum)
    for _, p in ipairs(nonlord) do
      local arg = {}
      for i = 1, generalNum do
        table.insert(arg, table.remove(generals, 1))
      end
      p.request_data = json.encode{ arg, n }
      p.default_reply = table.random(arg, n)
    end

    room:notifyMoveFocus(nonlord, "AskForGeneral")
    room:doBroadcastRequest("AskForGeneral", nonlord)

    local main_selected, deputy_selected = {}, {}
    for _, p in ipairs(nonlord) do
      local mainGeneral, deputyGeneral
      if p.general == "" and p.reply_ready then
        local _generals = json.decode(p.client_reply)
        mainGeneral = _generals[1]
        deputyGeneral = _generals[2]
      else
        mainGeneral = p.default_reply[1]
        deputyGeneral = p.default_reply[2]
      end
      table.insert(main_selected, mainGeneral)
      room:findGeneral(mainGeneral)
      if deputyGeneral and deputyGeneral ~= "" then
        table.insert(deputy_selected, deputyGeneral)
        room:findGeneral(deputyGeneral)
      end
      p.default_reply = ""
    end
    prepareHiddenGeneral(nonlord, main_selected, deputy_selected)

    room:setTag("SkipNormalDeathProcess", true)

  end

  function vanished_dragon_logic:broadcastGeneral()
    local room = self.room
    local players = room.players
    local lord = room:getTag("ShownLoyalist")

    for _, p in ipairs(players) do
      assert(p.general ~= "")
      local general = Fk.generals[p.general]
      local deputy = Fk.generals[p.deputyGeneral]
      p.maxHp = deputy and math.floor((deputy.maxHp + general.maxHp) / 2)
        or general.maxHp
      p.hp = deputy and math.floor((deputy.hp + general.hp) / 2) or general.hp
      p.shield = math.min(general.shield + (deputy and deputy.shield or 0), 5)
      -- TODO: setup AI here

      if p.id == lord and p.general ~= "hiddenone"  then
        p.maxHp = p.maxHp + 1
        p.hp = p.hp + 1
      end
      room:broadcastProperty(p, "maxHp")
      room:broadcastProperty(p, "hp")
      room:broadcastProperty(p, "shield")
    end
  end

  function vanished_dragon_logic:attachSkillToPlayers()
    local room = self.room
    local players = room.players
    local lord = room:getTag("ShownLoyalist")
  
    local addRoleModSkills = function(player, skillName)
      local skill = Fk.skills[skillName]
      if skill.lordSkill then
        return
      end
  
      if #skill.attachedKingdom > 0 and not table.contains(skill.attachedKingdom, player.kingdom) then
        return
      end
  
      room:handleAddLoseSkills(player, skillName, nil, false)
    end
    for _, p in ipairs(room.alive_players) do
      local skills = Fk.generals[p.general].skills
      for _, s in ipairs(skills) do
        addRoleModSkills(p, s.name)
      end
      for _, sname in ipairs(Fk.generals[p.general].other_skills) do
        addRoleModSkills(p, sname)
      end
  
      local deputy = Fk.generals[p.deputyGeneral]
      if deputy then
        skills = deputy.skills
        for _, s in ipairs(skills) do
          addRoleModSkills(p, s.name)
        end
        for _, sname in ipairs(deputy.other_skills) do
          addRoleModSkills(p, sname)
        end
      end

      if p.id == lord then
        local skill = (p.maxHp <= 4 and p:isMale()) and "vd_dongcha" or "vd_sheshen"
        room:sendLog{type = "#VDLoyalistSkill", from = p.id, arg = skill, toast = true}
        room:handleAddLoseSkills(p, skill, nil, false)
      end
    end
  end

  return vanished_dragon_logic
end

---@param killer ServerPlayer
---@param victim ServerPlayer
---@param room Room
local function rewardAndPunish(killer, victim, room)
  if killer.dead then return end
  local shownLoyalist = room:getTag("ShownLoyalist")
  if (victim.id == shownLoyalist and killer.role == "lord") or (victim.role == "loyalist" and killer.id == shownLoyalist) then
    killer:throwAllCards("he")
  elseif victim.role == "rebel" or victim.id == shownLoyalist then
    killer:drawCards(3, "kill")
  end
end

local vanished_dragon_rule = fk.CreateTriggerSkill{
  name = "#vanished_dragon_rule",
  priority = 10,
  mute = true,
  events = {fk.Deathed},
  --- FIXME:执行奖惩时机应为fk.BuryVictim，需要SkipGameRule逻辑大改
  can_trigger = function(self, event, target, player, data)
    return target == player and player.rest == 0
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local damage = data.damage
    if damage and damage.from then
      local killer = damage.from
      rewardAndPunish(killer, player, room)
    end

    if player.id == room:getTag("ShownLoyalist") then
      local lord = room:getLord()
      if not lord then return end
      room:setPlayerProperty(lord, "role_shown", true)
      room:broadcastProperty(lord, "role")
      room:sendLog{type = "#VDLordExploded", from = lord.id, toast = true}

      local skills = Fk.generals[lord.general]:getSkillNameList(true)
      local deputy = Fk.generals[lord.deputyGeneral]
      if deputy then
        table.insertTableIfNeed(skills, deputy:getSkillNameList(true))
      end
      for _, sname in ipairs(skills) do
        if Fk.skills[sname].lordSkill then
          room:handleAddLoseSkills(lord, sname, nil, false)
        end
      end
    end
  end,
}
Fk:addSkill(vanished_dragon_rule)

local vanished_dragon = fk.CreateGameMode{
  name = "vanished_dragon",
  minPlayer = 6,
  maxPlayer = 8,
  rule = vanished_dragon_rule,
  logic = vanished_dragon_getLogic,
  surrender_func = function(self, playedTime)
    return Fk.game_modes["aaa_role_mode"].surrenderFunc(self, playedTime)
  end,
  get_adjusted = function (self, player)
    if player.room:getTag("ShownLoyalist") == player.id then
      return {hp = player.hp + 1, maxHp = player.maxHp + 1}
    end
    return {}
  end
}


-- 洞察：游戏开始时，随机一名反贼的身份对你可见。准备阶段开始时，你可以弃置场上的一张牌。
local vd_dongcha = fk.CreateTriggerSkill{
  name = "vd_dongcha",
  anim_type = "control",
  events = {fk.GameStart, fk.EventPhaseStart}, 
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self) then
      if event == fk.GameStart then return true end
      return target == player and player.phase == Player.Start and table.find(player.room.alive_players, function(p)
        return #p:getCardIds("ej") > 0
      end)
    end
  end,
  on_cost = function(self, event, target, player, data)
    if event == fk.EventPhaseStart then
      local room = player.room
      local targets = table.map(table.filter(room.alive_players, function(p) return #p:getCardIds("ej") > 0 end), Util.IdMapper)
      local tos = room:askForChoosePlayers(player, targets, 1, 1, "#vd_dongcha-ask", self.name, true)
      if #tos > 0 then
        self.cost_data = tos[1]
        return true
      end
      return false
    end
    return true
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.GameStart then
      local players = table.simpleClone(room.alive_players)
      table.shuffle(players)
      for _, p in ipairs(players) do
        if p.role == "rebel" then
          room:notifyProperty(player, p, "role")
          break
        end
      end
      room:sendLog{type = "#VDDongcha", from = player.id, toast = true}
    else
      local to = room:getPlayerById(self.cost_data)
      local card = room:askForCardChosen(player, to, "ej", self.name)
      room:throwCard({card}, self.name, to, player)
    end
  end,
}
Fk:addSkill(vd_dongcha)

-- 舍身：锁定技，主公处于濒死状态即将死亡时，你令其体力上限+1，回复体力至X点（X为你的体力值），获得你所有牌，然后你死亡。
local vd_sheshen = fk.CreateTriggerSkill{
  name = "vd_sheshen",
  anim_type = "big",
  events = {fk.AskForPeachesDone},
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self) and target.role == "lord" and target.hp <= 0 and target.dying
    and not data.ignoreDeath and player:usedSkillTimes(self.name, Player.HistoryGame) == 0
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:changeMaxHp(target, 1)
    room:recover({
      who = target,
      num = player.hp - target.hp,
      recoverBy = player,
      skillName = self.name,
    })
    local cards = player:getCardIds{Player.Hand, Player.Equip}
    if #cards > 0 then
      room:obtainCard(target, cards, false, fk.ReasonPrey, player.id)
    end
    if not player.dead then
      room:killPlayer({who = player.id})
    end
  end,
}
Fk:addSkill(vd_sheshen)

Fk:loadTranslationTable{
  ["vanished_dragon"] = "忠胆英杰",
  [":vanished_dragon"] = desc_vanished_dragon,
  ["#VDIntro"] = "<b>%arg</b> 是 <b>明忠</b>，<b>开始选将</b><br>明忠是代替主公亮出身份牌的忠臣，明忠死后主公再翻出身份牌",
  ["#VDLoyalistSkill"] = "明忠 %from 获得忠臣技：%arg",
  ["#VDDongcha"] = "明忠 %from 发动了〖洞察〗，一名反贼的身份已被其知晓",
  ["#VDLordExploded"] = "明忠阵亡，主公暴露：%from",

  ["vd_dongcha"] = "洞察",
  [":vd_dongcha"] = "游戏开始时，随机一名反贼的身份对你可见。准备阶段开始时，你可以弃置场上的一张牌。",
  ["vd_sheshen"] = "舍身",
  [":vd_sheshen"] = "锁定技，主公处于濒死状态即将死亡时，你令其体力上限+1，回复体力至X点（X为你的体力值），获得你所有牌，然后你死亡。",
  ["$vd_sheshen1"] = "舍身为主，死而无憾！",
  ["$vd_sheshen2"] = "捐躯赴国难，视死忽如归。",

  ["#vd_dongcha-ask"] = "洞察：你可以选择一名角色，弃置其场上一张牌",
}

return vanished_dragon
