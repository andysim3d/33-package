-- SPDX-License-Identifier: GPL-3.0-or-later

local extension = Package:new("1v1_cards", Package.CardPack)
extension.extensionName = "gamemode"
extension.game_modes_whitelist = {
  "m_1v1_mode",
}

Fk:loadTranslationTable{
  ["1v1_cards"] = "1v1卡牌",
}

extension:addCards{
  Fk:cloneCard("slash", Card.Spade, 5),
  Fk:cloneCard("slash", Card.Spade, 7),
  Fk:cloneCard("slash", Card.Spade, 8),
  Fk:cloneCard("slash", Card.Spade, 10),

  Fk:cloneCard("slash", Card.Heart, 10),
  Fk:cloneCard("slash", Card.Heart, 11),

  Fk:cloneCard("slash", Card.Club, 4),
  Fk:cloneCard("slash", Card.Club, 5),
  Fk:cloneCard("slash", Card.Club, 6),
  Fk:cloneCard("slash", Card.Club, 8),
  Fk:cloneCard("slash", Card.Club, 9),
  Fk:cloneCard("slash", Card.Club, 9),
  Fk:cloneCard("slash", Card.Club, 11),

  Fk:cloneCard("slash", Card.Diamond, 6),
  Fk:cloneCard("slash", Card.Diamond, 9),
  Fk:cloneCard("slash", Card.Diamond, 13),

  Fk:cloneCard("jink", Card.Heart, 2),
  Fk:cloneCard("jink", Card.Heart, 5),
  
  Fk:cloneCard("jink", Card.Diamond, 2),
  Fk:cloneCard("jink", Card.Diamond, 3),
  Fk:cloneCard("jink", Card.Diamond, 7),
  Fk:cloneCard("jink", Card.Diamond, 8),
  Fk:cloneCard("jink", Card.Diamond, 10),
  Fk:cloneCard("jink", Card.Diamond, 11),

  Fk:cloneCard("peach", Card.Heart, 3),
  Fk:cloneCard("peach", Card.Heart, 4),
  Fk:cloneCard("peach", Card.Heart, 9),

  Fk:cloneCard("peach", Card.Diamond, 12),
}

-- warning: cannot 'clone' drowning by cardname cause it havent been added to engine yet !
local variation_cards = require "packages/gamemode/variation_cards"
if variation_cards then
  local vc_cards = variation_cards.cards
  if type(vc_cards) == "table" then
    local drowning = table.find(vc_cards, function(c) return c.name == "drowning" end)
    if drowning then
      extension:addCard(drowning:clone(Card.Club, 7))
    end
  end
end

local dismantlementSkill = fk.CreateActiveSkill{
  name = "v11__dismantlement_skill",
  prompt = "#v11__dismantlement_skill",
  target_num = 1,
  mod_target_filter = function(self, to_select, selected, user, card)
    local to = Fk:currentRoom():getPlayerById(to_select)
    return user ~= to_select and not to:isNude()
  end,
  target_filter = function(self, to_select, selected, _, card)
    if #selected < self:getMaxTargetNum(Self, card) then
      return self:modTargetFilter(to_select, selected, Self.id, card)
    end
  end,
  on_effect = function(self, room, effect)
    local from = room:getPlayerById(effect.from)
    local to = room:getPlayerById(effect.to)
    if from.dead or to.dead or to:isNude() then return end
    local handcards = to:getCardIds("h")
    local choices = {}
    if #handcards > 0 then table.insert(choices, "$Hand") end
    if #to.player_cards[Player.Equip] > 0 then table.insert(choices, "$Equip") end
    if room:askForChoice(from, choices, self.name) == "$Equip" then
      local cid = room:askForCardChosen(from, to, "e", self.name)
      room:throwCard(cid, self.name, to, from)
    else
      local cid = room:askForCardChosen(from, to, { card_data = { { "$Hand", handcards } } }, self.name)
      room:throwCard(cid, self.name, to, from)
    end
  end
}
local dismantlement = fk.CreateTrickCard{
  name = "v11__dismantlement",
  skill = dismantlementSkill,
}
extension:addCards({
  dismantlement:clone(Card.Spade, 3),
  dismantlement:clone(Card.Spade, 12),
  dismantlement:clone(Card.Heart, 12),
})
Fk:loadTranslationTable{
  ["v11__dismantlement"] = "过河拆桥",
  [":v11__dismantlement"] = "锦囊牌<br/><b>时机</b>：出牌阶段<br/><b>目标</b>：一名有牌的其他角色。<br/><b>效果</b>：你选择一项：弃置其装备区里的一张牌；或观看其所有手牌并弃置其中一张。",
  ["#v11__dismantlement_skill"] = "选择一名有牌的其他角色，选择弃置其装备区一张牌，或观看并弃置一张手牌",
  ["v11__dismantlement_skill"] = "过河拆桥",
}

extension:addCards{
  Fk:cloneCard("snatch", Card.Spade, 4),
  Fk:cloneCard("snatch", Card.Spade, 11),
  Fk:cloneCard("snatch", Card.Diamond, 4),

  Fk:cloneCard("duel", Card.Spade, 1),
  Fk:cloneCard("duel", Card.Club, 1),

  Fk:cloneCard("nullification", Card.Heart, 13),
  Fk:cloneCard("nullification", Card.Club, 13),

  Fk:cloneCard("savage_assault", Card.Spade, 13),

  Fk:cloneCard("archery_attack", Card.Heart, 1),

  Fk:cloneCard("indulgence", Card.Heart, 6),

  Fk:cloneCard("supply_shortage", Card.Club, 12),
}

extension:addCards{
  Fk:cloneCard("blade", Card.Spade, 6),
  Fk:cloneCard("ice_sword", Card.Spade, 9),
  Fk:cloneCard("spear", Card.Spade, 12),
  Fk:cloneCard("crossbow", Card.Diamond, 1),
  Fk:cloneCard("axe", Card.Diamond, 5),
  Fk:cloneCard("eight_diagram", Card.Spade, 2),
  Fk:cloneCard("nioh_shield", Card.Club, 2),
}

return extension
