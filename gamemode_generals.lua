-- SPDX-License-Identifier: GPL-3.0-or-later
local extension = Package("gamemode_generals")
extension.extensionName = "gamemode"

local U = require "packages/utility/utility"

Fk:loadTranslationTable{
  ["gamemode_generals"] = "模式专属武将",
  ["v33"] = "3v3",
  ["v11"] = "1v1",
}

local zombie = General(extension, "zombie", "god", 1)
zombie.hidden = true
local xunmeng = fk.CreateTriggerSkill{
  name = "zombie_xunmeng",
  anim_type = "offensive",
  frequency = Skill.Compulsory,
  events = {fk.DamageCaused},
  can_trigger = function(self, event, target, player, data)
    if target ~= player or not player:hasSkill(self) then
      return
    end

    local c = data.card
    return c and c.trueName == "slash"
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
      not table.contains(player.player_cards[Player.Equip], to_select.id) and
      not table.contains(player.player_cards[Player.Judge], to_select.id)
      -- table.contains(player.player_cards[Player.Hand], to_select.id) --不能用getCardArea！
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
  [":zombie_xunmeng"] = "锁定技，你的【杀】造成伤害时，令此伤害+1，" ..
    "若此时你的体力值大于1，则你失去1点体力。",
  ["zombie_zaibian"] = "灾变",
  [":zombie_zaibian"] = "锁定技，摸牌阶段，若人类玩家数-僵尸玩家数+1大于0，则你多摸该数目的牌。",
  ["zombie_ganran"] = "感染",
  [":zombie_ganran"] = "锁定技，你手牌中的装备牌视为【铁锁连环】。",
}

local v33__zhugejin = General(extension, "v33__zhugejin", "wu", 3)
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
  [":v33__ganglie"] = "当你受到伤害后，你可以选择一名对方角色，然后判定，若结果不为♥，其选择一项：1.弃置两张手牌；2.你对其造成1点伤害。",
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

Fk:loadTranslationTable{
  ["v33__lvbu"] = "吕布",
  ["v33__zhanshen"] = "战神",
  [":v33__zhanshen"] = "锁定技，准备阶段，你选择一项未获得过的效果，获得此效果直到本局游戏结束：<br>"..
  "1.摸牌阶段，你多摸一张牌；<br>2.你使用【杀】造成伤害+1；<br>3.你使用【杀】可以额外选择一个目标。",
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
        return true
      else
        return data.to == Player.Judge and player:getMark("@@v11__cuorui") > 0
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == "fk.Debut" then
      player:drawCards(#room:getTag("1v1_generals")[player.seat] - 2, self.name)
    else
      room:setPlayerMark(player, "@@v11__cuorui", 0)
      player:skip(Player.Judge)
      return true
    end
  end,
}
local v11__liewei = fk.CreateTriggerSkill{
  name = "v11__liewei",
  anim_type = "drawcard",
  events = {fk.Death},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self) and data.damage and data.damage.from and data.damage.from == player
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

--张辽 许褚 甄姬 夏侯渊 刘备 关羽 马超 黄月英 魏延 姜维 孟获 祝融 孙权 甘宁 吕蒙 大乔 孙尚香 貂蝉 庞德 华佗

Fk:loadTranslationTable{
  ["v11__xiangchong"] = "向宠",
  ["v11__changjun"] = "畅军",
  [":v11__changjun"] = "出牌阶段开始时，你可以将至多X张牌置于你的武将牌上（X为你的登场角色序数），若如此做，直到你下回合开始，你可以将与“畅军”牌"..
  "花色相同的牌当【杀】或【闪】使用或打出；准备阶段，你获得所有“畅军”牌。",
  ["v11__aibing"] = "哀兵",
  [":v11__aibing"] = "当你死亡时，你可以令你下一名武将登场时视为使用一张【杀】。",
}

Fk:loadTranslationTable{
  ["v11__sunyi"] = "孙翊",
  ["v11__guolie"] = "果烈",
  [":v11__guolie"] = "当你使用【杀】被【闪】抵消时，你可以亮出牌堆顶牌，若你：可以使用此牌，则使用之；不能使用且为【杀】，你获得之。",
  ["v11__hunbi"] = "魂弼",
  [":v11__hunbi"] = "当你死亡时，若对手的流放区未饱和，你可以令你下一名武将登场时选择一项：1.视为使用一张【杀】；2.摸一张牌；3.对对手执行至多两次流放。",
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
      local subcards = data.card:isVirtual() and data.card.subcards or {data.card.id}
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

return extension
