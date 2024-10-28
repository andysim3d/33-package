local U = require "packages/utility/utility"

local qin_generals = { "shangyang", "zhangyiq", "baiqi", "yingzheng", "lvbuwei", "zhaogao", "zhaoji", "miyue" } -- 秦将
local qin_soldiers = { "qin__qibing", "qin__bubing", "qin__nushou" } -- 秦兵
local han_generals = { "", "", "ex__caocao", "ex__liubei", "ex__sunquan" } -- 汉将

--- getSkills
---@param room Room
---@param num integer
---@return string[]
local function getSkills(room, num)
  num = num
  local skills = {}
  local skill_pool = room:getTag("skill_pool")
  if num > #skill_pool then return {} end
  for i = 1, num do
    local skill = table.random(skill_pool)
    table.removeOne(skill_pool, skill)
    table.insert(skills, skill)
  end
  return skills
end

local kangqin_getLogic = function()
  local kangqin_logic = GameLogic:subclass("kangqin_logic") ---@class GameLogic

  function kangqin_logic:initialize(room)
    GameLogic.initialize(self, room)
    self.role_table = { {"lord", "loyalist", "rebel", "rebel", "rebel", "loyalist", "loyalist", "loyalist"} }
  end

  function kangqin_logic:assignRoles()
    local room = self.room
    local players = room.players
    local n = #players
    local roles = self.role_table[1]
    table.shuffle(players)
    for i = 1, n do
      local p = players[i]
      p.role = roles[i]
      room:setPlayerProperty(p, "role_shown", true)
      room:broadcastProperty(p, "role")
    end
  end

  function kangqin_logic:chooseGenerals()
    local room = self.room
    local generalNum = room.settings.generalNum
    local n = room.settings.enableDeputy and 2 or 1
    local lord = room:getLord()
    room.current = lord
    -- 询问选将
    local lords, soldiers = table.random(qin_generals, math.max(2, generalNum//3) ), table.simpleClone(qin_soldiers)
    local others = room:getNGenerals( 2* generalNum )
    local to_ask = table.filter(room.players, function(p) return p.role ~= "rebel" end)
    local req = Request:new(to_ask, "AskForGeneral")
    req.focus_text = "AskForGeneral"
    for i, p in ipairs(room.players) do
      local arg, count = nil, 0
      if p == lord then -- 主公
        arg = lords
      elseif table.contains({2,8}, i) then -- 秦兵
        arg = soldiers
      elseif table.contains({6,7}, i) then -- 汉奸
        count = count + 1
        arg = table.slice(others, (count-1)*generalNum+1, count*generalNum+1)
      else -- 反贼
        local avatar = han_generals[i]
        room:setPlayerGeneral(p, avatar, true)
        room:broadcastProperty(p, "general")
      end
      if arg then
        req:setData(p, {arg, n})
        req:setDefaultReply(p, table.random(arg, n))
      end
    end
    -- 设置武将
    local selected = {}
    for _, p in ipairs(to_ask) do
      local general_ret = req:getResult(p)
      local general, deputy = general_ret[1], general_ret[2]
      table.insertTableIfNeed(selected, general_ret)
      room:setPlayerGeneral(p, general, true, true)
      room:setDeputyGeneral(p, deputy)
    end
    -- 返回武将库
    local ret_generals = table.filter(others, function(g) return not table.contains(selected, g) end)
    room:returnToGeneralPile(ret_generals)
  end

  function kangqin_logic:attachSkillToPlayers()
    local room = self.room
    local n = room.settings.enableDeputy and 2 or 1
    local players = room.players
    -- 创建技能池
    local skill_pool = {}
    for _, g_name in ipairs(room.general_pile) do
      local general = Fk.generals[g_name]
      if general.kingdom ~= "qin" then
        local skillNameList = general:getSkillNameList()
        skillNameList = table.filter(skillNameList, function(s) return Fk.skills[s].frequency <= 3 end)
        table.insertTableIfNeed(skill_pool, skillNameList)
      end
    end
    room:setTag("skill_pool", skill_pool)
    -- 选3个技能
    local num = math.floor(1.5* room.settings.generalNum)
    local to_ask = table.filter(players, function (p)
      return p.role == "rebel"
    end)
    local toSelectSkills = getSkills(room, #to_ask*num)
    local req = Request:new(to_ask, "CustomDialog")
    req.focus_text = "ChooseSkillsOfHans"
    for i, p in ipairs(to_ask) do
      local choices = table.slice(toSelectSkills, (i-1)*num +1, i*num +1)
      req:setData(p, {
        path = "packages/utility/qml/ChooseSkillBox.qml",
        data = { choices, 3*n, 3*n, "#kangqin-choose:::" .. tostring(3*n), {} },
      })
      req:setDefaultReply(p, table.random(choices, n*3))
    end

    for _, p in ipairs(to_ask) do
      local choice = req:getResult(p)
      room:handleAddLoseSkills(p, table.concat(choice, "|"), nil, false)
    end
    -- 上技能函数
    local addRoleModSkills = function(player, skillName)
      local skill = Fk.skills[skillName]
      if not skill then
        fk.qCritical("Skill: "..skillName.." doesn't exist!")
        return
      end
      if skill.lordSkill and (player.role ~= "lord" or #room.players < 5) then
        return
      end
      if #skill.attachedKingdom > 0 and not table.contains(skill.attachedKingdom, player.kingdom) then
        return
      end
      room:handleAddLoseSkills(player, skillName, nil, false)
    end
    -- 上技能
    local to_add = table.filter(players, function (p)
      return not table.contains(to_ask, p)
    end)
    for _, p in ipairs(to_add) do
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
    end
  end

  return kangqin_logic
end

local kangqin_rule = fk.CreateTriggerSkill{
  name = "#kangqin_rule",
  priority = 0.001,
  mute = true,
  events = { fk.GameStart, fk.BuryVictim },
  can_trigger = function (self, event, target, player, data)
    return target == player
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.GameStart then
      room:setTag("SkipNormalDeathProcess", true)
      -- 事件
      local storys = {"#kq__bianfa", "#kq__lianheng", "#kq__changping", "#kq__hengsao", "#kq__chunqiu", "#kq__shaqiu", "#kq__zhaoji", "#kq__taihou"}
      local story = table.random(storys)
      room:setBanner("@[:]kq_story", story)
      room:handleAddLoseSkills(room.players[1], story, self.name, false, false)
    else
      if target.kingdom == "qin" then
        if data.damage and data.damage.from then
          room:drawCards(data.damage.from, 3)
        end
      else
        for _, p in ipairs(room:getAlivePlayers()) do
          if p.kingdom ~= "qin" then
            room:drawCards(p, 1)
          end
        end
      end
    end
  end,
}
Fk:addSkill(kangqin_rule)

local kangqin_mode = fk.CreateGameMode{
  name = "kangqin_mode",
  minPlayer = 8,
  maxPlayer = 8,
  logic = kangqin_getLogic,
  rule = kangqin_rule,
}

local kangqin_desc = [[
  
# 合纵抗秦简介

  ---

  ## 身份说明

  游戏由8名玩家进行，8名玩家的身份分配如下：主公，忠臣（秦兵），反贼，反贼，反贼，忠臣（汉奸），忠臣（汉奸），忠臣（秦兵）

  ---

  ## 选将

  1. 主公从8名秦势力武将中选择（嬴政、白起、芈月、赵姬、吕不韦、赵高、商鞅、张仪）

  2. 忠臣（秦兵）从3名秦势力武将中选择（步兵、骑兵、弩手）；忠臣（汉奸）从将池中选择

  3. 反贼从3名武将中随机选择（界曹操、界孙权、界刘备；均无技能），选将结束后从随机的一定数量（受房间选将数影响）的技能中选择3个获得

  ---

  ## 启用副将

  主公、忠臣正常，为选择2名武将；反贼则改为选择6个技能获得

  ---
  
  ## 随机事件

  1. **变法图强**：
  牌堆中加入3张【商鞅变法】；
  若场上有商鞅，则商鞅使用的【商鞅变法】的目标上限+1。
  
  2. **合纵连横**：
  每个回合开始时，所有角色横置；
  若场上有张仪，则拥有“横”标记的角色无法对横置状态的角色使用牌。
  
  3. **长平之战**：
  游戏开始时，进入鏖战状态（所有角色只能将【桃】当【杀】或【闪】使用、打出）；
  当一名角色成为【杀】的目标时，其需要额外使用一张【闪】抵消之；
  若场上有白起，则秦势力角色的回合开始时，其获得一张【桃】。

  4. **横扫六合**：
  牌堆中加入【传国玉玺】和【真龙长剑】；
  若场上有嬴政，游戏开始时，嬴政将【传国玉玺】和【真龙长剑】置入装备区。

  5. **吕氏春秋**：
  所有男性角色的额定摸牌数+1；
  若场上有吕不韦，当吕不韦摸牌时，摸牌数+1。

  6. **沙丘之变**：
  当一名角色死亡时，将其所有牌随机分配给所有男性角色；
  若场上有赵高，则将上述“随机分配给所有男性角色”改为“交给赵高”。

  7. **赵姬之乱**：
  当一名男性角色每回合首次造成伤害时，此伤害-1；
  若场上有赵姬，则将上述“男性角色”改为“非秦势力角色”。

  8. **始称太后**：
  游戏开始时，所有女性角色的体力值和体力上限+1；
  若场上有芈月，每名男性角色的回合开始时，其选择一项：1.令芈月回复1点体力；2.令芈月摸一张牌。

  ---

  ## 击杀奖惩

  1. 非秦势力角色死亡后，所有非秦势力角色各摸一张牌。

  2. 秦势力角色死亡后，杀死其的角色摸三张牌。

  ---

  <font color="gray">模式专属武将及模式专属卡牌请移步至OL扩展包查看</font>

]]

Fk:loadTranslationTable{
  ["kangqin_mode"] = "合纵抗秦",
  [":kangqin_mode"] = kangqin_desc,
  ["#kangqin-choose"] = "从以下技能选择 %arg 个获得",
  ["@[:]kq_story"] = "事件",
}

--- 看看是不是包含指定武将
---@param player ServerPlayer
---@param name string
---@return boolean
local function isGeneral(player, name)
  return table.contains({player.general, player.deputyGeneral}, name)
end

--- 看看人在不在场(返回数量)
---@param room Room
---@param name string
---@return integer
local function numOnfield(room, name)
  return #table.filter(room.alive_players, function(p)
    return isGeneral(p, name)
  end)
end

local trans = {}

-- 商鞅变法
local bianfa_derivecards = {{"shangyang_reform", Card.Spade, 5}, {"shangyang_reform", Card.Spade, 7}, {"shangyang_reform", Card.Spade, 9}}

local bianfa = fk.CreateTriggerSkill{
  name = "#kq__bianfa",
  priority = 0.001,
  mute = true,
  events = {fk.GameStart, fk.AfterCardTargetDeclared},
  can_trigger = function(self, event, target, player, data)
    if event == fk.GameStart then
      return target == player
    else
      return target == player and isGeneral(player, "shangyang")
      and data.card.trueName == "shangyang_reform" and #U.getUseExtraTargets(player.room, data, false) > 0
    end
  end,
  on_cost = function(self, event, target, player, data)
    if event == fk.GameStart then
      return true
    else
      local room = player.room
      local targets = U.getUseExtraTargets(room, data, false)
      local to = room:askForChoosePlayers(player, targets, 1, 1, "#kq__bianfa-choose:::"..data.card:toLogString(), self.name, true)
      if #to > 0 then
        self.cost_data = to[1]
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:notifySkillInvoked(player, self.name, "special")
    if event == fk.GameStart then
      for _, id in ipairs(U.prepareDeriveCards(room, bianfa_derivecards, "bianfa_derivecards")) do
        if room:getCardArea(id) == Card.Void then
          table.removeOne(room.void, id)
          table.insert(room.draw_pile, math.random(1, #room.draw_pile), id)
          room:setCardArea(id, Card.DrawPile, nil)
        end
      end
      room:doBroadcastNotify("UpdateDrawPile", tostring(#room.draw_pile))
    else
      TargetGroup:pushTargets(data.tos, self.cost_data)
    end
  end,
}
Fk:addSkill(bianfa)

trans["#kq__bianfa"] = "商鞅变法"
trans[":#kq__bianfa"] = "牌堆中加入3张【商鞅变法】；"
  .."若场上有商鞅，则商鞅使用的【商鞅变法】的目标上限+1。"
trans["#kq__bianfa-choose"] = "商鞅变法：为可以为 %arg 增加一个目标"

-- 合纵连横
local lianheng_prohibit = fk.CreateProhibitSkill{
  name = "#kq__lianheng_prohibit",
  is_prohibited = function(self, from, to, card)
    if from:getMark("@@qin__lianheng") > 0 then
      return to.chained
    end
  end,
}
Fk:addSkill(lianheng_prohibit)

local lianheng = fk.CreateTriggerSkill{
  name = "#kq__lianheng",
  mute = true,
  events = {fk.TurnStart},
  can_trigger = function(self, event, target, player, data)
    return target == player
  end,
  on_cost = Util.TrueFunc,
  on_use = function (self, event, target, player, data)
    local room = player.room
    room:notifySkillInvoked(player, self.name, "special")
    for _, p in ipairs(room.alive_players) do
      local method = (numOnfield(room, "zhangyiq") > 0 and "-" or "")..lianheng_prohibit.name
      room:handleAddLoseSkills(p, method)
      if not p.chained then
        p:setChainState(true)
      end
    end
  end,
}
Fk:addSkill(lianheng)

trans["#kq__lianheng"] = "合纵连横"
trans[":#kq__lianheng"] = "每个回合开始时，所有角色横置；"
  .."若场上有张仪，则拥有“横”标记的角色无法对横置状态的角色使用牌。"
trans["#kq__lianheng_prohibit"] = "合纵连横"

-- 长平之战
local changping = fk.CreateTriggerSkill{
  name = "#kq__changping",
  mute = true,
  priority = 0.001,
  events = {fk.GameStart, fk.TurnStart},
  can_trigger = function (self, event, target, player, data)
    if target == player then
      local room = player.room
      if event == fk.GameStart then
        return true
      else
        return player.kingdom == "qin" and numOnfield(room, "baiqi") > 0
      end
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function (self, event, target, player, data)
    local room = player.room
    room:notifySkillInvoked(player, self.name, "special")
    if event == fk.GameStart then
      room:setBanner("@[:]BattleRoyalDummy", "BattleRoyalMode")
      for _, p in ipairs(room.players) do
        room:handleAddLoseSkills(p, "battle_royal&", nil, false, true)
      end
    else
      player:broadcastSkillInvoke("qin__wuan")
      local peach = room:getCardsFromPileByRule("peach", 1, "allPiles")
      if peach and #peach == 1 then
        room:obtainCard(player, peach[1], true, fk.ReasonPrey)
      end
    end
  end,
}
Fk:addSkill(changping)

trans["#kq__changping"] = "长平之战"
trans[":#kq__changping"] = "游戏开始时，进入鏖战状态（所有角色只能将【桃】当【杀】或【闪】使用、打出）；"
  .."当一名角色成为【杀】的目标时，其需要额外使用一张【闪】抵消之；"
  .."若场上有白起，则秦势力角色的回合开始时，其获得一张【桃】。"

-- 横扫六合
local hengsao_derivecards = {{"qin_dragon_sword", Card.Heart, 2}, {"qin_seal", Card.Heart, 7}}

local hengsao = fk.CreateTriggerSkill{
  name = "#kq__hengsao",
  priority = 0.001,
  mute = true,
  events = {fk.GameStart},
  can_trigger = function(self, event, target, player, data)
    return target == player
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:notifySkillInvoked(player, self.name, "special")
    player:broadcastSkillInvoke("qin__zulong")
    for _, id in ipairs(U.prepareDeriveCards(room, hengsao_derivecards, "hengsao_derivecards")) do
      if room:getCardArea(id) == Card.Void then
        table.removeOne(room.void, id)
        table.insert(room.draw_pile, math.random(1, #room.draw_pile), id)
        room:setCardArea(id, Card.DrawPile, nil)
      end
    end
    room:doBroadcastNotify("UpdateDrawPile", tostring(#room.draw_pile))
    for _, p in ipairs(room.alive_players) do
      local cards = room:getCardsFromPileByRule("qin_dragon_sword,qin_seal", 2, "allPiles")
      if #cards > 0 and isGeneral(p, "yingzheng") then
        room:moveCards({
          ids = cards,
          to = p.id,
          toArea = Card.PlayerEquip,
          moveReason = fk.ReasonJustMove,
          proposer = p.id,
          skillName = self.name,
        })
      end
    end
  end,
}
Fk:addSkill(hengsao)

trans["#kq__hengsao"] = "横扫六合"
trans[":#kq__hengsao"] = "牌堆中加入【传国玉玺】和【真龙长剑】；"
  .."若场上有嬴政，游戏开始时，嬴政将【传国玉玺】和【真龙长剑】置入装备区。"

-- 吕氏春秋
local chunqiu = fk.CreateTriggerSkill{
  name = "#kq__chunqiu",
  priority = 0.001,
  mute = true,
  events = {fk.DrawNCards, fk.BeforeDrawCard},
  can_trigger = function(self, event, target, player, data)
    if target ~= player then return end
    if event == fk.DrawNCards then
      return player:isMale()
    else
      return isGeneral(player, "lvbuwei")
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:notifySkillInvoked(player, self.name, "special")
    if event == fk.DrawNCards then
      data.n = data.n + 1
    else
      data.num = data.num + 1
    end
  end,
}
Fk:addSkill(chunqiu)

trans["#kq__chunqiu"] = "吕氏春秋"
trans[":#kq__chunqiu"] = "所有男性角色的额定摸牌数+1；"
  .."若场上有吕不韦，当吕不韦摸牌时，摸牌数+1。"

-- 沙丘之变
local shaqiu = fk.CreateTriggerSkill{
  name = "#kq__shaqiu",
  priority = 0.001,
  mute = true,
  events = {fk.Death},
  can_trigger = function (self, event, target, player, data)
    return target == player and not target:isNude()
  end,
  on_cost = Util.TrueFunc,
  on_use = function (self, event, target, player, data)
    local room = player.room
    room:notifySkillInvoked(player, self.name, "special")
    local tos = table.filter(room.alive_players, function (p)
      return p:isMale()
    end)
    if #tos == 0 then return end
    local cards_id = target:getCardIds{Player.Hand, Player.Equip}
    if numOnfield(room, "zhaogao") > 0 then
      for _, p in ipairs(room:getAlivePlayers()) do
        if isGeneral(p, "zhaogao") then
          room:obtainCard(p.id, cards_id, false, fk.ReasonPrey, p.id, self.name)
        end
      end
    else
      local distribution = {}
      for _, id in ipairs(cards_id) do
        local to = table.random(tos)
        local ids = distribution[to.id] or {}
        table.insert(ids, id)
        distribution[to.id] = ids
      end
      local move_data = {{}}
      local moveInfos = move_data[1]
      for _, p in ipairs(room.alive_players) do
        local ids = distribution[p.id]
        if ids then
          table.insert(moveInfos, {
            ids = ids,
            moveInfo = table.map(distribution[p.id], function(id) return {cardId = id, fromArea = room:getCardArea(id)} end),
            from = target.id,
            to = p.id,
            toArea = Card.PlayerHand,
            moveReason = fk.ReasonJustMove,
            skillName = self.name,
          })
        end
      end
      if #moveInfos > 0 then
        room:moveCards(table.unpack(moveInfos))
      end
    end
  end,
}
Fk:addSkill(shaqiu)

trans["#kq__shaqiu"] = "沙丘之变"
trans[":#kq__shaqiu"] = "当一名角色死亡时，将其所有牌随机分配给所有男性角色；"
  .."若场上有赵高，则将上述“随机分配给所有男性角色”改为“交给赵高”。"

-- 赵姬之乱
local zhaoji = fk.CreateTriggerSkill{
  name = "#kq__zhaoji",
  mute = true,
  priority = 0.001,
  events = {fk.DamageCaused},
  can_trigger = function(self, event, target, player, data)
    local room = player.room
    local from = data.from
    if target ~= player then return end
    local events = room.logic:getEventsOfScope(GameEvent.Damage, 2, function (e)
      for _, dmg_data in ipairs(e.data) do
        return dmg_data.from and dmg_data.from == from
      end
    end, player.HistoryTurn)
    if #events > 1 then return end
    if numOnfield(player.room, "zhaoji") > 0 then
      return from.kingdom ~= "qin"
    else
      return from:isMale()
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:notifySkillInvoked(player, self.name, "special")
    data.damage = data.damage - 1
  end,
}
Fk:addSkill(zhaoji)

trans["#kq__zhaoji"] = "赵姬之乱"
trans[":#kq__zhaoji"] = "当一名男性角色每回合首次造成伤害时，此伤害-1；"
  .."若场上有赵姬，则将上述“男性角色”改为“非秦势力角色”。"

-- 始称太后
local taihou = fk.CreateTriggerSkill{
  name = "#kq__taihou",
  mute = true,
  priority = 0.001,
  events = {fk.GameStart, fk.TurnStart},
  can_trigger = function (self, event, target, player, data)
    if target ~= player then return end
    if event == fk.GameStart then
      return true
    else
      return numOnfield(player.room, "miyue") > 0 and player:isMale()
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function (self, event, target, player, data)
    local room = player.room
    room:notifySkillInvoked(player, self.name, "special")
    if event == fk.GameStart then
      for _, p in ipairs(room:getAlivePlayers()) do
        if p:isFemale() then
          room:changeMaxHp(p, 1)
          room:recover{ who = p, num = 1, recoverBy = p, skillName = self.name }
        end
      end
    else
      local tos = table.filter(room:getAlivePlayers(), function (p)
        return isGeneral(p, "miyue")
      end)
      local all_choices = {"#kq__draw", "#kq__recover"}
      for _, miyue in pairs(tos) do
        local choices = table.simpleClone(all_choices)
        if miyue.hp == miyue.maxHp then
          table.removeOne(choices, "#kq__recover")
        end
        local choosed = room:askForChoice(player, choices, self.name, "#scth-ask:"..miyue.id, false, all_choices)
        if not choosed then choosed = all_choices[1] end
        if choosed == "#kq__draw" then
          miyue:drawCards(1, self.name)
        else
          room:recover{ who = miyue, num = 1, recoverBy = player, skillName = self.name }
        end
      end
    end
  end,
}
Fk:addSkill(taihou)

trans["#kq__taihou"] = "始称太后"
trans[":#kq__taihou"] = "游戏开始时，所有女性角色的体力值和体力上限+1；"
  .."若场上有芈月，每名男性角色的回合开始时，其选择一项：1.令芈月回复1点体力；2.令芈月摸一张牌。"
trans["#kq__draw"] = "令其摸一张牌"
trans["#kq__recover"] = "令其回复1点体力"
trans["#scth-ask"] = "选择一项令 %src 执行"
trans["ChooseSkillsOfHans"] = "汉将技能"

Fk:loadTranslationTable(trans)

return kangqin_mode