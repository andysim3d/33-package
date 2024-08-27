-- SPDX-License-Identifier: GPL-3.0-or-later
local extension = Package("jiange_generals")
extension.extensionName = "gamemode"

local U = require "packages/utility/utility"

Fk:loadTranslationTable{
  ["jiange_generals"] = "守卫剑阁",
  ["jiange"] = "剑阁",
}

local liubei = General(extension, "jiange__liubei", "shu", 6)
liubei.hidden = true
liubei.jiange_hero = true
local jiange__jizhen = fk.CreateTriggerSkill{
  name = "jiange__jizhen",
  anim_type = "support",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase == Player.Finish and
      table.find(U.GetFriends(player.room, player), function (p)
        return p:isWounded()
      end)
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askForSkillInvoke(player, self.name, nil, "#jiange__jizhen-invoke")
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local targets = table.filter(U.GetFriends(room, player), function (p)
      return p:isWounded()
    end)
    room:doIndicate(player.id, table.map(targets, Util.IdMapper))
    for _, p in ipairs(room:getAlivePlayers()) do
      if table.contains(targets, p) and not p.dead then
        p:drawCards(1, self.name)
      end
    end
  end,
}
local jiange__lingfeng = fk.CreateTriggerSkill{
  name = "jiange__lingfeng",
  anim_type = "offensive",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase == Player.Draw
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cards = room:getNCards(2)
    room:moveCardTo(cards, Card.Processing, nil, fk.ReasonJustMove, self.name, nil, true, player.id)
    room:delay(1000)
    local yes = #cards == 2 and Fk:getCardById(cards[1]).color ~= Fk:getCardById(cards[2]).color
    cards = table.filter(cards, function (id)
      return room:getCardArea(id) == Card.Processing
    end)
    if #cards > 0 then
      room:moveCardTo(cards, Card.PlayerHand, player, fk.ReasonJustMove, self.name, nil, true, player.id)
    end
    if yes and not player.dead and #U.GetEnemies(room, player) > 0 then
      local to = room:askForChoosePlayers(player, table.map(U.GetEnemies(room, player), Util.IdMapper), 1, 1,
        "#jiange__lingfeng-choose", self.name, true)
      if #to > 0 then
        room:loseHp(room:getPlayerById(to[1]), 1, self.name)
      end
    end
    return true
  end,
}
local jiange__qinzhen = fk.CreateTargetModSkill{
  name = "jiange__qinzhen",
  frequency = Skill.Compulsory,
  residue_func = function(self, player, skill, scope)
    if skill.trueName == "slash_skill" and scope == Player.HistoryPhase then
      return #table.filter(Fk:currentRoom().alive_players, function (p)
        return p:hasSkill(self) and table.contains(U.GetFriends(Fk:currentRoom(), p), player)
      end)
    end
  end,
}
liubei:addSkill(jiange__jizhen)
liubei:addSkill(jiange__lingfeng)
liubei:addSkill(jiange__qinzhen)
Fk:loadTranslationTable{
  ["jiange__liubei"] = "烈帝玄德",
  ["#jiange__liubei"] = "烈帝玄德",
  ["illustrator:jiange__liubei"] = "小北风巧绘",

  ["jiange__jizhen"] = "激阵",
  [":jiange__jizhen"] = "结束阶段，你可以令所有友方已受伤角色各摸一张牌。",
  ["jiange__lingfeng"] = "灵锋",
  [":jiange__lingfeng"] = "摸牌阶段，你可以放弃摸牌，改为亮出牌堆顶两张牌并获得之，若颜色不同，你可以令一名敌方角色失去1点体力。",
  ["jiange__qinzhen"] = "亲阵",
  [":jiange__qinzhen"] = "锁定技，友方角色出牌阶段使用【杀】次数上限+1。",
  ["#jiange__jizhen-invoke"] = "激阵：是否令所有友方已受伤角色各摸一张牌？",
  ["#jiange__lingfeng-choose"] = "灵锋：你可以令一名敌方角色失去1点体力",
}

local zhugeliang = General(extension, "jiange__zhugeliang", "shu", 5)
zhugeliang.hidden = true
zhugeliang.jiange_hero = true
local jiange__biantian = fk.CreateTriggerSkill{
  name = "jiange__biantian",
  anim_type = "control",
  frequency = Skill.Compulsory,
  events = {fk.EventPhaseStart},
  can_trigger = function (self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase == Player.Start
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    local judge = {
      who = player,
      reason = self.name,
      pattern = ".|.|^club",
    }
    room:judge(judge)
    local mark = {}
    if judge.card.color == Card.Red then
      for _, p in ipairs(U.GetEnemies(room, player)) do
        room:doIndicate(player.id, {p.id})
        room:addPlayerMark(p, "@@kuangfeng", 1)
        table.insert(mark, p.id)
      end
      room:setPlayerMark(player, "_kuangfeng", mark)
    elseif judge.card.suit == Card.Spade then
      for _, p in ipairs(U.GetFriends(room, player)) do
        room:doIndicate(player.id, {p.id})
        room:addPlayerMark(p, "@@dawu", 1)
        table.insert(mark, p.id)
      end
      room:setPlayerMark(player, "_dawu", mark)
    end
  end,

  refresh_events = {fk.TurnStart, fk.Death},
  can_refresh = function(self, event, target, player, data)
    return target == player and (player:getMark("_kuangfeng") ~= 0 or player:getMark("_dawu") ~= 0)
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    if player:getMark("_kuangfeng") ~= 0 then
      for _, id in ipairs(player:getTableMark("_kuangfeng")) do
        local p = room:getPlayerById(id)
        room:removePlayerMark(p, "@@kuangfeng", 1)
      end
      room:setPlayerMark(player, "_kuangfeng", 0)
    end
    if player:getMark("_dawu") ~= 0 then
      for _, id in ipairs(player:getTableMark("_dawu")) do
        local p = room:getPlayerById(id)
        room:removePlayerMark(p, "@@dawu", 1)
      end
      room:setPlayerMark(player, "_dawu", 0)
    end
  end,
}
local jiange__biantian_delay = fk.CreateTriggerSkill{
  name = "#jiange__biantian_delay",
  mute = true,
  events = {fk.DamageInflicted},
  can_trigger = function (self, event, target, player, data)
    return (target:getMark("@@kuangfeng") > 0 and data.damageType == fk.FireDamage and player:getMark("_kuangfeng") ~= 0) or
      (target:getMark("@@dawu") > 0 and data.damageType ~= fk.ThunderDamage and player:getMark("_dawu") ~= 0)
  end,
  on_cost = Util.TrueFunc,
  on_use = function (self, event, target, player, data)
    local room = player.room
    if target:getMark("@@kuangfeng") > 0 and data.damageType == fk.FireDamage and player:getMark("_kuangfeng") ~= 0 then
      room:notifySkillInvoked(player, "kuangfeng", "offensive")
      player:broadcastSkillInvoke("kuangfeng")
      data.damage = data.damage + 1
    end
    if target:getMark("@@dawu") > 0 and data.damageType ~= fk.ThunderDamage and player:getMark("_dawu") ~= 0 then
      room:notifySkillInvoked(player, "dawu", "defensive")
      player:broadcastSkillInvoke("dawu")
      return true
    end
  end,
}
jiange__biantian:addRelatedSkill(jiange__biantian_delay)
zhugeliang:addSkill(jiange__biantian)
zhugeliang:addSkill("bazhen")
Fk:loadTranslationTable{
  ["jiange__zhugeliang"] = "天侯孔明",
  ["#jiange__zhugeliang"] = "天侯孔明",
  ["illustrator:jiange__zhugeliang"] = "小北风巧绘",

  ["jiange__biantian"] = "变天",
  [":jiange__biantian"] = "锁定技，准备阶段，你进行一次判定，若结果为：<br>"..
  "红色，所有敌方进入狂风状态（若天侯孔明在场，受到火焰伤害+1），直到你下回合开始；<br>"..
  "♠，所有友方进入大雾状态（若天侯孔明在场，受到非雷电伤害时，防止此伤害），直到你下回合开始。",
  ["#jiange__biantian_delay"] = "变天",
}

local huangyueying = General(extension, "jiange__huangyueying", "shu", 5, 5, General.Female)
huangyueying.hidden = true
huangyueying.jiange_hero = true
local jiange__gongshen = fk.CreateTriggerSkill{
  name = "jiange__gongshen",
  mute = true,
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase == Player.Finish and
      (table.find(U.GetEnemies(player.room, player), function (p)
        return Fk.generals[p.general].jiange_machine
      end) or
      table.find(U.GetFriends(player.room, player), function (p)
        return Fk.generals[p.general].jiange_machine and p:isWounded()
      end))
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local choices = {}
    if table.find(U.GetFriends(room, player), function (p)
      return Fk.generals[p.general].jiange_machine and p:isWounded()
    end) then
      table.insert(choices, "jiange__gongshen1")
    end
    if table.find(U.GetEnemies(room, player), function (p)
      return Fk.generals[p.general].jiange_machine
    end) then
      table.insert(choices, "jiange__gongshen2")
    end
    table.insert(choices, "Cancel")
    local choice = room:askForChoice(player, choices, self.name,
      "#jiange__gongshen-invoke", false, {"jiange__gongshen1", "jiange__gongshen2", "Cancel"})
    if choice ~= "Cancel" then
      self.cost_data = choice[17]
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke(self.name)
    if self.cost_data == "1" then
      local targets = table.filter(U.GetFriends(room, player), function (p)
        return Fk.generals[p.general].jiange_machine and p:isWounded()
      end)
      room:doIndicate(player.id, table.map(targets, Util.IdMapper))
      for _, p in ipairs(room:getOtherPlayers(player)) do
        if table.contains(targets, p) and not p.dead and p:isWounded() then
          room:recover({
            who = p,
            num = 1,
            recoverBy = player,
            skillName = self.name,
          })
        end
      end
    else
      local targets = table.filter(U.GetEnemies(room, player), function (p)
        return Fk.generals[p.general].jiange_machine
      end)
      room:doIndicate(player.id, table.map(targets, Util.IdMapper))
      for _, p in ipairs(room:getOtherPlayers(player)) do
        if table.contains(targets, p) and not p.dead then
          room:damage({
            from = player,
            to = p,
            damage = 1,
            damageType = fk.FireDamage,
            skillName = self.name,
          })
        end
      end
    end
  end,
}
local jiange__zhinang = fk.CreateTriggerSkill{
  name = "jiange__zhinang",
  anim_type = "drawcard",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase == Player.Start
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cards = room:getNCards(3)
    room:moveCardTo(cards, Card.Processing, nil, fk.ReasonJustMove, self.name, nil, true, player.id)
    room:delay(1000)
    cards = table.filter(cards, function (id)
      return room:getCardArea(id) == Card.Processing
    end)
    if #cards == 0 then return end
    if player.dead then
      room:moveCardTo(cards, Card.DiscardPile, nil, fk.ReasonJustMove, self.name, nil, true, player.id)
      return
    end
    local get = table.filter(cards, function (id)
      return Fk:getCardById(id).type ~= Card.TypeBasic
    end)
    if #get > 0 then
      local to = room:askForChoosePlayers(player, table.map(U.GetFriends(room, player), Util.IdMapper), 1, 1,
        "#jiange__zhinang-give", self.name, true)
      if #to > 0 then
        to = room:getPlayerById(to[1])
        room:moveCardTo(get, Card.PlayerHand, to, fk.ReasonGive, self.name, nil, true, player.id)
      end
    end
    cards = table.filter(cards, function (id)
      return room:getCardArea(id) == Card.Processing
    end)
    if #cards > 0 then
      room:moveCardTo(cards, Card.DiscardPile, nil, fk.ReasonJustMove, self.name, nil, true, player.id)
    end
  end,
}
local jiange__jingmiao = fk.CreateTriggerSkill{
  name = "jiange__jingmiao",
  anim_type = "offensive",
  frequency = Skill.Compulsory,
  events = {fk.CardUseFinished},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self) and data.card.trueName == "nullification" and
      table.contains(U.GetEnemies(player.room, player), target) and not target.dead
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:doIndicate(player.id, {target.id})
    room:loseHp(target, 1, self.name)
  end,
}
huangyueying:addSkill(jiange__gongshen)
huangyueying:addSkill(jiange__zhinang)
huangyueying:addSkill(jiange__jingmiao)
Fk:loadTranslationTable{
  ["jiange__huangyueying"] = "工神月英",
  ["#jiange__huangyueying"] = "工神月英",
  ["illustrator:jiange__huangyueying"] = "小北风巧绘",

  ["jiange__gongshen"] = "工神",
  [":jiange__gongshen"] = "结束阶段，你可以令友方攻城器械各回复1点体力，或对敌方攻城器械各造成1点火焰伤害。",
  ["jiange__zhinang"] = "智囊",
  [":jiange__zhinang"] = "准备阶段，你可以亮出牌堆顶三张牌，然后你可以将其中的非基本牌交给一名友方角色。",
  ["jiange__jingmiao"] = "精妙",
  [":jiange__jingmiao"] = "锁定技，当敌方角色使用【无懈可击】结算后，其失去1点体力。",
  ["jiange__gongshen1"] = "友方攻城器械回复1点体力",
  ["jiange__gongshen2"] = "对敌方攻城器械造成1点火焰伤害",
  ["#jiange__gongshen-invoke"] = "工神：你可以执行一项",
  ["#jiange__zhinang-give"] = "智囊：你可以将其中的非基本牌交给一名友方角色",
}

local pangtong = General(extension, "jiange__pangtong", "shu", 5)
pangtong.hidden = true
pangtong.jiange_hero = true
local jiange__yuhuo = fk.CreateTriggerSkill{
  name = "jiange__yuhuo",
  anim_type = "defensive",
  frequency = Skill.Compulsory,
  events = {fk.DamageInflicted},
  can_trigger = function(self, _, target, player, data)
    return target == player and player:hasSkill(self) and data.damageType == fk.FireDamage
  end,
  on_use = Util.TrueFunc,
}
local jiange__qiwu = fk.CreateTriggerSkill{
  name = "jiange__qiwu",
  anim_type = "support",
  events = {fk.CardUsing},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and data.card.suit == Card.Club and
      table.find(U.GetFriends(player.room, player), function (p)
        return p:isWounded()
      end)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = table.filter(U.GetFriends(room, player), function (p)
      return p:isWounded()
    end)
    local to = room:askForChoosePlayers(player, table.map(targets, Util.IdMapper), 1, 1,
      "#jiange__qiwu-choose", self.name, true)
    if #to > 0 then
      self.cost_data = to[1]
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(self.cost_data)
    room:recover({
      who = to,
      num = 1,
      recoverBy = player,
      skillName = self.name,
    })
  end,
}
local jiange__tianyu = fk.CreateTriggerSkill{
  name = "jiange__tianyu",
  anim_type = "offensive",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase == Player.Finish and
      table.find(U.GetEnemies(player.room, player), function (p)
        return not p.chained
      end)
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askForSkillInvoke(player, self.name, nil, "#jiange__tianyu-invoke")
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke("lianhuan")
    local targets = table.filter(U.GetEnemies(room, player), function (p)
      return not p.chained
    end)
    room:doIndicate(player.id, table.map(targets, Util.IdMapper))
    for _, p in ipairs(room:getOtherPlayers(player)) do
      if table.contains(targets, p) and not p.dead then
        p:setChainState(true)
      end
    end
  end,
}
pangtong:addSkill(jiange__yuhuo)
pangtong:addSkill(jiange__qiwu)
pangtong:addSkill(jiange__tianyu)
Fk:loadTranslationTable{
  ["jiange__pangtong"] = "浴火士元",
  ["#jiange__pangtong"] = "浴火士元",
  ["illustrator:jiange__pangtong"] = "銘zmy",

  ["jiange__yuhuo"] = "浴火",
  [":jiange__yuhuo"] = "锁定技，防止你受到的火焰伤害。",
  ["jiange__qiwu"] = "栖梧",
  [":jiange__qiwu"] = "当你使用♣牌时，你可以令一名友方角色回复1点体力。",
  ["jiange__tianyu"] = "天狱",
  [":jiange__tianyu"] = "结束阶段，你可以横置所有敌方角色。",
  ["#jiange__qiwu-choose"] = "栖梧：你可以令一名友方角色回复1点体力",
  ["#jiange__tianyu-invoke"] = "天狱：是否横置所有敌方角色？",
}

local guanyu = General(extension, "jiange__guanyu", "shu", 6)
guanyu.hidden = true
guanyu.jiange_hero = true
local jiange__xiaorui = fk.CreateTriggerSkill{
  name = "jiange__xiaorui",
  anim_type = "support",
  frequency = Skill.Compulsory,
  events = {fk.Damage},
  can_trigger = function(self, event, target, player, data)
    if target and player:hasSkill(self) and data.card and data.card.trueName == "slash" and
      table.contains(U.GetFriends(player.room, player), target) then
      local turn_event = player.room.logic:getCurrentEvent():findParent(GameEvent.Turn)
      if turn_event then
        return target == turn_event.data[1]
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:doIndicate(player.id, {target.id})
    room:addPlayerMark(target, MarkEnum.SlashResidue.."-turn", 1)
  end,
}
local jiange__huchen = fk.CreateTriggerSkill{
  name = "jiange__huchen",
  anim_type = "drawcard",
  frequency = Skill.Compulsory,
  events = {fk.DrawNCards},
  can_trigger = function (self, event, target, player, data)
    if target == player and player:hasSkill(self) then
      local room = player.room
      local n = #room.logic:getEventsOfScope(GameEvent.Death, 999, function(e)
        local death = e.data[1]
        return death.damage and death.damage.from == player and
          table.contains(U.GetEnemies(room, player, true), room:getPlayerById(death.who))
      end, Player.HistoryGame)
      if n > 0 then
        self.cost_data = n
        return true
      end
    end
  end,
  on_use = function (self, event, target, player, data)
    data.n = data.n + self.cost_data
  end,
}
local jiange__tianjiang = fk.CreateTriggerSkill{
  name = "jiange__tianjiang",
  anim_type = "support",
  frequency = Skill.Compulsory,
  events = {fk.Damage},
  can_trigger = function(self, event, target, player, data)
    if target and player:hasSkill(self) and data.card and data.card.trueName == "slash" and
      table.contains(U.GetFriends(player.room, player), target) then
      local room = player.room
      local turn_event = room.logic:getCurrentEvent():findParent(GameEvent.Turn)
      if turn_event == nil then return end
      local damage_event = room.logic:getCurrentEvent()
      if not damage_event then return end
      local events = room.logic:getActualDamageEvents(1, function(e)
        local damage = e.data[1]
        return damage.from and damage.from == player and damage.card and damage.card.trueName == "slash"
      end, Player.HistoryTurn)
      if #events > 0 and damage_event.id == events[1].id then
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    player.room:doIndicate(player.id, {target.id})
    target:drawCards(1, self.name)
  end,
}
guanyu:addSkill(jiange__xiaorui)
guanyu:addSkill(jiange__huchen)
guanyu:addSkill(jiange__tianjiang)
Fk:loadTranslationTable{
  ["jiange__guanyu"] = "翊汉云长",
  ["#jiange__guanyu"] = "翊汉云长",
  --["illustrator:jiange__guanyu"] = "",

  ["jiange__xiaorui"] = "骁锐",
  [":jiange__xiaorui"] = "锁定技，当友方角色于其回合内使用【杀】造成伤害后，你令其本回合出牌阶段使用【杀】次数上限+1。",
  ["jiange__huchen"] = "虎臣",
  [":jiange__huchen"] = "锁定技，摸牌阶段，你额外摸X张牌（X为你杀死的敌方角色数）。",
  ["jiange__tianjiang"] = "天将",
  [":jiange__tianjiang"] = "锁定技，当友方角色每回合首次使用【杀】造成伤害后，其摸一张牌。",
}

local zhaoyun = General(extension, "jiange__zhaoyun", "shu", 6)
zhaoyun.hidden = true
zhaoyun.jiange_hero = true
local jiange__fengjian = fk.CreateTriggerSkill{
  name = "jiange__fengjian",
  anim_type = "control",
  frequency = Skill.Compulsory,
  events = {fk.Damage},
  can_trigger = function(self, event, target, player, data)
    return target and target == player and player:hasSkill(self) and not data.to.dead
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:doIndicate(player.id, {data.to.id})
    local mark = data.to:getTableMark("@@jiange__fengjian")
    table.insertIfNeed(mark, player.id)
    room:setPlayerMark(data.to, "@@jiange__fengjian", mark)
  end,

  refresh_events = {fk.AfterTurnEnd},
  can_refresh = function(self, event, target, player, data)
    return target == player and player:getMark("@@jiange__fengjian") ~= 0
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:setPlayerMark(player, "@@jiange__fengjian", 0)
  end,
}
local jiange__fengjian_prohibit = fk.CreateProhibitSkill{
  name = "#jiange__fengjian_prohibit",
  is_prohibited = function (self, from, to, card)
    if from:getMark("@@jiange__fengjian") ~= 0 and card then
      return table.contains(from:getTableMark("@@jiange__fengjian"), to.id)
    end
  end,
}
local jiange__keding = fk.CreateTriggerSkill{
  name = "jiange__keding",
  anim_type = "control",
  events = {fk.AfterCardTargetDeclared},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and #TargetGroup:getRealTargets(data.tos) == 1 and
      (data.card.trueName == "slash" or data.card:isCommonTrick()) and
      #U.getUseExtraTargets(player.room, data, false) > 0 and
      not player:isKongcheng()
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = U.getUseExtraTargets(room, data, false)
    local _, dat = room:askForUseActiveSkill(player, "jiange__keding_active",
      "#jiange__keding-choose:::"..data.card:toLogString(), true, {exclusive_targets = targets}, false)
    if dat then
      self.cost_data = dat
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local tos = self.cost_data.targets
    room:sortPlayersByAction(tos)
    for _, id in ipairs(tos) do
      table.insert(data.tos, {id})
    end
    room:throwCard(self.cost_data.cards, self.name, player, player)
  end,
}
local jiange__keding_active = fk.CreateActiveSkill{
  name = "jiange__keding_active",
  min_card_num = 1,
  min_target_num = 1,
  card_filter = function(self, to_select, selected)
    return table.contains(Self:getCardIds("h"), to_select) and not Self:prohibitDiscard(to_select)
  end,
  target_filter = function (self, to_select, selected, selected_cards)
    return #selected < #selected_cards
  end,
  feasible = function (self, selected, selected_cards)
    return #selected > 0 and #selected == #selected_cards
  end,
}
local jiange__longwei = fk.CreateTriggerSkill{
  name = "jiange__longwei",
  anim_type = "support",
  events = {fk.EnterDying},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self) and table.contains(U.GetFriends(player.room, player), target)
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askForSkillInvoke(player, self.name, data, "#jiange__longwei-invoke::"..target.id)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:doIndicate(player.id, {target.id})
    room:changeMaxHp(player, -1)
    if target:isWounded() and not target.dead then
      room:recover{
        who = target,
        num = 1,
        recoverBy = player,
        skillName = self.name,
      }
    end
  end,
}
jiange__fengjian:addRelatedSkill(jiange__fengjian_prohibit)
Fk:addSkill(jiange__keding_active)
zhaoyun:addSkill(jiange__fengjian)
zhaoyun:addSkill(jiange__keding)
zhaoyun:addSkill(jiange__longwei)
Fk:loadTranslationTable{
  ["jiange__zhaoyun"] = "扶危子龙",
  ["#jiange__zhaoyun"] = "扶危子龙",
  --["illustrator:jiange__zhaoyun"] = "",

  ["jiange__fengjian"] = "封缄",
  [":jiange__fengjian"] = "锁定技，当你对一名角色造成伤害后，其使用牌不能指定你为目标，直到其下回合结束。",
  ["jiange__keding"] = "克定",
  [":jiange__keding"] = "当你使用【杀】或普通锦囊牌指定唯一目标时，你可以弃置任意张手牌，为此牌增加等量的目标。",
  ["jiange__longwei"] = "龙威",
  [":jiange__longwei"] = "当友方角色进入濒死状态时，你可以减1点体力上限，令其回复1点体力。",
  ["@@jiange__fengjian"] = "封缄",
  ["jiange__keding_active"] = "克定",
  ["#jiange__keding-choose"] = "克定：你可以弃置任意张手牌，为此%arg增加等量的目标",
  ["#jiange__longwei-invoke"] = "龙威：是否减1点体力上限，令 %dest 回复1点体力？",
}

local zhangfei = General(extension, "jiange__zhangfei", "shu", 5)
zhangfei.hidden = true
zhangfei.jiange_hero = true
local jiange__mengwu = fk.CreateTriggerSkill{
  name = "jiange__mengwu",
  anim_type = "drawcard",
  frequency = Skill.Compulsory,
  events = {fk.CardEffectCancelledOut},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and data.card.trueName == "slash"
  end,
  on_use = function(self, event, target, player, data)
    player:drawCards(2, self.name)
  end,
}
local jiange__mengwu_targetmod = fk.CreateTargetModSkill{
  name = "#jiange__mengwu_targetmod",
  main_skill = jiange__mengwu,
  frequency = Skill.Compulsory,
  bypass_times = function(self, player, skill, scope, card, to)
    return player:hasSkill(jiange__mengwu) and skill.trueName == "slash_skill"
  end,
  bypass_distances =  function(self, player, skill, card, to)
    return player:hasSkill(jiange__mengwu) and skill.trueName == "slash_skill"
  end,
}
local jiange__hupo = fk.CreateFilterSkill{
  name = "jiange__hupo",
  anim_type = "offensive",
  frequency = Skill.Compulsory,
  card_filter = function(self, card, player)
    return player:hasSkill(self) and card.type == Card.TypeTrick and table.contains(player:getCardIds("h"), card.id)
  end,
  view_as = function(self, to_select)
    return Fk:cloneCard("slash", to_select.suit, to_select.number)
  end,
}
local jiange__shuhun = fk.CreateTriggerSkill{
  name = "jiange__shuhun",
  anim_type = "support",
  frequency = Skill.Compulsory,
  events = {fk.Damage},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and
      table.find(U.GetFriends(player.room, player), function (p)
        return p:isWounded()
      end)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = table.random(table.filter(U.GetFriends(room, player), function (p)
      return p:isWounded()
    end))
    room:doIndicate(player.id, {to.id})
    room:recover({
      who = to,
      num = 1,
      recoverBy = player,
      skillName = self.name,
    })
  end,
}
jiange__mengwu:addRelatedSkill(jiange__mengwu_targetmod)
zhangfei:addSkill(jiange__mengwu)
zhangfei:addSkill(jiange__hupo)
zhangfei:addSkill(jiange__shuhun)
Fk:loadTranslationTable{
  ["jiange__zhangfei"] = "威武翼德",
  ["#jiange__zhangfei"] = "威武翼德",
  ["illustrator:jiange__zhangfei"] = "鬼画府",

  ["jiange__mengwu"] = "猛武",
  [":jiange__mengwu"] = "锁定技，你使用【杀】无距离次数限制，当你使用【杀】被抵消后，你摸两张牌。",
  ["jiange__hupo"] = "虎魄",
  [":jiange__hupo"] = "锁定技，你的锦囊牌均视为【杀】。",
  ["jiange__shuhun"] = "蜀魂",
  [":jiange__shuhun"] = "锁定技，当你造成伤害后，你令随机一名友方角色回复1点体力。",
}

local caozhen = General(extension, "jiange__caozhen", "wei", 5)
caozhen.hidden = true
caozhen.jiange_hero = true
local jiange__chiying = fk.CreateTriggerSkill{
  name = "jiange__chiying",
  anim_type = "defensive",
  frequency = Skill.Compulsory,
  events = {fk.DamageInflicted},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self) and data.damage > 1 and table.contains(U.GetFriends(player.room, player), target)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:broadcastPlaySound("./packages/maneuvering/audio/card/silver_lion")
    room:setEmotion(target, "./packages/maneuvering/image/anim/silver_lion")
    data.damage = 1
  end,
}
local jiange__jingfan = fk.CreateDistanceSkill{
  name = "jiange__jingfan",
  frequency = Skill.Compulsory,
  correct_func = function(self, from, to)
    return -#table.filter(Fk:currentRoom().alive_players, function (p)
      return p:hasSkill(self) and
        table.contains(U.GetFriends(Fk:currentRoom(), p, false), from) and table.contains(U.GetEnemies(Fk:currentRoom(), p), to)
    end)
  end,
}
local jiange__zhenxi = fk.CreateTriggerSkill{
  name = "jiange__zhenxi",
  anim_type = "masochism",
  frequency = Skill.Compulsory,
  events = {fk.Damaged},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self) and table.contains(U.GetFriends(player.room, player), target)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:doIndicate(player.id, {target.id})
    room:addPlayerMark(target, "@jiange__zhenxi", 1)
  end,

  refresh_events = {fk.DrawNCards},
  can_refresh = function (self, event, target, player, data)
    return target == player and player:getMark("@jiange__zhenxi") > 0
  end,
  on_refresh = function (self, event, target, player, data)
    data.n = data.n + player:getMark("@jiange__zhenxi")
    player.room:setPlayerMark(player, "@jiange__zhenxi", 0)
  end,
}
caozhen:addSkill(jiange__chiying)
caozhen:addSkill(jiange__jingfan)
caozhen:addSkill(jiange__zhenxi)
Fk:loadTranslationTable{
  ["jiange__caozhen"] = "佳人子丹",
  ["#jiange__caozhen"] = "佳人子丹",
  ["illustrator:jiange__caozhen"] = "小北风巧绘",

  ["jiange__chiying"] = "持盈",
  [":jiange__chiying"] = "锁定技，当友方角色受到大于1点的伤害时，你令此伤害减至1点。",
  ["jiange__jingfan"] = "惊帆",
  [":jiange__jingfan"] = "锁定技，其他友方角色计算与敌方角色距离-1。",
  ["jiange__zhenxi"] = "镇西",
  [":jiange__zhenxi"] = "锁定技，当友方角色受到伤害后，其下个摸牌阶段摸牌数+1。",
  ["@jiange__zhenxi"] = "镇西",
}

local simayi = General(extension, "jiange__simayi", "wei", 5)
simayi.hidden = true
simayi.jiange_hero = true
local jiange__konghun = fk.CreateTriggerSkill{
  name = "jiange__konghun",
  anim_type = "offensive",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase == Player.Play and player:isWounded() and
      player:getLostHp() >= #U.GetEnemies(player.room, player)
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askForSkillInvoke(player, self.name, nil, "#jiange__konghun-invoke")
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:doIndicate(player.id, table.map(U.GetEnemies(room, player), Util.IdMapper))
    local n = 0
    for _, p in ipairs(room:getOtherPlayers(player)) do
      if table.contains(U.GetEnemies(room, player), p) and not p.dead then
        n = n + 1
        room:damage({
          from = player,
          to = p,
          damage = 1,
          damageType = fk.ThunderDamage,
          skillName = self.name,
        })
      end
    end
    if not player.dead and player:isWounded() then
      room:recover({
        who = player,
        num = math.min(n, player:getLostHp()),
        recoverBy = player,
        skillName = self.name,
      })
    end
  end,
}
local jiange__fanshi = fk.CreateTriggerSkill{
  name = "jiange__fanshi",
  anim_type = "negative",
  frequency = Skill.Compulsory,
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase == Player.Finish
  end,
  on_use = function(self, event, target, player, data)
    player.room:loseHp(player, 1, self.name)
  end,
}
local jiange__xuanlei = fk.CreateTriggerSkill{
  name = "jiange__xuanlei",
  anim_type = "offensive",
  frequency = Skill.Compulsory,
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase == Player.Start and
      table.find(U.GetEnemies(player.room, player), function (p)
        return #p:getCardIds("j") > 0
      end)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local targets = table.filter(U.GetEnemies(room, player), function (p)
      return #p:getCardIds("j") > 0
    end)
    room:doIndicate(player.id, table.map(targets, Util.IdMapper))
    for _, p in ipairs(room:getOtherPlayers(player)) do
      if table.contains(targets, p) and not p.dead then
        room:damage({
          from = player,
          to = p,
          damage = 1,
          damageType = fk.ThunderDamage,
          skillName = self.name,
        })
      end
    end
  end,
}
simayi:addSkill(jiange__konghun)
simayi:addSkill(jiange__fanshi)
simayi:addSkill(jiange__xuanlei)
Fk:loadTranslationTable{
  ["jiange__simayi"] = "断狱仲达",
  ["#jiange__simayi"] = "断狱仲达",
  ["illustrator:jiange__simayi"] = "小北风巧绘",

  ["jiange__konghun"] = "控魂",
  [":jiange__konghun"] = "出牌阶段开始时，若你已损失体力值不小于敌方角色数，你可以对所有敌方角色各造成1点雷电伤害，然后你回复X点体力"..
  "（X为受到伤害的角色数）。",
  ["jiange__fanshi"] = "反噬",
  [":jiange__fanshi"] = "锁定技，结束阶段，你失去1点体力。",
  ["jiange__xuanlei"] = "玄雷",
  [":jiange__xuanlei"] = "锁定技，准备阶段，你对判定区内有牌的所有敌方角色各造成1点雷电伤害。",
  ["#jiange__konghun-invoke"] = "控魂：是否对所有敌方角色各造成1点雷电伤害，你回复体力？",
}

local xiahouyuan = General(extension, "jiange__xiahouyuan", "wei", 5)
xiahouyuan.hidden = true
xiahouyuan.jiange_hero = true
local jiange__chuanyun = fk.CreateTriggerSkill{
  name = "jiange__chuanyun",
  anim_type = "offensive",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase == Player.Finish and
      table.find(player.room.alive_players, function (p)
        return p.hp > player.hp
      end)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = table.filter(room.alive_players, function (p)
      return p.hp > player.hp
    end)
    local to = room:askForChoosePlayers(player, table.map(targets, Util.IdMapper), 1, 1,
      "#jiange__chuanyun-choose", self.name, true)
    if #to > 0 then
      self.cost_data = to[1]
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:damage({
      from = player,
      to = room:getPlayerById(self.cost_data),
      damage = 1,
      skillName = self.name,
    })
  end,
}
local jiange__leili = fk.CreateTriggerSkill{
  name = "jiange__leili",
  anim_type = "offensive",
  events = {fk.Damage},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and data.card and data.card.trueName == "slash" and
      table.find(U.GetEnemies(player.room, player), function (p)
        return p ~= data.to
      end)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = table.filter(U.GetEnemies(room, player), function (p)
      return p ~= data.to
    end)
    local to = room:askForChoosePlayers(player, table.map(targets, Util.IdMapper), 1, 1,
      "#jiange__leili-choose", self.name, true)
    if #to > 0 then
      self.cost_data = to[1]
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke("ol_ex__shensu")
    room:damage({
      from = player,
      to = room:getPlayerById(self.cost_data),
      damage = 1,
      damageType = fk.ThunderDamage,
      skillName = self.name,
    })
  end,
}
local jiange__fengxing = fk.CreateTriggerSkill{
  name = "jiange__fengxing",
  anim_type = "offensive",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase == Player.Start and
      table.find(U.GetEnemies(player.room, player), function (p)
        return not player:isProhibited(p, Fk:cloneCard("slash"))
      end)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = table.filter(U.GetEnemies(room, player), function (p)
      return not player:isProhibited(p, Fk:cloneCard("slash"))
    end)
    local use = U.askForUseVirtualCard(room, player, "slash", nil, self.name,
      "#jiange__fengxing-slash", true, true, true, true, {exclusive_targets = table.map(targets, Util.IdMapper)}, true)
    if use then
      self.cost_data = use
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    player:broadcastSkillInvoke("shensu")
    player.room:useCard(self.cost_data)
  end,
}
xiahouyuan:addSkill(jiange__chuanyun)
xiahouyuan:addSkill(jiange__leili)
xiahouyuan:addSkill(jiange__fengxing)
Fk:loadTranslationTable{
  ["jiange__xiahouyuan"] = "绝尘妙才",
  ["#jiange__xiahouyuan"] = "绝尘妙才",
  ["illustrator:jiange__xiahouyuan"] = "小北风巧绘",

  ["jiange__chuanyun"] = "穿云",
  [":jiange__chuanyun"] = "结束阶段，你可以对一名体力值大于你的角色造成1点伤害。",
  ["jiange__leili"] = "雷厉",
  [":jiange__leili"] = "当你使用【杀】造成伤害后，你可以对另一名敌方角色造成1点雷电伤害。",
  ["jiange__fengxing"] = "风行",
  [":jiange__fengxing"] = "准备阶段，你可以视为对一名敌方角色使用一张【杀】。",
  ["#jiange__chuanyun-choose"] = "穿云：你可以对一名体力值大于你的角色造成1点伤害",
  ["#jiange__leili-choose"] = "雷厉：你可以对另一名敌方角色造成1点雷电伤害",
  ["#jiange__fengxing-slash"] = "风行：你可以视为对一名敌方角色使用一张【杀】",
}

local zhanghe = General(extension, "jiange__zhanghe", "wei", 5)
zhanghe.hidden = true
zhanghe.jiange_hero = true
local jiange__huodi = fk.CreateTriggerSkill{
  name = "jiange__huodi",
  anim_type = "control",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase == Player.Finish and
      table.find(U.GetFriends(player.room, player), function (p)
        return not p.faceup
      end) and
      #U.GetEnemies(player.room, player) > 0
  end,
  on_cost = function(self, event, target, player, data)
    local to = player.room:askForChoosePlayers(player, table.map(U.GetEnemies(player.room, player), Util.IdMapper), 1, 1,
      "#jiange__huodi-choose", self.name, true)
    if #to > 0 then
      self.cost_data = to[1]
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    player.room:getPlayerById(self.cost_data):turnOver()
  end,
}
local jiange__jueji = fk.CreateTriggerSkill{
  name = "jiange__jueji",
  anim_type = "control",
  frequency = Skill.Compulsory,
  events = {fk.DrawNCards},
  can_trigger = function (self, event, target, player, data)
    return player:hasSkill(self) and table.contains(U.GetEnemies(player.room, player), target) and target:isWounded() and data.n > 0
  end,
  on_use = function (self, event, target, player, data)
    player.room:doIndicate(player.id, {target.id})
    data.n = data.n - 1
  end,
}
zhanghe:addSkill(jiange__huodi)
zhanghe:addSkill(jiange__jueji)
Fk:loadTranslationTable{
  ["jiange__zhanghe"] = "巧魁儁乂",
  ["#jiange__zhanghe"] = "巧魁儁乂",
  ["illustrator:jiange__zhanghe"] = "小北风巧绘",

  ["jiange__huodi"] = "惑敌",
  [":jiange__huodi"] = "结束阶段，若有友方角色武将牌背面朝上，你可以令一名敌方角色翻面。",
  ["jiange__jueji"] = "绝汲",
  [":jiange__jueji"] = "锁定技，敌方角色摸牌阶段，若其已受伤，你令其少摸一张牌。",
  ["#jiange__huodi-choose"] = "惑敌：你可以令一名敌方角色翻面",
}

local zhangliao = General(extension, "jiange__zhangliao", "wei", 5)
zhangliao.hidden = true
zhangliao.jiange_hero = true
local jiange__jiaoxie = fk.CreateActiveSkill{
  name = "jiange__jiaoxie",
  anim_type = "control",
  card_num = 0,
  min_target_num = 1,
  max_target_num = 2,
  prompt = "#jiange__jiaoxie",
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, to_select, selected)
    local target = Fk:currentRoom():getPlayerById(to_select)
    return #selected < 2 and table.contains(U.GetEnemies(Fk:currentRoom(), Self), target) and
      Fk.generals[target.general].jiange_machine and not target:isNude()
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    room:sortPlayersByAction(effect.tos)
    for _, id in ipairs(effect.tos) do
      if player.dead then return end
      local target = room:getPlayerById(id)
      if not target.dead and not target:isNude() then
        local card = room:askForCard(target, 1, 1, true, self.name, false, nil, "#jiange__jiaoxie-give:"..player.id)
        room:moveCardTo(card, Card.PlayerHand, player, fk.ReasonGive, self.name, nil, false, target.id)
      end
    end
  end,
}
local jiange__shuailing = fk.CreateTriggerSkill{
  name = "jiange__shuailing",
  anim_type = "support",
  frequency = Skill.Compulsory,
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self) and target.phase == Player.Draw and table.contains(U.GetFriends(player.room, player), target)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:doIndicate(player.id, {target.id})
    local judge = {
      who = target,
      reason = self.name,
      pattern = ".|.|spade,club",
      skipDrop = true,
    }
    room:judge(judge)
    if not target.dead and judge.card.color == Card.Black and room:getCardArea(judge.card) == Card.Processing then
      room:moveCardTo(judge.card, Card.PlayerHand, target, fk.ReasonJustMove, self.name, nil, true, target.id)
      return
    end
    if room:getCardArea(judge.card) == Card.Processing then
      room:moveCardTo(judge.card, Card.DiscardPile, nil, fk.ReasonJustMove, self.name, nil, true)
    end
  end,
}
zhangliao:addSkill(jiange__jiaoxie)
zhangliao:addSkill(jiange__shuailing)
Fk:loadTranslationTable{
  ["jiange__zhangliao"] = "百计文远",
  ["#jiange__zhangliao"] = "百计文远",
  --["illustrator:jiange__zhangliao"] = "",

  ["jiange__jiaoxie"] = "缴械",
  [":jiange__jiaoxie"] = "出牌阶段限一次，你可以令至多两名敌方攻城器械各交给你一张牌。",
  ["jiange__shuailing"] = "帅令",
  [":jiange__shuailing"] = "锁定技，友方角色摸牌阶段开始时，其进行一次判定，若结果为黑色，其获得判定牌。",
  ["#jiange__jiaoxie"] = "缴械：令至多两名敌方攻城器械各交给你一张牌",
  ["#jiange__jiaoxie-give"] = "缴械：你须交给 %src 一张牌",
}

local xiahoudun = General(extension, "jiange__xiahoudun", "wei", 5)
xiahoudun.hidden = true
xiahoudun.jiange_hero = true
local jiange__bashi = fk.CreateTriggerSkill{
  name = "jiange__bashi",
  anim_type = "defensive",
  events = {fk.TargetConfirmed},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and data.from ~= player.id and
      (data.card:isCommonTrick() or data.card.trueName == "slash") and player.faceup
  end,
  on_cost = function (self, event, target, player, data)
    return player.room:askForSkillInvoke(player, self.name, nil, "#jiange__bashi-invoke:::"..data.card:toLogString())
  end,
  on_use = function(self, event, target, player, data)
    player:turnOver()
    table.insertIfNeed(data.nullifiedTargets, player.id)
  end,
}
local jiange__danjing = fk.CreateTriggerSkill{
  name = "jiange__danjing",
  anim_type = "support",
  events = {fk.AskForPeaches},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self) and target.dying and table.contains(U.GetFriends(player.room, player, false), target) and
      player.hp > 1
  end,
  on_cost = function (self, event, target, player, data)
    return player.room:askForSkillInvoke(player, self.name, nil, "#jiange__danjing-invoke::"..target.id)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:loseHp(player, 1, self.name)
    if not target.dead then
      room:useVirtualCard("peach", nil, player, target, self.name)
    end
  end,
}
local jiange__tongjun = fk.CreateAttackRangeSkill{
  name = "jiange__tongjun",
  frequency = Skill.Compulsory,
  correct_func = function (self, from, to)
    return #table.filter(Fk:currentRoom().alive_players, function (p)
      return p:hasSkill(self) and Fk.generals[from.general].jiange_machine and
        table.contains(U.GetFriends(Fk:currentRoom(), p), from)
    end)
  end,
}
xiahoudun:addSkill(jiange__bashi)
xiahoudun:addSkill(jiange__danjing)
xiahoudun:addSkill(jiange__tongjun)
Fk:loadTranslationTable{
  ["jiange__xiahoudun"] = "枯目元让",
  ["#jiange__xiahoudun"] = "枯目元让",
  --["illustrator:jiange__xiahoudun"] = "",

  ["jiange__bashi"] = "拔矢",
  [":jiange__bashi"] = "当你成为其他角色使用【杀】或普通锦囊牌的目标后，你可以将武将牌翻至背面朝上，令此牌对你无效。",
  ["jiange__danjing"] = "啖睛",
  [":jiange__danjing"] = "其他友方角色处于濒死状态时，若你的体力值大于1，你可以失去1点体力，视为你对其使用一张【桃】。",
  ["jiange__tongjun"] = "统军",
  [":jiange__tongjun"] = "锁定技，友方攻城器械攻击范围+1。",
  ["#jiange__bashi-invoke"] = "拔矢：你可以翻面，令此%arg对你无效",
  ["#jiange__danjing-invoke"] = "啖睛：是否失去1点体力，视为对 %dest 使用【桃】？",
}

local dianwei = General(extension, "jiange__dianwei", "wei", 5)
dianwei.hidden = true
dianwei.jiange_hero = true
local jiange__yingji = fk.CreateActiveSkill{
  name = "jiange__yingji",
  anim_type = "offensive",
  prompt = "#jiange__yingji",
  card_num = 0,
  min_target_num = 1,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0 and not player:isKongcheng()
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, to_select, selected)
    local card = Fk:cloneCard("slash")
    card.skillName = self.name
    return card.skill:targetFilter(to_select, selected, {}, card, {bypass_times = true})
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local cards = player:getCardIds("h")
    local types = {}
    for _, id in ipairs(cards) do
      table.insertIfNeed(types, Fk:getCardById(id).type)
    end
    player:showCards(cards)
    local card = Fk:cloneCard("slash")
    card.skillName = self.name
    local use = {
      from = player.id,
      tos = table.map(effect.tos, function(id) return {id} end),
      card = card,
      extra_data = {jiange__yingji = #types},
      extraUse = true,
    }
    room:useCard(use)
  end,
}
local jiange__yingji_delay = fk.CreateTriggerSkill{
  name = "#jiange__yingji_delay",
  mute = true,
  events = {fk.DamageCaused},
  can_trigger = function(self, event, target, player, data)
    if target and target == player and data.card and table.contains(data.card.skillNames, "jiange__yingji") then
      local room = player.room
      local use_event = room.logic:getCurrentEvent():findParent(GameEvent.UseCard)
      if use_event then
        local use = use_event.data[1]
        if use.extra_data and use.extra_data.jiange__yingji then
          self.cost_data = use.extra_data.jiange__yingji
          return true
        end
      end
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    data.damage = self.cost_data
  end,
}
local jiange__zhene = fk.CreateTriggerSkill{
  name = "jiange__zhene",
  anim_type = "offensive",
  frequency = Skill.Compulsory,
  events = {fk.TargetSpecified},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase == Player.Play and
      (data.card.type == Card.TypeBasic or data.card:isCommonTrick()) and
      player.room:getPlayerById(data.to):getHandcardNum() <= player:getHandcardNum()
  end,
  on_use = function(self, event, target, player, data)
    data.disresponsiveList = data.disresponsiveList or {}
    table.insert(data.disresponsiveList, data.to)
  end,
}
local jiange__weizhu = fk.CreateTriggerSkill{
  name = "jiange__weizhu",
  anim_type = "defensive",
  events = {fk.DamageInflicted},
  can_trigger = function(self, _, target, player, data)
    return player:hasSkill(self) and table.contains(U.GetFriends(player.room, player), target) and not player:isKongcheng()
  end,
  on_cost  = function(self, event, target, player, data)
    local card = player.room:askForDiscard(player, 1, 1, false, self.name, true, nil, "#jiange__weizhu-invoke::"..target.id, true)
    if #card > 0 then
      self.cost_data = card
      return true
    end
  end,
  on_use  = function(self, event, target, player, data)
    local room = player.room
    room:doIndicate(player.id, {target.id})
    room:throwCard(self.cost_data, self.name, player, player)
    return true
  end,
}
jiange__yingji:addRelatedSkill(jiange__yingji_delay)
dianwei:addSkill(jiange__yingji)
dianwei:addSkill(jiange__zhene)
dianwei:addSkill(jiange__weizhu)
Fk:loadTranslationTable{
  ["jiange__dianwei"] = "古之恶来",
  ["#jiange__dianwei"] = "古之恶来",
  ["illustrator:jiange__dianwei"] = "鬼画府",

  ["jiange__yingji"] = "影戟",
  [":jiange__yingji"] = "出牌阶段限一次，你可以展示所有手牌，视为使用一张【杀】，此【杀】造成伤害时，将伤害值改为X（X为你展示牌的类别数）。",
  ["jiange__zhene"] = "震恶",
  [":jiange__zhene"] = "锁定技，当你于出牌阶段使用牌指定目标后，若目标角色手牌数不大于你，其不能响应。",
  ["jiange__weizhu"] = "卫主",
  [":jiange__weizhu"] = "当友方角色受到伤害时，你可以弃置一张手牌，防止此伤害。",
  ["#jiange__yingji"] = "影戟：你可以展示所有手牌，视为使用一张【杀】，此【杀】伤害值改为展示牌类别数",
  ["#jiange__yingji_delay"] = "影戟",
  ["#jiange__weizhu-invoke"] = "卫主：你可以弃置一张手牌，防止 %dest 受到的伤害",
}

local qinglong = General(extension, "jiange__qinglong", "shu", 5)
qinglong.hidden = true
qinglong.jiange_machine = true
local jiange__mojian = fk.CreateTriggerSkill{
  name = "jiange__mojian",
  anim_type = "offensive",
  frequency = Skill.Compulsory,
  events = {fk.EventPhaseStart},
  can_trigger = function (self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase == Player.Play and
      table.find(U.GetEnemies(player.room, player), function (p)
        return not player:isProhibited(p, Fk:cloneCard("archery_attack"))
      end)
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    local tos = {}
    for _, p in ipairs(room:getOtherPlayers(player)) do
      if table.contains(U.GetEnemies(room, player), p) and not player:isProhibited(p, Fk:cloneCard("archery_attack")) then
        table.insert(tos, p)
      end
    end
    room:useVirtualCard("archery_attack", nil, player, tos, self.name)
  end,
}
local jiange__jiguan = fk.CreateProhibitSkill{
  name = "jiange__jiguan",
  frequency = Skill.Compulsory,
  is_prohibited = function(self, from, to, card)
    return to:hasSkill(self) and card and card.name == "indulgence"
  end,
}
qinglong:addSkill(jiange__mojian)
qinglong:addSkill(jiange__jiguan)
Fk:loadTranslationTable{
  ["jiange__qinglong"] = "云屏青龙",
  ["#jiange__qinglong"] = "云屏青龙",

  ["jiange__jiguan"] = "机关",
  [":jiange__jiguan"] = "锁定技，你不能成为【乐不思蜀】的目标。",
  ["jiange__mojian"] = "魔箭",
  [":jiange__mojian"] = "锁定技，出牌阶段开始时，你视为对所有敌方角色使用一张【万箭齐发】。",
}

local baihu = General(extension, "jiange__baihu", "shu", 5)
baihu.hidden = true
baihu.jiange_machine = true
local jiange__zhenwei = fk.CreateDistanceSkill{
  name = "jiange__zhenwei",
  frequency = Skill.Compulsory,
  correct_func = function(self, from, to)
    return #table.filter(Fk:currentRoom().alive_players, function (p)
      return p:hasSkill(self) and
        table.contains(U.GetEnemies(Fk:currentRoom(), p), from) and table.contains(U.GetFriends(Fk:currentRoom(), p, false), to)
    end)
  end,
}
local jiange__benlei = fk.CreateTriggerSkill{
  name = "jiange__benlei",
  anim_type = "offensive",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase == Player.Start and
      table.find(U.GetEnemies(player.room, player), function (p)
        return Fk.generals[p.general].jiange_machine
      end)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = table.filter(U.GetEnemies(room, player), function (p)
      return Fk.generals[p.general].jiange_machine
    end)
    local to = room:askForChoosePlayers(player, table.map(targets, Util.IdMapper), 1, 1,
      "#jiange__benlei-choose", self.name, true)
    if #to > 0 then
      self.cost_data = to[1]
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:damage({
      from = player,
      to = room:getPlayerById(self.cost_data),
      damage = 2,
      damageType = fk.ThunderDamage,
      skillName = self.name,
    })
  end,
}
baihu:addSkill(jiange__zhenwei)
baihu:addSkill(jiange__benlei)
baihu:addSkill("jiange__jiguan")
Fk:loadTranslationTable{
  ["jiange__baihu"] = "机雷白虎",
  ["#jiange__baihu"] = "机雷白虎",

  ["jiange__zhenwei"] = "镇卫",
  [":jiange__zhenwei"] = "锁定技，敌方角色计算与其他友方角色距离+1。",
  ["jiange__benlei"] = "奔雷",
  [":jiange__benlei"] = "准备阶段，你可以对一名敌方攻城器械造成2点雷电伤害。",
  ["#jiange__benlei-choose"] = "奔雷：你可以对一名敌方攻城器械造成2点雷电伤害",
}

local zhuque = General(extension, "jiange__zhuque", "shu", 5, 5, General.Female)
zhuque.hidden = true
zhuque.jiange_machine = true
local jiange__tianyun = fk.CreateTriggerSkill{
  name = "jiange__tianyun",
  anim_type = "offensive",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase == Player.Finish
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askForSkillInvoke(player, self.name, nil, "#jiange__tianyun-invoke")
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:loseHp(player, 1, self.name)
    if player.dead or #U.GetEnemies(room, player) == 0 then return end
    local to = room:askForChoosePlayers(player, table.map(U.GetEnemies(room, player), Util.IdMapper), 1, 1,
      "#jiange__tianyun-choose", self.name, false)
    to = room:getPlayerById(to[1])
    room:damage({
      from = player,
      to = to,
      damage = 2,
      damageType = fk.FireDamage,
      skillName = self.name,
    })
    if not to.dead then
      to:throwAllCards("e")
    end
  end,
}
zhuque:addSkill(jiange__tianyun)
zhuque:addSkill("jiange__yuhuo")
zhuque:addSkill("jiange__jiguan")
Fk:loadTranslationTable{
  ["jiange__zhuque"] = "炽羽朱雀",
  ["#jiange__zhuque"] = "炽羽朱雀",

  ["jiange__tianyun"] = "天陨",
  [":jiange__tianyun"] = "结束阶段，你可以失去1点体力，然后对一名敌方角色造成2点火焰伤害并弃置其装备区内所有牌。",
  ["#jiange__tianyun-invoke"] = "天陨：你可以失去1点体力，然后对一名敌方角色造成2点火焰伤害并弃置其装备区内所有牌",
  ["#jiange__tianyun-choose"] = "天陨：对一名敌方角色造成2点火焰伤害并弃置其装备区内所有牌",
}

local xuanwu = General(extension, "jiange__xuanwu", "shu", 5)
xuanwu.hidden = true
xuanwu.jiange_machine = true
local jiange__lingyu = fk.CreateTriggerSkill{
  name = "jiange__lingyu",
  anim_type = "support",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase == Player.Finish
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askForSkillInvoke(player, self.name, nil, "#jiange__lingyu-invoke")
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:doIndicate(player.id, table.map(U.GetFriends(room, player, false), Util.IdMapper))
    player:turnOver()
    for _, p in ipairs(room:getOtherPlayers(player)) do
      if not p.dead and table.contains(U.GetFriends(room, player), p) and p:isWounded() then
        room:recover({
          who = p,
          num = 1,
          recoverBy = player,
          skillName = self.name,
        })
      end
    end
  end,
}
xuanwu:addSkill("yizhong")
xuanwu:addSkill("jiange__jiguan")
xuanwu:addSkill(jiange__lingyu)
Fk:loadTranslationTable{
  ["jiange__xuanwu"] = "灵甲玄武",
  ["#jiange__xuanwu"] = "灵甲玄武",

  ["jiange__lingyu"] = "灵愈",
  [":jiange__lingyu"] = "结束阶段，你可以翻面，然后令其他友方角色各回复1点体力。",
  ["#jiange__lingyu-invoke"] = "灵愈：是否翻面，令其他友方角色各回复1点体力？",
}

local bihan = General(extension, "jiange__bihan", "wei", 5)
bihan.hidden = true
bihan.jiange_machine = true
local jiange__didong = fk.CreateTriggerSkill{
  name = "jiange__didong",
  anim_type = "control",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase == Player.Finish and
      #U.GetEnemies(player.room, player) > 0
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askForSkillInvoke(player, self.name, nil, "#jiange__didong-invoke")
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = table.random(U.GetEnemies(room, player))
    room:doIndicate(player.id, {to.id})
    to:turnOver()
  end,
}
bihan:addSkill(jiange__didong)
bihan:addSkill("jiange__jiguan")
Fk:loadTranslationTable{
  ["jiange__bihan"] = "缚地狴犴",
  ["#jiange__bihan"] = "缚地狴犴",

  ["jiange__didong"] = "地动",
  [":jiange__didong"] = "结束阶段，你可以令随机一名敌方角色翻面。",
  ["#jiange__didong-invoke"] = "地动：是否令随机一名敌方角色翻面？",
}

local suanni = General(extension, "jiange__suanni", "wei", 4)
suanni.hidden = true
suanni.jiange_machine = true
local jiange__lianyu = fk.CreateTriggerSkill{
  name = "jiange__lianyu",
  anim_type = "offensive",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase == Player.Finish and
      #U.GetEnemies(player.room, player) > 0
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askForSkillInvoke(player, self.name, nil, "#jiange__lianyu-invoke")
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:doIndicate(player.id, table.map(U.GetEnemies(room, player), Util.IdMapper))
    player:turnOver()
    for _, p in ipairs(room:getOtherPlayers(player)) do
      if table.contains(U.GetEnemies(room, player), p) and not p.dead then
        room:damage({
          from = player,
          to = p,
          damage = 1,
          damageType = fk.FireDamage,
          skillName = self.name,
        })
      end
    end
  end,
}
suanni:addSkill("jiange__jiguan")
suanni:addSkill(jiange__lianyu)
Fk:loadTranslationTable{
  ["jiange__suanni"] = "食火狻猊",
  ["#jiange__suanni"] = "食火狻猊",

  ["jiange__lianyu"] = "炼狱",
  [":jiange__lianyu"] = "结束阶段，你可以翻面，对所有敌方角色各造成1点火焰伤害。",
  ["#jiange__lianyu-invoke"] = "炼狱：是否翻面并对所有敌方角色各造成1点火焰伤害？",
}

local chiwen = General(extension, "jiange__chiwen", "wei", 6)
chiwen.hidden = true
chiwen.jiange_machine = true
local jiange__tanshi = fk.CreateTriggerSkill{
  name = "jiange__tanshi",
  anim_type = "negative",
  frequency = Skill.Compulsory,
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase == Player.Finish and not player:isKongcheng()
  end,
  on_use = function(self, event, target, player, data)
    player.room:askForDiscard(player, 1, 1, false, self.name, false)
  end,
}
local jiange__tunshi = fk.CreateTriggerSkill{
  name = "jiange__tunshi",
  anim_type = "offensive",
  frequency = Skill.Compulsory,
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase == Player.Start and
      table.find(U.GetEnemies(player.room, player), function (p)
        return p:getHandcardNum() > player:getHandcardNum()
      end)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local targets = table.filter(U.GetEnemies(room, player), function (p)
      return p:getHandcardNum() > player:getHandcardNum()
    end)
    room:doIndicate(player.id, table.map(targets, Util.IdMapper))
    for _, p in ipairs(room:getOtherPlayers(player)) do
      if table.contains(targets, p) and not p.dead then
        room:damage({
          from = player,
          to = p,
          damage = 1,
          skillName = self.name,
        })
      end
    end
  end,
}
chiwen:addSkill("jiange__jiguan")
chiwen:addSkill(jiange__tanshi)
chiwen:addSkill(jiange__tunshi)
Fk:loadTranslationTable{
  ["jiange__chiwen"] = "吞天螭吻",
  ["#jiange__chiwen"] = "吞天螭吻",

  ["jiange__tanshi"] = "贪食",
  [":jiange__tanshi"] = "锁定技，结束阶段，你弃置一张手牌。",
  ["jiange__tunshi"] = "吞噬",
  [":jiange__tunshi"] = "锁定技，准备阶段，你对所有手牌数大于你的敌方角色各造成1点伤害。",
}

local yazi = General(extension, "jiange__yazi", "wei", 6)
yazi.hidden = true
yazi.jiange_machine = true
local jiange__nailuo = fk.CreateTriggerSkill{
  name = "jiange__nailuo",
  anim_type = "control",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase == Player.Finish
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askForSkillInvoke(player, self.name, nil, "#jiange__nailuo-invoke")
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:doIndicate(player.id, table.map(U.GetEnemies(room, player), Util.IdMapper))
    player:turnOver()
    for _, p in ipairs(room:getOtherPlayers(player)) do
      if table.contains(U.GetEnemies(room, player), p) and not p.dead then
        p:throwAllCards("e")
      end
    end
  end,
}
yazi:addSkill("jiange__jiguan")
yazi:addSkill(jiange__nailuo)
Fk:loadTranslationTable{
  ["jiange__yazi"] = "裂石睚眦",
  ["#jiange__yazi"] = "裂石睚眦",

  ["jiange__nailuo"] = "奈落",
  [":jiange__nailuo"] = "结束阶段，你可以翻面，令所有敌方角色依次弃置其装备区内所有牌。",
  ["#jiange__nailuo-invoke"] = "奈落：是否翻面，令所有敌方角色弃置装备区内所有牌？",
}

return extension
