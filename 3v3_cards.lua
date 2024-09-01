-- SPDX-License-Identifier: GPL-3.0-or-later

local extension = Package:new("3v3_cards", Package.CardPack)
extension.extensionName = "gamemode"
extension.game_modes_whitelist = {
  "m_3v3_mode",
  --"m_2v2_mode"
}

Fk:loadTranslationTable{
  ["3v3_cards"] = "3v3卡牌",
}

extension:addCards{
  Fk:cloneCard("slash", Card.Spade, 7),
  Fk:cloneCard("slash", Card.Spade, 8),
  Fk:cloneCard("slash", Card.Spade, 8),
  Fk:cloneCard("slash", Card.Spade, 9),
  Fk:cloneCard("slash", Card.Spade, 9),
  Fk:cloneCard("slash", Card.Spade, 10),
  Fk:cloneCard("slash", Card.Heart, 10),
  Fk:cloneCard("slash", Card.Club, 3),
  Fk:cloneCard("slash", Card.Club, 4),
  Fk:cloneCard("slash", Card.Club, 6),
  Fk:cloneCard("slash", Card.Club, 8),
  Fk:cloneCard("slash", Card.Club, 9),
  Fk:cloneCard("slash", Card.Club, 9),
  Fk:cloneCard("slash", Card.Club, 10),
  Fk:cloneCard("slash", Card.Club, 10),
  Fk:cloneCard("slash", Card.Club, 11),
  Fk:cloneCard("slash", Card.Club, 11),
  Fk:cloneCard("slash", Card.Diamond, 6),
  Fk:cloneCard("slash", Card.Diamond, 10),
  Fk:cloneCard("slash", Card.Diamond, 13),

  Fk:cloneCard("thunder__slash", Card.Spade, 4),
  Fk:cloneCard("thunder__slash", Card.Spade, 5),
  Fk:cloneCard("thunder__slash", Card.Spade, 6),
  Fk:cloneCard("thunder__slash", Card.Club, 5),
  Fk:cloneCard("thunder__slash", Card.Club, 6),
  Fk:cloneCard("thunder__slash", Card.Club, 7),
  Fk:cloneCard("thunder__slash", Card.Club, 8),

  Fk:cloneCard("fire__slash", Card.Heart, 4),
  Fk:cloneCard("fire__slash", Card.Heart, 10),
  Fk:cloneCard("fire__slash", Card.Diamond, 4),
  Fk:cloneCard("fire__slash", Card.Diamond, 5),

  Fk:cloneCard("jink", Card.Heart, 2),
  Fk:cloneCard("jink", Card.Heart, 2),
  Fk:cloneCard("jink", Card.Heart, 9),
  Fk:cloneCard("jink", Card.Heart, 11),
  Fk:cloneCard("jink", Card.Heart, 13),
  Fk:cloneCard("jink", Card.Diamond, 2),
  Fk:cloneCard("jink", Card.Diamond, 6),
  Fk:cloneCard("jink", Card.Diamond, 7),
  Fk:cloneCard("jink", Card.Diamond, 7),
  Fk:cloneCard("jink", Card.Diamond, 8),
  Fk:cloneCard("jink", Card.Diamond, 8),
  Fk:cloneCard("jink", Card.Diamond, 9),
  Fk:cloneCard("jink", Card.Diamond, 10),
  Fk:cloneCard("jink", Card.Diamond, 11),
  Fk:cloneCard("jink", Card.Diamond, 11),

  Fk:cloneCard("peach", Card.Heart, 4),
  Fk:cloneCard("peach", Card.Heart, 6),
  Fk:cloneCard("peach", Card.Heart, 7),
  Fk:cloneCard("peach", Card.Heart, 8),
  Fk:cloneCard("peach", Card.Heart, 9),
  Fk:cloneCard("peach", Card.Diamond, 2),
  Fk:cloneCard("peach", Card.Diamond, 3),
  Fk:cloneCard("peach", Card.Diamond, 12),

  Fk:cloneCard("analeptic", Card.Spade, 3),
  Fk:cloneCard("analeptic", Card.Club, 3),
  Fk:cloneCard("analeptic", Card.Diamond, 9),

  Fk:cloneCard("dismantlement", Card.Spade, 3),
  Fk:cloneCard("dismantlement", Card.Spade, 4),
  Fk:cloneCard("dismantlement", Card.Spade, 12),
  Fk:cloneCard("dismantlement", Card.Heart, 12),

  Fk:cloneCard("snatch", Card.Spade, 11),
  Fk:cloneCard("snatch", Card.Diamond, 3),
  Fk:cloneCard("snatch", Card.Diamond, 4),

  Fk:cloneCard("duel", Card.Spade, 1),
  Fk:cloneCard("duel", Card.Diamond, 1),

  Fk:cloneCard("collateral", Card.Club, 12),
  Fk:cloneCard("collateral", Card.Club, 13),
}

local v33_exNihiloSkill = fk.CreateActiveSkill{
  name = "v33__ex_nihilo_skill",
  prompt = "#v33__ex_nihilo_skill",
  mod_target_filter = Util.TrueFunc,
  can_use = function(self, player, card)
    return not player:isProhibited(player, card)
  end,
  on_use = function(self, room, cardUseEvent)
    if not cardUseEvent.tos or #TargetGroup:getRealTargets(cardUseEvent.tos) == 0 then
      cardUseEvent.tos = { { cardUseEvent.from } }
    end
  end,
  on_effect = function(self, room, effect)
    local target = room:getPlayerById(effect.to)
    if target.dead then return end
    if 2 * #table.filter(room.alive_players, function (p)
      return p.role[1] == target.role[1]
    end) < #room.alive_players then
      target:drawCards(3, "v33__ex_nihilo")
    else
      target:drawCards(2, "v33__ex_nihilo")
    end
  end
}
local v33_exNihilo = fk.CreateTrickCard{
  name = "v33__ex_nihilo",
  skill = v33_exNihiloSkill,
}
extension:addCards({
  v33_exNihilo:clone(Card.Heart, 7),
  v33_exNihilo:clone(Card.Heart, 8),
  v33_exNihilo:clone(Card.Heart, 11),
})
Fk:loadTranslationTable{
  ["v33__ex_nihilo"] = "无中生有",
  [":v33__ex_nihilo"] = "锦囊牌<br/><b>时机</b>：出牌阶段<br/><b>目标</b>：你<br/><b>效果</b>：目标角色摸两张牌。若己方角色数少于"..
  "敌方角色数，则多摸一张牌。",
  ["#v33__ex_nihilo_skill"] = "摸两张牌，若己方角色数少于敌方则多摸一张牌",
}

extension:addCards{
  Fk:cloneCard("nullification", Card.Spade, 13),
  Fk:cloneCard("nullification", Card.Heart, 1),
  Fk:cloneCard("nullification", Card.Club, 12),
  Fk:cloneCard("nullification", Card.Diamond, 12),

  Fk:cloneCard("savage_assault", Card.Spade, 7),
  Fk:cloneCard("savage_assault", Card.Club, 7),

  Fk:cloneCard("archery_attack", Card.Heart, 1),

  Fk:cloneCard("god_salvation", Card.Heart, 1),

  Fk:cloneCard("amazing_grace", Card.Heart, 3),

  Fk:cloneCard("indulgence", Card.Spade, 6),
  Fk:cloneCard("indulgence", Card.Heart, 6),

  Fk:cloneCard("iron_chain", Card.Spade, 11),
  Fk:cloneCard("iron_chain", Card.Club, 12),
  Fk:cloneCard("iron_chain", Card.Club, 13),

  Fk:cloneCard("fire_attack", Card.Heart, 3),
  Fk:cloneCard("fire_attack", Card.Diamond, 12),

  Fk:cloneCard("supply_shortage", Card.Spade, 10),
  Fk:cloneCard("supply_shortage", Card.Club, 4),
}

local xbowSkill = fk.CreateTargetModSkill{
  name = "#xbow_skill",
  attached_equip = "xbow",
  frequency = Skill.Compulsory,
  residue_func = function(self, player, skill, scope, card)
    if player:hasSkill(self) and skill.trueName == "slash_skill" and scope == Player.HistoryPhase then
      --FIXME: 无法检测到非转化的cost选牌的情况，如活墨等
      local cardIds = Card:getIdList(card)
      local xbows = table.filter(player:getEquipments(Card.SubtypeWeapon), function(id)
        return Fk:getCardById(id).equip_skill == self
      end)
      if #xbows == 0 or not table.every(xbows, function(id)
        return table.contains(cardIds, id)
      end) then
        return 3
      end
    end
  end,
}
local xbowAudio = fk.CreateTriggerSkill{
  name = "#xbowAudio",

  refresh_events = {fk.CardUsing},
  can_refresh = function(self, event, target, player, data)
    return target == player and player:hasSkill(xbowSkill) and player.phase == Player.Play and
      data.card.trueName == "slash" and player:usedCardTimes("slash", Player.HistoryPhase) > 1
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    room:broadcastPlaySound("./packages/standard_cards/audio/card/crossbow")
    room:setEmotion(player, "./packages/standard_cards/image/anim/crossbow")
    room:sendLog{
      type = "#InvokeSkill",
      from = player.id,
      arg = "xbow",
    }
  end,
}
xbowSkill:addRelatedSkill(xbowAudio)
Fk:addSkill(xbowSkill)
local xbow = fk.CreateWeapon{
  name = "xbow",
  suit = Card.Club,
  number = 1,
  attack_range = 1,
  equip_skill = xbowSkill,
}
extension:addCard(xbow)
Fk:loadTranslationTable{
  ["xbow"] = "连弩",
  [":xbow"] = "装备牌·武器<br/><b>攻击范围</b>：1<br/><b>武器技能</b>：锁定技，你于出牌阶段内使用【杀】次数上限+3。",
  ["#xbow_skill"] = "连弩",
}

extension:addCards{
  Fk:cloneCard("double_swords", Card.Spade, 2),
  Fk:cloneCard("ice_sword", Card.Spade, 2),
  Fk:cloneCard("guding_blade", Card.Spade, 1),
  Fk:cloneCard("blade", Card.Spade, 5),
  Fk:cloneCard("spear", Card.Spade, 12),
  Fk:cloneCard("axe", Card.Diamond, 5),
  Fk:cloneCard("fan", Card.Diamond, 1),
  Fk:cloneCard("kylin_bow", Card.Heart, 5),

  Fk:cloneCard("eight_diagram", Card.Club, 2),
  Fk:cloneCard("vine", Card.Club, 2),
  Fk:cloneCard("silver_lion", Card.Club, 1),

  Fk:cloneCard("dilu", Card.Club, 5),
  Fk:cloneCard("zhuahuangfeidian", Card.Heart, 13),
  Fk:cloneCard("hualiu", Card.Diamond, 13),

  Fk:cloneCard("chitu", Card.Heart, 5),
  Fk:cloneCard("dayuan", Card.Spade, 13),
}

return extension
