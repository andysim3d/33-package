-- SPDX-License-Identifier: GPL-3.0-or-later

local description = [[
  # 应变模式简介

  《应变篇》是三国杀OL推出的全新牌扩，须替换军争/国战标准版牌堆对应的卡牌进行游戏。

  基本游戏规则与身份模式/国战标准模式相同。

  ---

  ## 新机制：应变

  在《应变篇》中，部分卡牌的牌面将带有特殊标记，标识此牌具有“应变”效果。具有这些标记的卡牌可符合对应的条件时触发其应变效果：

  富甲：使用时手牌最多。

  空巢：使用时没有手牌。

  残躯：使用时体力值为1。

  助战：指定目标后，除目标外的其他角色可以弃置一张同类别手牌，有角色响应后执行对应的效果。

  ---

  ## 新概念：冰属性伤害

  冰属性是一种新的属性伤害，与火属性伤害和雷属性伤害一样，可以传导。

  特别的，当你对一名角色造成冰属性伤害时，若其受到的不是传导伤害，你可以防止此伤害，依次弃置其两张牌。（类似于卡牌【寒冰剑】）

  ---

  ## 新概念：卜算

  卜算是一种新的能力关键字，部分牌或技能将引入卜算的操作。

  卜算X，即观看牌堆顶的X张牌，将其中任意张以任意顺序置于牌堆顶，其余以任意顺序置于牌堆底。（类似于诸葛亮的技能〖观星〗）。
]]
local variation = fk.CreateGameMode{
  name = "variation",
  minPlayer = 2,
  maxPlayer = 8,
  blacklist = {
    "standard_cards",
    "maneuvering",
    "hegemony_cards",
    "formation_cards",
    "momentum_cards",
    "transformation_cards",
    "power_cards",
    "chaos_mode_cards",
    "vanished_dragon_cards",
    "espionage_cards",
  },
  --rule = variation_rule,
  logic = Fk.game_modes["aaa_role_mode"].logic,
  surrender_func = function(self, playedTime)
    return Fk.game_modes["aaa_role_mode"]:surrenderFunc(self, playedTime)
  end,
}

Fk:loadTranslationTable{
  ["variation"] = "应变",
  [":variation"] = description,
}

return variation
