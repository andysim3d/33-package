-- SPDX-License-Identifier: GPL-3.0-or-later
local extension = Package("gamemode_generals")
extension.extensionName = "gamemode"

local U = require "packages/utility/utility"

Fk:loadTranslationTable{
  ["gamemode_generals"] = "模式专属武将",
  ["v33"] = "3v3",
  ["v22"] = "2v2",
  ["v11"] = "1v1",
  ["vd"] = "忠胆",
  ["var"] = "应变",
}

local zombie = General(extension, "zombie", "god", 1)
zombie.hidden = true
local xunmeng = fk.CreateTriggerSkill{
  name = "zombie_xunmeng",
  anim_type = "offensive",
  frequency = Skill.Compulsory,
  events = {fk.DamageCaused},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and data.card and data.card.trueName == "slash"
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    data.damage = data.damage + 1
    if player.hp > 1 then
      room:loseHp(player, 1, self.name)
    end
  end,
}
local zaibian = fk.CreateTriggerSkill{
  name = "zombie_zaibian",
  anim_type = "drawcard",
  frequency = Skill.Compulsory,
  events = {fk.DrawNCards},
  can_trigger = function(self, event, target, player, data)
    if not (player == target and player:hasSkill(self)) then return end
    local room = player.room
    local human = #table.filter(room.alive_players, function(p)
      return p.role == "lord" or p.role == "loyalist"
    end)
    local zombie = #room.alive_players - human
    return human - zombie + 1 > 0
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local human = #table.filter(room.alive_players, function(p)
      return p.role == "lord" or p.role == "loyalist"
    end)
    local zombie = #room.alive_players - human
    data.n = data.n + (human - zombie + 1)
  end,
}
local ganran = fk.CreateFilterSkill{
  name = "zombie_ganran",
  card_filter = function(self, to_select, player)
    return player:hasSkill(self) and to_select.type == Card.TypeEquip and
    table.contains(player.player_cards[Player.Hand], to_select.id)
  end,
  view_as = function(self, to_select)
    local card = Fk:cloneCard("iron_chain", to_select.suit, to_select.number)
    card.skillName = self.name
    return card
  end,
}
zombie:addSkill("ex__paoxiao")
zombie:addSkill("ol_ex__wansha")
zombie:addSkill(xunmeng)
zombie:addSkill(zaibian)
zombie:addSkill(ganran)
Fk:loadTranslationTable{
  ["zombie"] = "僵尸",
  ["zombie_xunmeng"] = "迅猛",
  [":zombie_xunmeng"] = "锁定技，你的【杀】造成伤害时，令此伤害+1，若此时你的体力值大于1，则你失去1点体力。",
  ["zombie_zaibian"] = "灾变",
  [":zombie_zaibian"] = "锁定技，摸牌阶段，若X大于0，则你多摸X张牌（X为人类玩家数-僵尸玩家数+1）。",
  ["zombie_ganran"] = "感染",
  [":zombie_ganran"] = "锁定技，你手牌中的装备牌视为【铁锁连环】。",
}

local hiddenone = General(extension, "hiddenone", "jin", 1)
hiddenone.hidden = true
Fk:loadTranslationTable{
  ["hiddenone"] = "隐匿",
}

local v33__zhugejin = General(extension, "v33__zhugejin", "wu", 3)
v33__zhugejin.hidden = true
local v33__huanshi = fk.CreateTriggerSkill{
  name = "v33__huanshi",
  anim_type = "support",
  events = {fk.AskForRetrial},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self) and table.contains(U.GetFriends(player.room, player), target) and not player:isNude()
  end,
  on_cost = function(self, event, target, player, data)
    local card = player.room:askForResponse(player, self.name, ".", "#v33__huanshi-invoke::"..target.id, true)
    if card ~= nil then
      self.cost_data = card
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    player.room:retrial(self.cost_data, player, data, self.name)
  end,
}
local v33__hongyuan = fk.CreateTriggerSkill{
  name = "v33__hongyuan",
  anim_type = "support",
  events = {fk.DrawNCards},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and data.n > 0
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    data.n = data.n - 1
  end,
}
local v33__hongyuan_trigger = fk.CreateTriggerSkill{
  name = "#v33__hongyuan_trigger",
  mute = true,
  events = {fk.EventPhaseEnd},
  can_trigger = function(self, event, target, player, data)
    return target == player and player.phase == Player.Draw and player:usedSkillTimes("v33__hongyuan", Player.HistoryPhase) > 0
  end,
  on_use = function(self, event, target, player, data)
    for _, p in ipairs(U.GetFriends(player.room, player, false)) do
      if not p.dead then
        player.room:doIndicate(player.id, {p.id})
        p:drawCards(1, "v33__hongyuan")
      end
    end
  end,
}
v33__hongyuan:addRelatedSkill(v33__hongyuan_trigger)
v33__zhugejin:addSkill(v33__huanshi)
v33__zhugejin:addSkill(v33__hongyuan)
v33__zhugejin:addSkill("mingzhe")
Fk:loadTranslationTable{
  ["v33__zhugejin"] = "诸葛瑾",
  ["v33__huanshi"] = "缓释",
  [":v33__huanshi"] = "当己方角色的判定牌生效前，你可以打出一张牌代替之。",
  ["v33__hongyuan"] = "弘援",
  [":v33__hongyuan"] = "摸牌阶段，你可以少摸一张牌，若如此做，其他己方角色各摸一张牌。",
  ["#v33__huanshi-invoke"] = "缓释：是否打出一张牌修改 %dest 的判定牌？",
}

Fk:loadTranslationTable{
  ["v33__wenpin"] = "文聘",
  ["v33__zhenwei"] = "镇卫",
  [":v33__zhenwei"] = "锁定技，对方角色计算与己方角色的距离+1。",
}

Fk:loadTranslationTable{
  ["v33__huangquan"] = "黄权",
  ["v33__choujin"] = "筹进",
  [":v33__choujin"] = "锁定技，分发起始手牌前，你指定一名其他角色。当己方角色对该角色造成伤害后，该己方角色摸一张牌。",
  ["v33__zhongjian"] = "忠谏",
  [":v33__zhongjian"] = "出牌阶段限一次，你可以交给一名己方角色一张牌，然后你摸一张牌。",
}

Fk:loadTranslationTable{
  ["v33__xiahoudun"] = "夏侯惇",
  ["v33__ganglie"] = "刚烈",
  [":v33__ganglie"] = "当你受到伤害后，你可以选择一名对方角色，然后判定，若结果不为<font color='red'>♥</font>，其选择一项：1.弃置两张手牌；"..
  "2.你对其造成1点伤害。",
}

Fk:loadTranslationTable{
  ["v33__guanyu"] = "关羽",
  ["v33__zhongyi"] = "忠义",
  [":v33__zhongyi"] = "出牌阶段，若你没有“义”，你可以将任意张红色牌置为“义”。当己方角色使用【杀】对对方角色造成伤害时，你移去一张“义”，令此伤害+1。",
}

Fk:loadTranslationTable{
  ["v33__xusheng"] = "徐盛",
  ["v33__yicheng"] = "疑城",
  [":v33__yicheng"] = "当己方角色成为敌方角色使用【杀】的目标后，你可以令其摸一张牌，然后其弃置一张手牌；若弃置的是装备牌，则改为其使用之。",
}

local v33__lvbu = General(extension, "v33__lvbu", "qun", 4)
local v33__zhanshen = fk.CreateTriggerSkill{
  name = "v33__zhanshen",
  anim_type = "special",
  frequency = Skill.Compulsory,
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(self) and player.phase == Player.Start then
      for i = 1, 3, 1 do
        if player:getMark("v33__zhanshen_"..i) == 0 then
          return true
        end
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local choices = table.map(table.filter({1, 2, 3}, function(n)
      return player:getMark("v33__zhanshen_"..n) == 0
    end), function(n)
      return "v33__zhanshen_"..n
    end)
    local choice = room:askForChoice(player, choices, self.name, "#v33__zhanshen-choice")
    room:setPlayerMark(player, choice, 1)
  end,
}
local v33__zhanshen_trigger = fk.CreateTriggerSkill{
  name = "#v33__zhanshen_trigger",
  mute = true,
  events = {fk.DrawNCards, fk.PreCardUse, fk.AfterCardTargetDeclared},
  can_trigger = function (self, event, target, player, data)
    if target == player then
      if event == fk.DrawNCards then
        return player:getMark("v33__zhanshen_1") > 0
      elseif event == fk.PreCardUse then
        return player:getMark("v33__zhanshen_2") > 0 and data.card.trueName == "slash"
      elseif event == fk.AfterCardTargetDeclared then
        return player:getMark("v33__zhanshen_3") > 0 and data.card.trueName == "slash" and
          #U.getUseExtraTargets(player.room, data, false) > 0
      end
    end
  end,
  on_cost = function (self, event, target, player, data)
    if event == fk.DrawNCards or event == fk.PreCardUse then
      return true
    elseif event == fk.AfterCardTargetDeclared then
      local targets = U.getUseExtraTargets(player.room, data, false)
      local tos = player.room:askForChoosePlayers(player, targets, 1, 1,
        "#v33__zhanshen-choose:::"..data.card:toLogString(), "v33__zhanshen", true)
      if #tos > 0 then
        self.cost_data = tos
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke("v33__zhanshen")
    if event == fk.DrawNCards then
      room:notifySkillInvoked(player, "v33__zhanshen", "drawcard")
      data.n = data.n + 1
    elseif event == fk.PreCardUse then
      room:notifySkillInvoked(player, "v33__zhanshen", "offensive")
      data.additionalDamage = (data.additionalDamage or 0) + 1
    elseif event == fk.AfterCardTargetDeclared then
      room:notifySkillInvoked(player, "v33__zhanshen", "offensive")
      table.insert(data.tos, self.cost_data)
    end
  end,
}
v33__zhanshen:addRelatedSkill(v33__zhanshen_trigger)
v33__lvbu:addSkill(v33__zhanshen)
Fk:loadTranslationTable{
  ["v33__lvbu"] = "吕布",
  ["v33__zhanshen"] = "战神",
  [":v33__zhanshen"] = "锁定技，准备阶段，你选择一项未获得过的效果，获得此效果直到本局游戏结束：<br>"..
  "1.摸牌阶段，你多摸一张牌；<br>2.你使用【杀】造成伤害+1；<br>3.你使用【杀】可以额外选择一个目标。",
  ["#v33__zhanshen-choice"] = "战神：选择一项效果，本局游戏永久获得",
  ["v33__zhanshen_1"] = "摸牌阶段多摸一张牌",
  ["v33__zhanshen_2"] = "使用【杀】伤害+1",
  ["v33__zhanshen_3"] = "使用【杀】可以额外选择一个目标",
  ["#v33__zhanshen-choose"] = "战神：你可以为此%arg增加一个目标",

  ["$v33__zhanshen1"] = "战神降世，神威再临！",
  ["$v33__zhanshen2"] = "战神既出，谁与争锋！",
  ["~v33__lvbu"] = "不可能！",
}

local v11__niujin = General(extension, "v11__niujin", "wei", 4)
v11__niujin.hidden = true
local v11__cuorui = fk.CreateTriggerSkill{
  name = "v11__cuorui",
  anim_type = "drawcard",
  frequency = Skill.Compulsory,
  events = {"fk.Debut", fk.EventPhaseChanging},
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(self) then
      if event == "fk.Debut" then
        return #player.room:getBanner(player.role == "lord" and "@&firstGenerals" or "@&secondGenerals") - 2 > 0
      else
        return data.to == Player.Judge and player:getMark("_v11__cuorui") == 0
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == "fk.Debut" then
      player:drawCards(#room:getBanner(player.role == "lord" and "@&firstGenerals" or "@&secondGenerals") - 2, self.name)
    else
      room:setPlayerMark(player, "_v11__cuorui", 1)
      return true
    end
  end,
}
local v11__liewei = fk.CreateTriggerSkill{
  name = "v11__liewei",
  anim_type = "drawcard",
  events = {fk.Death},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self) and data.damage and data.damage.from and data.damage.from == player and player ~= target
  end,
  on_use = function(self, event, target, player, data)
    player:drawCards(3, self.name)
  end,
}
v11__niujin:addSkill(v11__cuorui)
v11__niujin:addSkill(v11__liewei)
Fk:loadTranslationTable{
  ["v11__niujin"] = "牛金",
  ["v11__cuorui"] = "挫锐",
  [":v11__cuorui"] = "锁定技，当你登场时，你摸X-2张牌（X为你的备用武将数）；你跳过登场后的第一个判定阶段。",
  ["v11__liewei"] = "裂围",
  [":v11__liewei"] = "当你杀死对手的角色后，你可以摸三张牌。",

  ["$v11__cuorui1"] = "区区乌合之众，如何困得住我？！",
  ["$v11__cuorui2"] = "今日就让你见识见识老牛的厉害！",
  ["$v11__liewei1"] = "敌阵已乱，速速突围！",
  ["$v11__liewei2"] = "杀你，如同捻死一只蚂蚁！",
  ["~v11__niujin"] = "这包围圈太厚，老牛，尽力了……",
}

Fk:loadTranslationTable{
  ["v11__hejin"] = "何进",
  ["v11__mouzhu"] = "谋诛",
  [":v11__mouzhu"] = "出牌阶段限一次，你可以令对手交给你一张手牌，然后若其手牌数小于你，其选择视为对你使用【杀】或【决斗】。",
  ["v11__yanhuo"] = "延祸",
  [":v11__yanhuo"] = "当你死亡时，你可以依次弃置对手X张牌（X为你的牌数）。",
}

Fk:loadTranslationTable{
  ["v11__hansui"] = "韩遂",
  ["v11__xiaoxi"] = "骁袭",
  [":v11__xiaoxi"] = "当你登场时，你可以视为使用一张【杀】。",
  ["v11__niluan"] = "逆乱",
  [":v11__niluan"] = "对手的结束阶段，若其体力值大于你，或其本回合对你使用过【杀】，你可以将一张黑色牌当【杀】对其使用。",
}

--张辽 许褚 甄姬 夏侯渊 刘备 关羽 马超 黄月英 魏延 姜维 孟获 祝融 孙权 甘宁 吕蒙 大乔 孙尚香 貂蝉 华佗 庞德

Fk:loadTranslationTable{
  ["v11__liubei"] = "刘备",
  ["v11__renwang"] = "仁望",
  [":v11__renwang"] = "当对手于其出牌阶段内对你使用【杀】或普通锦囊牌时，若本阶段你已成为过上述牌的目标，你可以弃置其一张牌。",
}

Fk:loadTranslationTable{
  ["v11__xiangchong"] = "向宠",
  ["v11__changjun"] = "畅军",
  [":v11__changjun"] = "出牌阶段开始时，你可以将至多X张牌置于你的武将牌上（X为你的登场角色序数），若如此做，直到你下回合开始，你可以将与“畅军”牌"..
  "花色相同的牌当【杀】或【闪】使用或打出；准备阶段，你获得所有“畅军”牌。",
  ["v11__aibing"] = "哀兵",
  [":v11__aibing"] = "当你死亡时，你可以令你下一名武将登场时视为使用一张【杀】。",
}

local v11__sunyi = General(extension, "v11__sunyi", "wu", 4)
v11__sunyi.hidden = true
local v11__guolie = fk.CreateTriggerSkill{
  name = "v11__guolie",
  anim_type = "offensive",
  events = {fk.CardEffectCancelledOut},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and data.card.trueName == "slash"
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local card = Fk:getCardById(room:getNCards(1)[1])
    room:moveCardTo(card, Card.Processing, nil, fk.ReasonJustMove)
    if U.canUseCard(room, player, card, true) then
      player.special_cards["v11__guolie"] = {card.id}
      player:doNotify("ChangeSelf", json.encode {
        id = player.id,
        handcards = player:getCardIds("h"),
        special_cards = player.special_cards,
      })
      room:setPlayerMark(player, "v11__guolie_card", card.id)
      local success, dat = room:askForUseActiveSkill(player, "v11__guolie_vs", "#v11__guolie-use:::" .. card:toLogString(), false)
      room:setPlayerMark(player, "v11__guolie_card", 0)
      player.special_cards["v11__guolie"] = {}
      player:doNotify("ChangeSelf", json.encode {
        id = player.id,
        handcards = player:getCardIds("h"),
        special_cards = player.special_cards,
      })
      if success then
        local c = Fk.skills["v11__guolie_vs"]:viewAs(dat.cards)
        room:useCard{
          from = player.id,
          tos = table.map(dat.targets, function(id) return {id} end),
          card = c,
          extraUse = true,
        }
      end
    elseif card.trueName == "slash" then
      room:obtainCard(player, card)
    end
  end,
}
local v11__guolie_vs = fk.CreateViewAsSkill{
  name = "v11__guolie_vs",
  expand_pile = "v11__guolie",
  card_filter = function(self, to_select, selected)
    if #selected == 0 then
      return Self:getMark("v11__guolie_card") == to_select
    end
  end,
  view_as = function(self, cards)
    if #cards == 1 then
      return Fk:getCardById(cards[1])
    end
  end,
}
Fk:addSkill(v11__guolie_vs)
v11__sunyi:addSkill(v11__guolie)
Fk:loadTranslationTable{
  ["v11__sunyi"] = "孙翊",
  ["v11__guolie"] = "果烈",
  [":v11__guolie"] = "当你使用【杀】被【闪】抵消时，你可以亮出牌堆顶牌，若你：可以使用此牌，则使用之；不能使用且为【杀】，你获得之。",
  ["v11__hunbi"] = "魂弼",
  [":v11__hunbi"] = "当你死亡时，若对手的流放区未饱和，你可以令你下一名武将登场时选择一项：1.视为使用一张【杀】；2.摸一张牌；3.对对手执行至多两次流放。",

  ["#v11__guolie-use"] = "果烈：你使用 %arg",
  ["v11__guolie_vs"] = "果烈",
}

Fk:loadTranslationTable{
  ["v11__duosidawang"] = "朵思大王",
  ["v11__mihuo"] = "迷惑",
  [":v11__mihuo"] = "对手使用的锦囊牌结算完毕进入弃牌堆时，你可以将之置于你的武将牌上。对手不能使用与“迷惑”同名的牌。",
  ["v11__fanshu"] = "反术",
  [":v11__fanshu"] = "出牌阶段限一次，你可以将一张“迷惑”牌当任意一张“迷惑”牌使用。",
}

local v11__zhuyi = General(extension, "v11__zhuyi", "qun", 4)
v11__zhuyi.hidden = true
local v11__chengji = fk.CreateTriggerSkill{
  name = "v11__chengji",
  anim_type = "masochism",
  events = {fk.Damage, fk.Damaged},
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(self) and data.card and #player:getPile(self.name) < 4 then
      local room = player.room
      local subcards = Card:getIdList(data.card)
      return #subcards > 0 and table.every(subcards, function(id) return room:getCardArea(id) == Card.Processing end)
    end
  end,
  on_use = function(self, event, target, player, data)
    player:addToPile(self.name, data.card, true, self.name)
  end,
}
local v11__chengji_trigger = fk.CreateTriggerSkill{
  name = "#v11__chengji_trigger",
  mute = true,
  events = {fk.Death, "fk.Debut"},
  can_trigger = function(self, event, target, player, data)
    if target == player then
      if event == fk.Death then
        return #player:getPile("v11__chengji") > 0 and player.room.settings.gameMode == "m_1v1_mode"
      else
        return player.room:getTag("v11__chengji"..player.id) ~= nil
      end
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.Death then
      room:setTag("v11__chengji"..player.id, table.simpleClone(player:getPile("v11__chengji")))
      local dummy = Fk:cloneCard("dilu")
      dummy:addSubcards(player:getPile("v11__chengji"))
      room:moveCardTo(dummy, Card.Void, nil, fk.ReasonJustMove, "v11__chengji", nil, true, player.id)
    else
      local dummy = Fk:cloneCard("dilu")
      dummy:addSubcards(table.simpleClone(room:getTag("v11__chengji"..player.id)))
      room:removeTag("v11__chengji"..player.id)
      room:moveCardTo(dummy, Card.PlayerHand, player, fk.ReasonJustMove, "v11__chengji", nil, true, player.id)
    end
  end,
}
v11__chengji:addRelatedSkill(v11__chengji_trigger)
v11__zhuyi:addSkill(v11__chengji)
Fk:loadTranslationTable{
  ["v11__zhuyi"] = "注诣",
  ["v11__chengji"] = "城棘",
  [":v11__chengji"] = "当你造成或受到伤害后，若“城棘”牌少于四张，你可以将造成伤害的牌置于你的武将牌上。你死亡后，你的下一名武将登场时获得所有“城棘”牌。",
}

local v22__leitong = General(extension, "v22__leitong", "shu", 4)
local v22__kuiji = fk.CreateActiveSkill{
  name = "v22__kuiji",
  anim_type = "offensive",
  target_num = 0,
  card_num = 1,
  prompt = "#v22__kuiji",
  can_use = function(self, player)
    return player:usedSkillTimes(self.name) == 0 and not player:hasDelayedTrick("supply_shortage")
  end,
  card_filter = function(self, to_select, selected)
    return #selected == 0 and Fk:getCardById(to_select).type == Card.TypeBasic and Fk:getCardById(to_select).color == Card.Black
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local card = Fk:cloneCard("supply_shortage")
    card:addSubcards(effect.cards)
    card.skillName = self.name
    player:addVirtualEquip(card)
    room:moveCardTo(card, Player.Judge, player, fk.ReasonJustMove, self.name)
    if player.dead then return end
    player:drawCards(1, self.name)
    local targets = table.map(table.filter(U.GetEnemies(room, player), function(p)
      return table.every(U.GetEnemies(room, player), function(p2)
        return p.hp >= p2.hp
      end)
    end), Util.IdMapper)
    local to = room:askForChoosePlayers(player, targets, 1, 1, "#v22__kuiji-damage", self.name, true)
    if #to > 0 then
      room:damage{
        from = player,
        to = room:getPlayerById(to[1]),
        damage = 2,
        skillName = self.name,
      }
    end
  end,
}
local v22__kuiji_trigger = fk.CreateTriggerSkill{
  name = "#v22__kuiji_trigger",
  mute = true,
  events = {fk.EnterDying},
  can_trigger = function(self, event, target, player, data)
    return data.damage and data.damage.skillName == "v22__kuiji" and data.damage.from and data.damage.from == player
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local targets = table.map(table.filter(U.GetFriends(room, player), function(p)
      return table.every(U.GetFriends(room, player), function(p2)
        return p.hp <= p2.hp and p:isWounded()
      end)
    end), Util.IdMapper)
    if #targets == 0 then return end
    local to = targets[1]
    if #targets > 1 then
      to = room:askForChoosePlayers(player, targets, 1, 1, "#v22__kuiji-recover", "v22__kuiji", false, true)[1]
    end
    room:doIndicate(player.id, {to})
    room:recover({
      who = room:getPlayerById(to),
      num = 1,
      recoverBy = player,
      skillName = "v22__kuiji"
    })
  end,
}
v22__kuiji:addRelatedSkill(v22__kuiji_trigger)
v22__leitong:addSkill(v22__kuiji)
Fk:loadTranslationTable{
  ["v22__leitong"] = "雷铜",
  ["v22__kuiji"] = "溃击",
  [":v22__kuiji"] = "出牌阶段限一次，你可以将一张黑色基本牌当作【兵粮寸断】置于你的判定区，然后摸一张牌。若如此做，你可以对体力值最多的一名敌方角色"..
  "造成2点伤害，其因此进入濒死状态时，体力值最少的一名友方角色回复1点体力。",
  ["#v22__kuiji"] = "溃击：将一张黑色基本牌当【兵粮寸断】置于你的判定区并摸一张牌，然后对一名体力最多的敌方造成2点伤害",
  ["#v22__kuiji-damage"] = "溃击：你可以对体力值最多的一名敌方造成2点伤害",
  ["#v22__kuiji-recover"] = "溃击：令体力值最少的一名友方回复1点体力",

  ["$v22__kuiji1"] = "绝域奋击，孤注一掷。",
  ["$v22__kuiji2"] = "舍得一身剐，不畏君王威。",
  ["~v22__leitong"] = "翼德救我……",
}

Fk:loadTranslationTable{
  ["v22__wulan"] = "吴兰",
  ["v22__cuoruiw"] = "挫锐",
  [":v22__cuoruiw"] = "出牌阶段开始时，你可以弃置一名友方角色区域内的一张牌。若如此做，你选择一项：1.弃置敌方角色装备区内至多两张与此牌颜色相同的牌；"..
  "2.展示敌方角色共计两张手牌，然后获得其中与此牌颜色相同的牌。",
}

local v22__jianggan = General(extension, "v22__jianggan", "wei", 3)
local v22__daoshu = fk.CreateTriggerSkill{
  name = "v22__daoshu",
  mute = true,
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self) and table.contains(U.GetEnemies(player.room, player), target) and target.phase == Player.Play and
      not target.dead and not target:isKongcheng() and player:usedSkillTimes(self.name, Player.HistoryRound) == 0
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askForSkillInvoke(player, self.name, nil, "#v22__daoshu-invoke::"..target.id)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke(self.name, 1)
    room:notifySkillInvoked(player, self.name, "control")
    room:doIndicate(player.id, {target.id})
    room:useVirtualCard("analeptic", nil, target, target, self.name, false)
    if player.dead or target.dead then return end
    local names = {}
    for _, id in ipairs(Fk:getAllCardIds()) do
      local card = Fk:getCardById(id)
      if card.type == Card.TypeBasic then
        table.insertIfNeed(names, card.name)
      end
    end
    local choice = room:askForChoice(target, names, self.name, "#v22__daoshu-declare:"..player.id)
    room:doBroadcastNotify("ShowToast", Fk:translate(target.general)..Fk:translate("#v22__daoshu")..Fk:translate(choice))
    local yes = room:askForChoice(player, {"yes", "no"}, self.name, "#v22__daoshu-choice::"..target.id..":"..choice)
    local right = table.find(target:getCardIds("h"), function(id) return Fk:getCardById(id).trueName == choice end)
    if ((yes == "yes" and right) or (yes == "no" and not right)) then
      if not target:isKongcheng() then
        player:broadcastSkillInvoke(self.name, 2)
        local dummy = Fk:cloneCard("dilu")
        dummy:addSubcards(table.random(target:getCardIds("h"), 2))
        room:moveCardTo(dummy, Card.PlayerHand, player, fk.ReasonPrey, self.name, nil, false, player.id)
      end
    else
      player:broadcastSkillInvoke(self.name, 3)
    end
  end,
}
local v22__daizui = fk.CreateTriggerSkill{
  name = "v22__daizui",
  anim_type = "defensive",
  frequency = Skill.Limited,
  events = {fk.DamageInflicted},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and data.damage >= player.hp and
      player:usedSkillTimes(self.name, Player.HistoryGame) == 0
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if data.from and not data.from.dead and data.card then
      local subcards = data.card:isVirtual() and data.card.subcards or {data.card.id}
      if #subcards > 0 and table.every(subcards, function(id) return room:getCardArea(id) == Card.Processing end) then
        room:doIndicate(player.id, {data.from.id})
        player:addToPile("v22__jianggan_shi", data.card, true, self.name)
        local turn = room.logic:getCurrentEvent():findParent(GameEvent.Round)
        if turn ~= nil then
          turn:addCleaner(function()
            if not data.from.dead and #data.from:getPile("v22__jianggan_shi") > 0 then
              local dummy = Fk:cloneCard("dilu")
              dummy:addSubcards(data.from:getPile("v22__jianggan_shi"))
              room:moveCardTo(dummy, Card.PlayerHand, data.from, fk.ReasonJustMove, self.name, nil, true, data.from.id)
            end
          end)
        end
      end
    end
    return true
  end,
}
v22__jianggan:addSkill(v22__daoshu)
v22__jianggan:addSkill(v22__daizui)
Fk:loadTranslationTable{
  ["v22__jianggan"] = "蒋干",
  ["v22__daoshu"] = "盗书",
  [":v22__daoshu"] = "每轮限一次，敌方角色的出牌阶段开始时，若其有手牌，你可以令其视为使用一张【酒】，并令其声明其手牌中有一种基本牌，你判断真假。"..
  "若判断正确，则你随机获得其两张手牌。",
  ["v22__daizui"] = "戴罪",
  [":v22__daizui"] = "限定技，当你受到致命伤害时，你可以防止之，然后将造成伤害的牌置于伤害来源的武将牌上，称为“释”。本回合结束后，其获得所有“释”。",
  ["#v22__daoshu-invoke"] = "盗书：令 %dest 视为使用【酒】，然后猜测其手牌中是否有其声明的基本牌，若猜对你获得其两张手牌",
  ["#v22__daoshu-declare"] = "盗书：声明你有某种基本牌，令 %src 猜测",
  ["#v22__daoshu"] = "声明其手牌中有 ",
  ["#v22__daoshu-choice"] = "盗书：猜测 %dest 手中是否有【%arg】？若猜对你获得其两张手牌",
  ["v22__jianggan_shi"] = "释",

  ["$v22__daoshu1"] = "在此机要之地，何不一窥东吴军机？",
  ["$v22__daoshu2"] = "哦？密信……果然有所收获。",
  ["$v22__daoshu3"] = "啊？公，公瑾误会，误会矣！",
  ["$v22__daizui1"] = "望丞相权且记过，容干将功折罪啊！",
  ["$v22__daizui2"] = "干，谢丞相不杀之恩！",
  ["~v22__jianggan"] = "唉！假信害我不浅啊！",
}

local huangfusong = General(extension, "vd__huangfusong", "qun", 4)
local vd__fenyue = fk.CreateActiveSkill{
  name = "vd__fenyue",
  anim_type = "offensive",
  card_num = 0,
  target_num = 1,
  can_use = function(self, player)
    return not player:isKongcheng() and player:usedSkillTimes(self.name, Player.HistoryPhase) < player:getMark(self.name)
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, to_select, selected)
    return #selected == 0 and to_select ~= Self.id and Self:canPindian(Fk:currentRoom():getPlayerById(to_select))
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    local pindian = player:pindian({target}, self.name)
    if pindian.results[target.id].winner == player then
      if player:prohibitUse(Fk:cloneCard("slash")) or player:isProhibited(target, Fk:cloneCard("slash")) or room:askForChoice(player, {"vd__fenyue_slash", "vd__fenyue_prohibit"}, self.name) == "vd__fenyue_prohibit" then
        room:setPlayerMark(target, "@@vd__fenyue-turn", 1)
      else
        room:useVirtualCard("slash", nil, player, target, self.name, true)
      end
    else
      player:endPlayPhase()
    end
  end,
}
local vd__fenyue_record = fk.CreateTriggerSkill{
  name = "#vd__fenyue_record",
  refresh_events = {fk.GameStart, fk.BeforeGameOverJudge, fk.EventAcquireSkill},
  can_refresh = function(self, event, target, player, data)
    if event == fk.EventAcquireSkill then
      return target == player and data == self and player.room:getTag("RoundCount")
    end
    return player:hasSkill(vd__fenyue, true)
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    room:setPlayerMark(player, "vd__fenyue", #table.filter(room.alive_players, function(p) return p.role == "loyalist" end))
  end,
}
vd__fenyue:addRelatedSkill(vd__fenyue_record)
local vd__fenyue_prohibit = fk.CreateProhibitSkill{
  name = "#vd__fenyue_prohibit",
  prohibit_use = function(self, player, card)
    if player:getMark("@@vd__fenyue-turn") > 0 then
      local subcards = card:isVirtual() and card.subcards or {card.id}
      return #subcards > 0 and table.every(subcards, function(id)
        return table.contains(player.player_cards[Player.Hand], id)
      end)
    end
  end,
  prohibit_response = function(self, player, card)
    if player:getMark("@@vd__fenyue-turn") > 0 then
      local subcards = card:isVirtual() and card.subcards or {card.id}
      return #subcards > 0 and table.every(subcards, function(id)
        return table.contains(player.player_cards[Player.Hand], id)
      end)
    end
  end,
}
vd__fenyue:addRelatedSkill(vd__fenyue_prohibit)
huangfusong:addSkill(vd__fenyue)
Fk:loadTranslationTable{
  ["vd__huangfusong"] = "皇甫嵩",
  ["#vd__huangfusong"] = "志定雪霜",
  ["illustrator:vd__huangfusong"] = "秋呆呆",
  ["vd__fenyue"] = "奋钺",
  [":vd__fenyue"] = "出牌阶段限X次，你可以与一名角色拼点，若你赢，你选择一项：1.其不能使用或打出手牌直到回合结束；2.视为你对其使用了不计入次数的【杀】。若你没赢，你结束出牌阶段(X为存活的忠臣数)。",
  ["vd__fenyue_slash"] = "视为对其使用【杀】",
  ["vd__fenyue_prohibit"] = "本回合禁止其使用/打出手牌",
  ["@@vd__fenyue-turn"] = "被奋钺",
}



local var__yangyan = General(extension, "var__yangyan", "jin", 3, 3, General.Female)
local nos__xuanbei = fk.CreateTriggerSkill{
  name = "nos__xuanbei",
  anim_type = "support",
  events = {fk.GameStart, fk.CardUseFinished},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self) then
      if event == fk.GameStart then
        return true
      elseif event == fk.CardUseFinished then
        return target == player and not data.card:isVirtual() and
          table.find({"@fujia", "@kongchao", "@canqu", "@zhuzhan"}, function(mark) return data.card:getMark(mark) ~= 0 end) and
          player.room:getCardArea(data.card.id) == Card.Processing and
          player:usedSkillTimes(self.name, Player.HistoryTurn) == 0
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    if event == fk.GameStart then
      return true
    elseif event == fk.CardUseFinished then
      local to = player.room:askForChoosePlayers(player, table.map(player.room:getOtherPlayers(player), function(p)
        return p.id end), 1, 1, "#nos__xuanbei-give:::"..data.card:toLogString(), self.name, true)
      if #to > 0 then
        self.cost_data = to[1]
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.GameStart then
      local cards = {}
      for _, id in ipairs(room.draw_pile) do
        if table.find({"@fujia", "@kongchao", "@canqu", "@zhuzhan"}, function(mark) return Fk:getCardById(id):getMark(mark) ~= 0 end) then
          table.insert(cards, id)
        end
      end
      local dummy = Fk:cloneCard("dilu")
      if #cards > 0 then
        dummy:addSubcards(table.random(cards, 2))
      else  --没有就印两张！
        local card1 = room:printCard("drowning", Card.Spade, 3)
        room:setCardMark(card1, "@zhuzhan", Fk:translate("variation_addtarget"))
        dummy:addSubcard(card1.id)
        local card2 = room:printCard("savage_assault", Card.Spade, 13)
        room:setCardMark(card2, "@fujia", Fk:translate("variation_minustarget"))
        dummy:addSubcard(card2.id)
      end
      room:moveCardTo(dummy, Card.PlayerHand, player, fk.ReasonJustMove, self.name, nil, false, player.id)
    elseif event == fk.CardUseFinished then
      room:moveCardTo(data.card, Card.PlayerHand, room:getPlayerById(self.cost_data), fk.ReasonGive, self.name, nil, true, player.id)
    end
  end,
}
var__yangyan:addSkill(nos__xuanbei)
var__yangyan:addSkill("xianwan")
Fk:loadTranslationTable{
  ["var__yangyan"] = "杨艳",
  ["#var__yangyan"] = "武元皇后",
  ["illustrator:var__yangyan"] = "张艺骞",
  ["nos__xuanbei"] = "选备",
  [":nos__xuanbei"] = "游戏开始时，你获得两张带有应变效果的牌。每回合限一次，当你使用带有应变效果的牌结算后，你可以将之交给一名其他角色。",
  ["#nos__xuanbei-give"] = "选备：你可以将 %arg 交给一名其他角色",

  ["$nos__xuanbei1"] = "男胤有德色，愿陛下以备六宫。",
  ["$nos__xuanbei2"] = "广集良家，召充选者使吾拣择。",
  ["$xianwan_var__yangyan1"] = "姿容娴婉，服饰华光。",
  ["$xianwan_var__yangyan2"] = "有美一人，清扬婉兮。",
  ["~var__yangyan"] = "后承前训，奉述遗芳……",
}

local var__yangzhi = General(extension, "var__yangzhi", "jin", 3, 3, General.Female)
local nos__wanyi = fk.CreateViewAsSkill{
  name = "nos__wanyi",
  prompt = "#nos__wanyi",
  interaction = function()
    local all_names = {"chasing_near", "unexpectation", "drowning", "foresight"}
    local names = table.simpleClone(all_names)
    for _, name in ipairs(all_names) do
      if table.contains(U.getMark(Self, "nos__wanyi-turn"), name) then
        table.removeOne(names, name)
      end
    end
    if #names == 0 then return end
    return UI.ComboBox {choices = names, all_choices = all_names,}
  end,
  card_filter = function (self, to_select, selected)
    return #selected == 0 and table.find({"@fujia", "@kongchao", "@canqu", "@zhuzhan"}, function(mark)
      return Fk:getCardById(to_select):getMark(mark) ~= 0 end)
  end,
  before_use = function (self, player, use)
    local mark = U.getMark(player, "nos__wanyi-turn")
    table.insert(mark, use.card.name)
    player.room:setPlayerMark(player, "nos__wanyi-turn", mark)
  end,
  view_as = function(self, cards)
    if #cards ~= 1 or not self.interaction.data then return end
    local card = Fk:cloneCard(self.interaction.data)
    card:addSubcard(cards[1])
    card.skillName = self.name
    return card
  end,
}
var__yangzhi:addSkill(nos__wanyi)
var__yangzhi:addSkill("maihuo")
Fk:loadTranslationTable{
  ["var__yangzhi"] = "杨芷",
  ["#var__yangzhi"] = "武悼皇后",
  ["illustrator:var__yangzhi"] = "张艺骞",
  ["nos__wanyi"] = "婉嫕",
  [":nos__wanyi"] = "出牌阶段每种牌名限一次，你可以将一张带有应变效果的牌当【逐近弃远】、【出其不意】、【水淹七军】或【洞烛先机】使用。",
  ["#nos__wanyi"] = "婉嫕：你可以将一张带有应变效果的牌当一种应变篇锦囊使用",

  ["$nos__wanyi1"] = "婉嫕而淑慎，位居正室。",
  ["$nos__wanyi2"] = "为后需备贞静之德、婉嫕之操。",
  ["$maihuo_var__yangzhi1"] = "至亲约束不严，祸根深埋。",
  ["$maihuo_var__yangzhi2"] = "闻祸端而不备，可亡矣。",
  ["~var__yangzhi"] = "姊妹继宠，福极灾生……",
}








return extension
