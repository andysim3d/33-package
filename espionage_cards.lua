-- SPDX-License-Identifier: GPL-3.0-or-later

local extension = Package:new("espionage_cards", Package.CardPack)
extension.extensionName = "gamemode"
extension.game_modes_blacklist = {"m_1v1_mode", "m_1v2_mode", "m_2v2_mode", "zombie_mode", "heg_mode"}

local U = require "packages/utility/utility"

Fk:loadTranslationTable{
  ["espionage_cards"] = "用间",
}

local PresentCards = {}
local function addPreasentCard(c)
  extension:addCard(c)
  table.insert(PresentCards, c)
end

addPreasentCard(Fk:cloneCard("slash", Card.Heart, 5))
addPreasentCard(Fk:cloneCard("slash", Card.Heart, 10))
addPreasentCard(Fk:cloneCard("slash", Card.Heart, 11))
addPreasentCard(Fk:cloneCard("slash", Card.Heart, 12))

local slash = Fk:cloneCard("slash")
local stabSlashSkill = fk.CreateActiveSkill{
  name = "stab__slash_skill",
  max_phase_use_time = 1,
  target_num = 1,
  can_use = slash.skill.canUse,
  mod_target_filter = slash.skill.modTargetFilter,
  target_filter = slash.skill.targetFilter,
  on_effect = slash.skill.onEffect,
}
local stab__slash_trigger = fk.CreateTriggerSkill{
  name = "stab__slash_trigger",
  global = true,
  mute = true,
  events = {fk.CardEffectCancelledOut},
  can_trigger = function(self, event, target, player, data)
    return data.card.name == "stab__slash" and data.to == player.id and not player.dead and not player:isKongcheng()
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local card = room:askForDiscard(player, 1, 1, false, self.name, true, ".", "#stab__slash-discard:::"..data.card:toLogString(), true)
    if #card == 0 then
      return true
    else
      room:throwCard(card, self.name, player, player)
    end
  end,
}
Fk:addSkill(stab__slash_trigger)
local stabSlash = fk.CreateBasicCard{
  name = "stab__slash",
  skill = stabSlashSkill,
  is_damage_card = true,
}
extension:addCards{
  stabSlash:clone(Card.Spade, 6),
  stabSlash:clone(Card.Spade, 7),
  stabSlash:clone(Card.Spade, 8),
  stabSlash:clone(Card.Club, 2),
  stabSlash:clone(Card.Club, 6),
  stabSlash:clone(Card.Club, 7),
  stabSlash:clone(Card.Club, 8),
  stabSlash:clone(Card.Club, 9),
  stabSlash:clone(Card.Club, 10),
  stabSlash:clone(Card.Diamond, 13),
}
Fk:loadTranslationTable{
  ["stab__slash"] = "刺杀",
  ["stab__slash_trigger"] = "刺杀",
  [":stab__slash"] = "基本牌<br/><b>时机</b>：出牌阶段<br/><b>目标</b>：攻击范围内的一名角色<br/><b>效果</b>：对目标角色造成1点伤害。"..
  "当目标角色使用【闪】抵消刺【杀】时，若其有手牌，其需弃置一张手牌，否则此刺【杀】依然造成伤害。",
  ["#stab__slash-discard"] = "请弃置一张手牌，否则%arg依然对你生效",
}

addPreasentCard(Fk:cloneCard("jink", Card.Heart, 2))
addPreasentCard(Fk:cloneCard("jink", Card.Diamond, 2))
extension:addCards{
  Fk:cloneCard("jink", Card.Diamond, 5),
  Fk:cloneCard("jink", Card.Diamond, 6),
  Fk:cloneCard("jink", Card.Diamond, 7),
  Fk:cloneCard("jink", Card.Diamond, 8),
  Fk:cloneCard("jink", Card.Diamond, 12),
  Fk:cloneCard("peach", Card.Heart, 7),
  Fk:cloneCard("peach", Card.Heart, 8),
}
addPreasentCard(Fk:cloneCard("peach", Card.Diamond, 11))

local poison_trigger = fk.CreateTriggerSkill{
  name = "poison_trigger",
  global = true,
  priority = 0.1,
  mute = true,
  events = {fk.AfterCardsMove},
  can_trigger = function(self, event, target, player, data)
    for _, move in ipairs(data) do
      if move.extra_data and move.extra_data.poison then
        if table.contains(move.extra_data.poison, player.id) and not player.dead then
          return true
        end
      end
      if move.to == player.id and move.toArea == Card.PlayerHand and move.moveReason == fk.ReasonDraw then
        for _, info in ipairs(move.moveInfo) do
          if Fk:getCardById(info.cardId).name == "es__poison" then
            return true
          end
        end
      end
    end
  end,
  on_trigger = function(self, event, target, player, data)
    local n = 0
    local ids = {}
    for _, move in ipairs(data) do
      if move.extra_data and move.extra_data.poison then
        n = n + #table.filter(move.extra_data.poison, function(id) return id == player.id end)
      end
      if move.to == player.id and move.toArea == Card.PlayerHand then
        for _, info in ipairs(move.moveInfo) do
          if Fk:getCardById(info.cardId).name == "es__poison" then
            table.insertIfNeed(ids, info.cardId)
          end
        end
      end
    end
    for i = 1, n, 1 do
      if not player.dead then
        player.room:loseHp(player, 1, "es__poison")
      end
    end
    ids = table.filter(ids, function(id) return table.contains(player:getCardIds("h"), id) end)
    while not player.dead and #ids > 0 do
      ids = table.filter(ids, function(id) return table.contains(player:getCardIds("h"), id) end)
      if #ids == 0 then break end
      if not self:doCost(event, nil, player, ids) then
        break
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    room:setPlayerMark(player, "es__poison-tmp", data)
    local success, dat = room:askForUseActiveSkill(player, "es__poison_give", "#es__poison-give", true)
    room:setPlayerMark(player, "es__poison-tmp", 0)
    if success then
      self.cost_data = dat
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(self.cost_data.targets[1])
    room:moveCardTo(self.cost_data.cards, Card.PlayerHand, to, fk.ReasonGive, "es__poison_give", nil, true, player.id)
  end,

  refresh_events = {fk.BeforeCardsMove},
  can_refresh = function(self, event, target, player, data)
    for _, move in ipairs(data) do
      if move.from == player.id then
        return true
      end
    end
  end,
  on_refresh = function(self, event, target, player, data)
    for _, move in ipairs(data) do
      if move.from == player.id and move.skillName ~= "es__poison_give" and move.skillName ~= "scrape_poison" then
        for _, info in ipairs(move.moveInfo) do
          if info.fromArea == Card.PlayerHand and (move.moveVisible or table.contains({2, 3, 5, 7}, move.toArea)) then
            if Fk:getCardById(info.cardId).name == "es__poison" then
              move.extra_data = move.extra_data or {}
              local dat = move.extra_data.poison or {}
              table.insert(dat, player.id)
              move.extra_data.poison = dat
            end
          end
        end
      end
    end
  end,
}
local es__poison_give = fk.CreateActiveSkill{
  name = "es__poison_give",
  min_card_num = 1,
  target_num = 1,
  card_filter = function(self, to_select, selected)
    return table.contains(Self:getMark("es__poison-tmp"), to_select)
  end,
  target_filter = function(self, to_select, selected)
    return #selected == 0 and to_select ~= Self.id
  end,
}
Fk:addSkill(es__poison_give)
Fk:addSkill(poison_trigger)
local esPoisonSkill = fk.CreateActiveSkill{
  name = "es__poison_skill",
  can_use = Util.FalseFunc,
}
local es__poison = fk.CreateBasicCard{
  name = "es__poison",
  skill = esPoisonSkill,
}
Fk:addSkill(esPoisonSkill)
addPreasentCard(es__poison:clone(Card.Spade, 4))
addPreasentCard(es__poison:clone(Card.Spade, 5))
addPreasentCard(es__poison:clone(Card.Spade, 9))
addPreasentCard(es__poison:clone(Card.Spade, 10))
extension:addCards({
  es__poison:clone(Card.Club, 4),
})
Fk:loadTranslationTable{
  ["es__poison"] = "毒",
  [":es__poison"] = "基本牌<br/><b>效果</b>：①当【毒】正面向上离开你的手牌区或作为你的拼点牌亮出后，你失去1点体力。②当你因摸牌获得【毒】后，"..
  "你可以将之交给一名其他角色，以此法失去【毒】时不触发失去体力效果。",
  ["es__poison_give"] = "",
  ["#es__poison-give"] = "你可以将摸到的【毒】交给其他角色（不触发失去体力效果）",
}

addPreasentCard(Fk:cloneCard("snatch", Card.Spade, 3))
addPreasentCard(Fk:cloneCard("duel", Card.Diamond, 1))
extension:addCards{
  Fk:cloneCard("nullification", Card.Spade, 11),
  Fk:cloneCard("nullification", Card.Club, 11),
  Fk:cloneCard("nullification", Card.Club, 12),
}
addPreasentCard(Fk:cloneCard("amazing_grace", Card.Heart, 3))

local bogusFlowerSkill = fk.CreateActiveSkill{
  name = "bogus_flower_skill",
  mod_target_filter = Util.TrueFunc,
  on_use = function(self, room, cardUseEvent)
    if not cardUseEvent.tos or #TargetGroup:getRealTargets(cardUseEvent.tos) == 0 then
      cardUseEvent.tos = { { cardUseEvent.from } }
    end
  end,
  on_effect = function(self, room, effect)
    local target = room:getPlayerById(effect.to)
    if target.dead or target:isNude() then return end
    local cards = room:askForDiscard(target, 1, 2, true, "bogus_flower", false, ".", "#bogus_flower-discard", true)
    if #cards == 0 then return end
    local n = #cards
    if table.find(cards, function(id) return Fk:getCardById(id).type == Card.TypeEquip end) then
      n = n + 1
    end
    room:throwCard(cards, "bogus_flower", target, target)
    if not target.dead then
      target:drawCards(n, "bogus_flower")
    end
  end
}
local bogus_flower = fk.CreateTrickCard{
  name = "bogus_flower",
  skill = bogusFlowerSkill,
}
addPreasentCard(bogus_flower:clone(Card.Diamond, 3))
addPreasentCard(bogus_flower:clone(Card.Diamond, 4))
Fk:loadTranslationTable{
  ["bogus_flower"] = "树上开花",
  ["bogus_flower_skill"] = "树上开花",
  [":bogus_flower"] = "锦囊牌<br/><b>时机</b>：出牌阶段<br/><b>目标</b>：你<br/><b>效果</b>：目标角色弃置至多两张牌，然后摸等量的牌；"..
  "若弃置了装备牌，则多摸一张牌。",
  ["#bogus_flower-discard"] = "树上开花：弃置一至两张牌，摸等量的牌，若弃置了装备牌则多摸一张",
}

local scrapePoisonSkill = fk.CreateActiveSkill{
  name = "scrape_poison_skill",
  target_num = 1,
  mod_target_filter = function(self, to_select, selected, user, card)
    return Fk:currentRoom():getPlayerById(to_select):isWounded()
  end,
  target_filter = function(self, to_select, selected, _, card)
    if #selected < self:getMaxTargetNum(Self, card) then
      return self:modTargetFilter(to_select, selected, Self.id, card)
    end
  end,
  on_effect = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.to)
    if target:isWounded() and not target.dead then
      room:recover({
        who = target,
        num = 1,
        card = effect.card,
        recoverBy = player,
        skillName = self.name
      })
    end
    if not target.dead and not target:isKongcheng() then
      room:askForDiscard(target, 1, 1, false, "scrape_poison", true, "poison", "#scrape_poison-discard")
    end
  end
}
local scrape_poison = fk.CreateTrickCard{
  name = "scrape_poison",
  skill = scrapePoisonSkill,
}
extension:addCards({
  scrape_poison:clone(Card.Spade, 1),
  scrape_poison:clone(Card.Heart, 1),
})
Fk:loadTranslationTable{
  ["scrape_poison"] = "刮骨疗毒",
  ["scrape_poison_skill"] = "刮骨疗毒",
  [":scrape_poison"] = "锦囊牌<br/><b>时机</b>：出牌阶段<br/><b>目标</b>：一名已受伤角色<br/><b>效果</b>：目标角色回复1点体力，然后其可以"..
  "弃置一张【毒】，以此法失去【毒】时不触发失去体力效果。",
  ["#scrape_poison-discard"] = "刮骨疗毒：你可以弃置一张【毒】（不触发失去体力效果）",
}

local snatch = Fk:cloneCard("snatch")
local sincereTreatSkill = fk.CreateActiveSkill{
  name = "sincere_treat_skill",
  distance_limit = 1,
  target_num = 1,
  mod_target_filter = snatch.skill.modTargetFilter,
  target_filter = snatch.skill.targetFilter,
  on_effect = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.to)
    if player.dead or target.dead or target:isAllNude() then return end
    local cards = room:askForCardsChosen(player, target, 1, 2, "hej", self.name)
    room:obtainCard(player, cards, false, fk.ReasonPrey)
    if not player.dead and not target.dead or player:isKongcheng() then
      local n = math.min(#cards, player:getHandcardNum())
      cards = room:askForCard(player, n, n, false, self.name, false, ".|.|.|hand", "#sincere_treat-give::"..target.id..":"..n)
      room:obtainCard(target, cards, false, fk.ReasonGive)
    end
  end
}
local sincere_treat = fk.CreateTrickCard{
  name = "sincere_treat",
  skill = sincereTreatSkill,
}
extension:addCards({
  sincere_treat:clone(Card.Diamond, 9),
  sincere_treat:clone(Card.Diamond, 10),
})
Fk:loadTranslationTable{
  ["sincere_treat"] = "推心置腹",
  ["sincere_treat_skill"] = "推心置腹",
  [":sincere_treat"] = "锦囊牌<br/><b>时机</b>：出牌阶段<br/><b>目标</b>：距离为1的一名区域内有牌的其他角色<br/><b>效果</b>：你获得目标角色"..
  "区域里至多两张牌，然后交给其等量的手牌。",
  ["#sincere_treat-give"] = "推心置腹：请交给 %dest %arg张手牌",
}

local lootingSkill = fk.CreateActiveSkill{
  name = "looting_skill",
  target_num = 1,
  mod_target_filter = function(self, to_select, selected, user, card, distance_limited)
    return to_select ~= user and not Fk:currentRoom():getPlayerById(to_select):isKongcheng()
  end,
  target_filter = function(self, to_select)
    return to_select ~= Self.id and not Fk:currentRoom():getPlayerById(to_select):isKongcheng()
  end,
  on_effect = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.to)
    if player.dead or target.dead or target:isKongcheng() then return end
    local id = room:askForCardChosen(player, target, "h", self.name)
    target:showCards(id)
    if player.dead or target.dead then return end
    if room:getCardOwner(id) == target and room:getCardArea(id) == Card.PlayerHand then
      if room:askForSkillInvoke(target, self.name, nil, "#looting-give:"..player.id.."::"..effect.card:toLogString()) then
        room:obtainCard(player, id, true, fk.ReasonGive, player.id, "looting")
      else
        room:damage({
          from = player,
          to = target,
          card = effect.card,
          damage = 1,
          skillName = self.name
        })
      end
    else
      room:damage({
        from = player,
        to = target,
        card = effect.card,
        damage = 1,
        skillName = self.name
      })
    end
  end
}
local looting = fk.CreateTrickCard{
  name = "looting",
  skill = lootingSkill,
  is_damage_card = true,
}
extension:addCards({
  looting:clone(Card.Spade, 12),
  looting:clone(Card.Spade, 13),
  looting:clone(Card.Heart, 6),
})
Fk:loadTranslationTable{
  ["looting"] = "趁火打劫",
  ["looting_skill"] = "趁火打劫",
  [":looting"] = "锦囊牌<br/><b>时机</b>：出牌阶段<br/><b>目标</b>：一名有手牌的其他角色<br/><b>效果</b>：你展示目标角色一张手牌，"..
  "然后令其选择一项：将此牌交给你，或受到你造成的1点伤害。",
  ["#looting-give"] = "趁火打劫：点“确定”将此牌交给 %src ，或点“取消”其对你造成1点伤害",
}

local broken_halberd = fk.CreateWeapon{
  name = "broken_halberd",
  suit = Card.Club,
  number = 1,
  attack_range = 0,
}
addPreasentCard(broken_halberd)
Fk:loadTranslationTable{
  ["broken_halberd"] = "折戟",
  [":broken_halberd"] = "装备牌·武器<br/><b>攻击范围</b>：0<br/>这是一把坏掉的武器……",
}

local sevenStarsPreciousSwordSkill = fk.CreateTriggerSkill{
  name = "#seven_stars_precious_sword_skill",
  attached_equip = "seven_stars_precious_sword",
  frequency = Skill.Compulsory,
}
Fk:addSkill(sevenStarsPreciousSwordSkill)
local seven_stars_precious_sword = fk.CreateWeapon{
  name = "seven_stars_precious_sword",
  suit = Card.Spade,
  number = 2,
  attack_range = 2,
  equip_skill = sevenStarsPreciousSwordSkill,
  on_install = function(self, room, player)
    if player:isAlive() and self.equip_skill:isEffectable(player) then
      local cards = player:getCardIds("ej")
      table.removeOne(cards, player:getEquipment(Card.SubtypeWeapon))
      room:throwCard(cards, "seven_stars_precious_sword", player, player)
    end
  end,
}
addPreasentCard(seven_stars_precious_sword)
Fk:loadTranslationTable{
  ["seven_stars_precious_sword"] = "七星宝刀",
  [":seven_stars_precious_sword"] = "装备牌·武器<br/><b>攻击范围</b>：2<br/><b>武器技能</b>：锁定技，当此牌进入你的装备区时，弃置你判定区和"..
  "装备区内除此牌外所有的牌。",
}

local yitianSwordSkill = fk.CreateTriggerSkill{
  name = "#yitian_sword_skill",
  attached_equip = "yitian_sword",
  events = {fk.Damage},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and data.card and data.card.trueName == "slash" and
      not player:isKongcheng()
  end,
  on_cost = function(self, event, target, player, data)
    local card = player.room:askForDiscard(player, 1, 1, false, self.name, true, ".", "#yitian_sword-invoke", true)
    if #card > 0 then
      self.cost_data = card
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:throwCard(self.cost_data, "yitian_sword", player, player)
    if not player.dead and player:isWounded() then
      room:recover({
        who = player,
        num = 1,
        recoverBy = player,
        skillName = "yitian_sword",
      })
    end
  end,
}
Fk:addSkill(yitianSwordSkill)
local yitian_sword = fk.CreateWeapon{
  name = "yitian_sword",
  suit = Card.Club,
  number = 5,
  attack_range = 2,
  equip_skill = yitianSwordSkill,
}
extension:addCard(yitian_sword)
Fk:loadTranslationTable{
  ["yitian_sword"] = "倚天剑",
  ["#yitian_sword_skill"] = "倚天剑",
  [":yitian_sword"] = "装备牌·武器<br/><b>攻击范围</b>：2<br/><b>武器技能</b>：当你使用【杀】造成伤害后，你可以弃置一张手牌，然后回复1点体力。",
  ["#yitian_sword-invoke"] = "倚天剑：你可以弃置一张手牌，回复1点体力",
}

local beeClothSkill = fk.CreateTriggerSkill{
  name = "#bee_cloth_skill",
  attached_equip = "bee_cloth",
  anim_type = "negative",
  frequency = Skill.Compulsory,
  events = {fk.DamageInflicted, fk.PreHpLost},
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(self) then
      if event == fk.DamageInflicted then
        return data.card and data.card.type == Card.TypeTrick
      elseif event == fk.PreHpLost then
        return data.skillName == "es__poison"
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    if event == fk.DamageInflicted then
      data.damage = data.damage + 1
    elseif event == fk.PreHpLost then
      data.num = data.num + 1
    end
  end,
}
Fk:addSkill(beeClothSkill)
local bee_cloth = fk.CreateArmor{
  name = "bee_cloth",
  suit = Card.Club,
  number = 3,
  equip_skill = beeClothSkill,
}
addPreasentCard(bee_cloth)
Fk:loadTranslationTable{
  ["bee_cloth"] = "引蜂衣",
  ["#bee_cloth_skill"] = "引蜂衣",
  [":bee_cloth"] = "装备牌·防具<br/><b>防具技能</b>：锁定技，你受到锦囊牌的伤害+1，因【毒】的效果失去体力+1。",
}

local womenDressSkill = fk.CreateTriggerSkill{
  name = "#women_dress_skill",
  attached_equip = "women_dress",
  anim_type = "negative",
  frequency = Skill.Compulsory,
  events = {fk.TargetConfirmed},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and (player.gender == General.Male or player.gender == General.Bigender) and
      data.card.trueName == "slash"
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local judge = {
      who = player,
      reason = self.name,
      pattern = ".|.|spade,club",
    }
    room:judge(judge)
    if judge.card.color == Card.Black then
      data.additionalDamage = (data.additionalDamage or 0) + 1
    end
  end,
}
Fk:addSkill(womenDressSkill)
local women_dress = fk.CreateArmor{
  name = "women_dress",
  suit = Card.Heart,
  number = 9,
  equip_skill = womenDressSkill,
}
addPreasentCard(women_dress)
Fk:loadTranslationTable{
  ["women_dress"] = "女装",
  ["#women_dress_skill"] = "女装",
  [":women_dress"] = "装备牌·防具<br/><b>防具技能</b>：锁定技，若你是男性角色，当你成为【杀】的目标后，你判定，若结果为黑色，此【杀】伤害+1。",
}

local elephantSkill = fk.CreateTriggerSkill{  --需要一个空技能以判断equip_skill是否无效
  name = "#elephant_skill",
  attached_equip = "elephant",
}
Fk:addSkill(elephantSkill)
local elephant = fk.CreateDefensiveRide{
  name = "elephant",
  suit = Card.Heart,
  number = 13,
  equip_skill = elephantSkill,
}
addPreasentCard(elephant)
Fk:loadTranslationTable{
  ["elephant"] = "战象",
  [":elephant"] = "装备牌·坐骑<br/><b>坐骑技能</b>：锁定技，其他角色计算至你的距离+1，其他角色对你赠予时赠予失败。",
}

local inferiorHorseSkill = fk.CreateDistanceSkill{
  name = "#inferior_horse_skill",
  frequency = Skill.Compulsory,
  fixed_func = function (self, from, to)
    if to:hasSkill(self) then
      return 1
    end
  end,
}
Fk:addSkill(inferiorHorseSkill)
local inferior_horse = fk.CreateOffensiveRide{
  name = "inferior_horse",
  suit = Card.Club,
  number = 13,
  equip_skill = inferiorHorseSkill,
}
addPreasentCard(inferior_horse)
Fk:loadTranslationTable{
  ["inferior_horse"] = "驽马",
  [":inferior_horse"] = "装备牌·坐骑<br/><b>坐骑技能</b>：锁定技，你计算至其他角色的距离-1，其他角色计算至你的距离始终为1。",
}

local carrierPigeonSkill = fk.CreateActiveSkill{
  name = "carrier_pigeon_skill&",
  attached_equip = "carrier_pigeon",
  anim_type = "support",
  card_num = 1,
  target_num = 1,
  prompt = "#carrier_pigeon_skill",
  can_use = function(self, player)
    return not player:isKongcheng() and player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
  end,
  card_filter = function(self, to_select, selected)
    return #selected == 0 and Fk:currentRoom():getCardArea(to_select) == Player.Hand
  end,
  target_filter = function(self, to_select, selected, selected_cards)
    return #selected == 0 and to_select ~= Self.id
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    room:moveCardTo(effect.cards[1], Card.PlayerHand, target, fk.ReasonGive, "carrier_pigeon", nil, false, player.id)
  end,
}
Fk:addSkill(carrierPigeonSkill)
local carrier_pigeon = fk.CreateTreasure{
  name = "carrier_pigeon",
  suit = Card.Heart,
  number = 4,
  equip_skill = carrierPigeonSkill,
}
addPreasentCard(carrier_pigeon)
Fk:loadTranslationTable{
  ["carrier_pigeon"] = "信鸽",
  ["carrier_pigeon_skill&"] = "信鸽",
  [":carrier_pigeon"] = "装备牌·宝物<br/><b>宝物技能</b>：出牌阶段限一次，你可以将一张手牌交给一名其他角色。",
  [":carrier_pigeon_skill&"] = "出牌阶段限一次，你可以将一张手牌交给一名其他角色",
  ["#carrier_pigeon_skill"] = "信鸽：你可以将一张手牌交给一名其他角色",
}

local present_skill = fk.CreateActiveSkill{
  name = "present_skill&",
  prompt = "#present_skill&",
  anim_type = "support",
  card_num = 1,
  target_num = 1,
  can_use = function(self, player)
    return table.find(player:getCardIds("h"), function(id) return Fk:getCardById(id):getMark("@@present") > 0 end)
  end,
  card_filter = function(self, to_select, selected)
    return #selected == 0 and Fk:getCardById(to_select):getMark("@@present") > 0 and table.contains(Self:getCardIds("h"), to_select)
  end,
  target_filter = function(self, to_select, selected, selected_cards)
    return #selected == 0 and to_select ~= Self.id
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    U.presentCard(player, target, Fk:getCardById(effect.cards[1]))
  end,
}
local espionage_rule = fk.CreateTriggerSkill{
  name = "#espionage_rule",
  priority = 0.001,
  global = true,

  refresh_events = {fk.GamePrepared},
  can_refresh = function(self, event, target, player, data)
    return not table.contains(player.room.disabled_packs, "espionage_cards")
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    for _, p in ipairs(room.alive_players) do
      room:handleAddLoseSkills(p, "present_skill&", nil, false, true)
    end
    for _, card in ipairs(Fk.packages["espionage_cards"].cards) do
      if table.contains(PresentCards, card) then
        room:setCardMark(card, "@@present", 1)
      end
    end
  end,
}
Fk:addSkill(present_skill)
Fk:addSkill(espionage_rule)
Fk:loadTranslationTable{
  ["present_skill&"] = "赠予",
  [":present_skill&"] = "出牌阶段，你可以从手牌中将一张有“赠”标记的牌正面向上赠予其他角色。若此牌不是装备牌，则进入该角色手牌区；若此牌是装备牌，"..
  "则进入该角色装备区且替换已有装备。",
  ["#present_skill&"] = "将一张有“赠”标记的牌赠予其他角色",
  ["@@present"] = "<font color='yellow'>赠</font>",
}

return extension
