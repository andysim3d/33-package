-- SPDX-License-Identifier: GPL-3.0-or-later
local description = [[
  # 用间模式简介

  《三国杀用间篇》是《三国杀标准版》的扩展包，在《三国杀用间篇》中，你会有更多避免和对手正面交锋的手段展开刺激的较量，可以下毒令其进入“慢性死亡”，也可以将其装备更换为损坏的劣品令其陷入困境，一起来加入这工于心计的战斗，体验谋定天下的快感吧。

  ---

  ## 新机制：赠予

  游戏牌上带有“赠”标识的牌，表示此牌能被赠予。

  赠予是一项独立动作，流程为：出牌阶段，你可以从手牌中将该牌以正面向上的方式将此牌赠予其他角色。若此牌不是装备牌，则进入该角色手牌区；若此牌是装备牌，则进入该角色装备区且替换已有装备。

  备注：

  1.赠予目标不能拒绝被赠予。

  2.一旦发起赠予，无论发起赠予者在赠予过程中存活与否，都必须结算完赠予流程，即赠予的牌须进入赠予目标的手牌区或装备区。

  3.赠予是独立于牌名的功能效果，一张游戏牌牌面上带有“赠”标识，不代表所有同名的牌都可赠予（例如【毒】）。

  4.在受到技能影响下，赠予可能会失败。若赠予失败，须将被赠予的牌置入弃牌堆。
  
  ---

  ## 新机制：【毒】

  【毒】是《三国杀用间篇》特有的一种基本牌，其效果为：当【毒】正面向上离开你的手牌区（包括转化为其他牌）或作为你的拼点牌亮出后，你失去1点体力。当你因摸牌获得【毒】后，你可以将之交给一名其他角色，以此法失去【毒】时不触发失去体力效果。

  备注：

  1.【毒】以正面向上的形式离开手牌区包括但不限于：将【毒】赠予其他角色，被使用【过河拆桥】等卡牌弃置，弃牌阶段将【毒】弃置等等。【毒】以背面向上的形式离开手牌区不产生失去体力的效果，如刘备通过技能〖仁德〗交给其他角色，被使用【顺手牵羊】等卡牌被其他角色获得等。

  2.【毒】转化为其他牌包括使用【丈八蛇矛】转化为【杀】，使用甘宁的技能〖奇袭〗转化为【过河拆桥】，使用甄姬的技能〖倾国〗转化为【闪】等等。

  3.通过【五谷丰登】、郭嘉的技能〖遗计〗等方式获得牌不属于摸牌，不能直接交给其他角色。
]]
local espionage = fk.CreateGameMode{
  name = "espionage",
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
    "variation_cards",
  },
  logic = Fk.game_modes["aaa_role_mode"].logic,
  surrender_func = function(self, playedTime)
    return Fk.game_modes["aaa_role_mode"]:surrenderFunc(self, playedTime)
  end,
}

Fk:loadTranslationTable{
  ["espionage"] = "用间",
  [":espionage"] = description,
}

return espionage
