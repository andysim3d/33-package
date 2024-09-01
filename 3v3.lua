local m_3v3_desc = [[
  
# 3v3模式简介

  六名玩家3v3进行对战的竞技模式。
  
  若为“统帅三军”规则，则改为两名玩家1v1对战，每名玩家控制三名角色（统帅三军模式暂无）。

  3v3模式规则历年经过多次修改，新月杀采用的是2023版王者之战规则。

  ___

  ## 阵营分布

  分为暖色方、冷色方双方阵营，每阵营为一名“主帅”和两名“先锋”。暖色方身份牌为红色，冷色方身份牌为蓝色。

  座次固定为：冷方先锋A-冷方主帅-冷方先锋B-暖方先锋A-暖方主帅-暖方先锋B

  ___

  ## 胜利条件

  消灭敌方阵营的主帅。

  ___

  ## 选将流程

  游戏开始前，展示16张公共武将牌，由双方主帅为本方阵营挑选武将。

  由暖色方开始，按1-2-2-...-2-1的数量，双方交替选择武将。
  
  完成选将后，主帅为本方的三名角色选择武将，然后同时亮出，游戏开始。

  ___

  ## 初始体力与手牌

  主帅的初始体力上限和初始体力值+1，但不会获得主公技。

  暖色方主帅初始手牌数+1。

  ___

  ## 行动顺序

  行动顺序是3v3模式与其他游戏模式最大的区别。

  每轮游戏分为四个行动单元。每个行动单元中，主帅选择：1.自己行动；2.选择一名本方先锋，该先锋行动，然后另一名先锋行动。

  1. 由冷色方开始，执行一个行动单元；
  
  2. 然后暖色方执行一个行动单元；

  3. 冷色方执行剩余的一个行动单元（即：若第一个行动单元时选择主帅行动，则此时两名先锋行动；若第一个行动单元时选择两名先锋行动，则此时主帅行动）；
  
  4. 最后再由暖色方执行最后一个行动单元。

  5. 所有角色都行动后，完成一轮。

  线下模式中，会将身份牌横置以表示本轮已行动。在新月杀中，为行动的角色增加“已行动”标记（小红旗）以表示本轮已行动。

  ___

  ## 击杀奖惩

  击杀一名先锋角色后，摸两张牌。（贴吧早年梗：冷主收边）

  ___

  ## 特殊规则

  本模式AOE卡牌（【南蛮入侵】、【万箭齐发】、【桃园结义】、【五谷丰登】）在使用前，使用者选择按顺时针或逆时针方向进行结算。

  ___

  ## 游戏牌堆

  本模式采用特殊的精简后的标准版+军争牌堆，牌堆列表参见卡牌一览。

  注意，部分卡牌效果进行了修改：

  - 【无中生有】：出牌阶段，对你使用，目标角色摸两张牌。若己方角色数少于敌方角色数，则多摸一张牌。
  - 【诸葛连弩】替换为【连弩】：锁定技，你于出牌阶段内使用【杀】次数上限+3。

  ___

  ## 武将牌堆

  采用专用的竞技将池，部分武将技能进行了修改。

]]

local m_3v3_getLogic = function()
  local m_3v3_logic = GameLogic:subclass("m_3v3_logic") ---@class GameLogic

  function m_3v3_logic:initialize(room)
    GameLogic.initialize(self, room)
    self.role_table = {
      {"cool_vanguard", "cool_marshal", "cool_vanguard", "warm_vanguard", "warm_marshal", "warm_vanguard"},
    }
  end

  function m_3v3_logic:assignRoles()
    local room = self.room
    local roles = self.role_table[math.random(1, 1)]
    table.shuffle(room.players)
    for i = 1, #room.players do
      local p = room.players[i]
      p.role = roles[i]
      p.role_shown = true
      room:broadcastProperty(p, "role")
    end
    room.current = room.players[1]
  end

  function m_3v3_logic:chooseGenerals()
    local room = self.room
    math.randomseed(tonumber(tostring(os.time()):reverse():sub(1, 6)))

    local all_generals = room:getNGenerals(16)
    local cool_marshal = room.players[2]
    local warm_marshal = room.players[5]
    room.current = cool_marshal

    local cool_generals, warm_generals = {}, {}

    local function removeSame(t, n)
      local same = Fk:getSameGenerals(n)
      for i, v in ipairs(t) do
        if table.contains(same, v) or (v == n) then
          table.remove(t, i)
          return
        end
      end
    end
    local function chooseGeneral(p, n)
      local g = room:askForGeneral(p, all_generals, n, true)
      if type(g) == "string" then g = {g} end
      local t = p == cool_marshal and cool_generals or warm_generals
      table.insertTable(t, g)
      removeSame(all_generals, g[1])
      if g[2] then removeSame(all_generals, g[2]) end
      room:sendLog{
        type = "#3v3ChooseGeneralsLog",
        arg = p == cool_marshal and "cool" or "warm",
        arg2 = g[1],
        arg3 = g[2] or "",
        toast = true,
      }
      room:setBanner("@&cool_generals", cool_generals)
      room:setBanner("@&warm_generals", warm_generals)
    end

    chooseGeneral(warm_marshal, 1)
    chooseGeneral(cool_marshal, 2)
    chooseGeneral(warm_marshal, 2)
    chooseGeneral(cool_marshal, 2)
    chooseGeneral(warm_marshal, 2)
    chooseGeneral(cool_marshal, 2)
    chooseGeneral(warm_marshal, 2)
    chooseGeneral(cool_marshal, 2)
    chooseGeneral(warm_marshal, 1)

    cool_marshal.request_data = json.encode({ cool_generals, 3, true })
    cool_marshal.default_reply = table.concat(table.random(cool_generals, 3), ",")
    warm_marshal.request_data = json.encode({ warm_generals, 3, true })
    warm_marshal.default_reply = table.concat(table.random(warm_generals, 3), ",")

    room:doBroadcastNotify("ShowToast", Fk:translate("3v3_choose_general"))
    room:doBroadcastRequest("AskForGeneral", {cool_marshal, warm_marshal})

    room:setBanner("@&cool_generals", 0)
    room:setBanner("@&warm_generals", 0)

    local generals = {}
    if cool_marshal.reply_ready then
      table.insertTable(generals, json.decode(cool_marshal.client_reply))
    else
      table.insertTable(generals, string.split(cool_marshal.default_reply, ","))
    end
    if warm_marshal.reply_ready then
      table.insertTable(generals, json.decode(warm_marshal.client_reply))
    else
      table.insertTable(generals, string.split(warm_marshal.default_reply, ","))
    end

    for i = 1, 6, 1 do
      local p = room.players[i]
      room:setPlayerGeneral(p, generals[i], true, true)
      room:broadcastProperty(p, "general")
      p.default_reply = ""
      p.default_reply = ""
    end
  end

  function m_3v3_logic:attachSkillToPlayers()
    local room = self.room
    local addRoleModSkills = function(player, skillName)
      local skill = Fk.skills[skillName]
      if not skill then
        fk.qCritical("Skill: "..skillName.." doesn't exist!")
        return
      end
      if skill.lordSkill then
        return
      end
      if #skill.attachedKingdom > 0 and not table.contains(skill.attachedKingdom, player.kingdom) then
        return
      end

      room:handleAddLoseSkills(player, skillName, nil, false)
    end
    for _, p in ipairs(room.alive_players) do
      for _, s in ipairs(Fk.generals[p.general]:getSkillNameList(false)) do
        addRoleModSkills(p, s)
      end
      if p.deputyGeneral ~= "" then
        for _, s in ipairs(Fk.generals[p.deputyGeneral]:getSkillNameList(false)) do
          addRoleModSkills(p, s)
        end
      end
    end
  end

  ---@class m_3v3_Round: GameEvent.Round
  local m_3v3_Round = GameEvent.Round:subclass("m_3v3_Round")
  function m_3v3_Round:action()
    local room = self.room
    local cool_marshal = table.find(room.players, function (p)
      return p.role == "cool_marshal"
    end)
    local warm_marshal = table.find(room.players, function (p)
      return p.role == "warm_marshal"
    end)
    local function CommandAction(marshal)
      local friends = table.filter(room.alive_players, function (p)
        return marshal.role[1] == p.role[1] and p:getMark("@!action-round") == 0
      end)
      if #friends > 0 then
        local to
        if #friends > 1 then
          to = room:askForChoosePlayers(marshal, table.map(friends, Util.IdMapper), 1, 1,
            "#m_3v3_action", "m_3v3_gamerule", false)
          to = room:getPlayerById(to[1])
        else
          to = friends[1]
        end
        room.current = to
        room:setPlayerMark(to, "@!action-round", 1)
        GameEvent.Turn:create(to):exec()
        while to ~= marshal do
          if room.game_finished then break end
          local vanguards = table.filter(room.alive_players, function (p)
            return p.role:endsWith("vanguard") and marshal.role[1] == p.role[1] and p:getMark("@!action-round") == 0
          end)
          if #vanguards > 0 then
            if #vanguards > 1 then
              to = room:askForChoosePlayers(marshal, table.map(vanguards, Util.IdMapper), 1, 1,
                "#m_3v3_action", "m_3v3_gamerule", false)
              room.current = to
              room:setPlayerMark(to, "@!action-round", 1)
              GameEvent.Turn:create(to):exec()
            else
              to = vanguards[1]
              room.current = to
              room:setPlayerMark(to, "@!action-round", 1)
              GameEvent.Turn:create(to):exec()
            end
          else
            break
          end
        end
      end
    end
    while table.find(room.alive_players, function (p)
      return p:getMark("@!action-round") == 0
    end) do
      if room.game_finished then break end
      CommandAction(cool_marshal)
      if room.game_finished then break end
      CommandAction(warm_marshal)
    end
  end

  function m_3v3_logic:action()
    self:trigger(fk.GamePrepared)
    local room = self.room
    room:setTag("SkipNormalDeathProcess", true)

    GameEvent.DrawInitial:create():exec()

    while true do
      m_3v3_Round:create():exec()
      if room.game_finished then break end
    end
  end

  return m_3v3_logic
end

local m_3v3_rule = fk.CreateTriggerSkill{
  name = "#m_3v3_rule",
  priority = 0.001,
  mute = true,
  events = {fk.DrawInitialCards, fk.GameOverJudge, fk.Deathed, fk.PreCardUse, fk.BeforeDrawCard},
  can_trigger = function (self, event, target, player, data)
    return target == player and not (event == fk.Deathed and player.rest > 0)
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.DrawInitialCards then
      if player.seat == 5 then
        data.num = data.num + 1
      end
    elseif event == fk.GameOverJudge then
      room:setTag("SkipGameRule", true)
      if target.role == "cool_marshal" then
        room:gameOver("warm")
        return true
      elseif target.role == "warm_marshal" then
        room:gameOver("cool")
        return true
      end
    elseif event == fk.Deathed and target.role:endsWith("vanguard") then
      local damage = data.damage
      if damage and damage.from and not damage.from.dead then
        damage.from:drawCards(2, "kill")
      end
    elseif event == fk.PreCardUse then
      if data.card.multiple_targets and data.card.skill.min_target_num == 0 then
        local choice = room:askForChoice(player, {"left", "right"}, "m_3v3_gamerule",
          "#m_3v3_aoe-choice:::"..data.card:toLogString())
        if choice == "left" then
          data.extra_data = data.extra_data or {}
          data.extra_data.m_3v3_reverse = true
        end
      end
    elseif event == fk.BeforeDrawCard and data.skillName == "ex_nihilo" then  --转化出的原版无中（eg.孙乾），按理来说应该改卡牌的skill
      if 2 * #table.filter(room.alive_players, function (p)
        return p.role[1] == target.role[1]
      end) < #room.alive_players then
        data.num = data.num + 1
      end
    end
  end,

  refresh_events = {fk.BeforeCardUseEffect},
  can_refresh = function(self, event, target, player, data)
    return player.seat == 1 and data.extra_data and data.extra_data.m_3v3_reverse and
      #TargetGroup:getRealTargets(data.tos) > 0
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    local new_tos = {}
    local players = {room.current}
    table.insertTable(players, table.reverse(room:getOtherPlayers(room.current)))
    for _, p in ipairs(players) do
      for _, info in ipairs(data.tos) do
        if info[1] == p.id then
          table.insert(new_tos, info)
          break
        end
      end
    end
    data.tos = new_tos
  end,
}
Fk:addSkill(m_3v3_rule)

local m_3v3_mode = fk.CreateGameMode{
  name = "m_3v3_mode",
  minPlayer = 6,
  maxPlayer = 6,
  logic = m_3v3_getLogic,
  rule = m_3v3_rule,
  surrender_func = function(self, playedTime)
    if Self.role:endsWith("vanguard") then
      return { { text = "vanguard_never_surrender", passed = false } }
    else
      local canSurrender = true
      if table.find(Fk:currentRoom().players, function(p)
        return (p.rest > 0 or not p.dead) and p ~= Self and p.role[1] == Self.role[1]
      end) then
        canSurrender = false
      end
      return { { text = "marshal_surrender", passed = canSurrender } }
    end
  end,
  whitelist = {
    "3v3_cards",

    "standard_ex",-- 先随便开一些
    "wind",
    "fire",
    "forest",
    "mountain",
    "shadow",
    "thunder",

    "yj2011",
    "yj2012",
    "yj2013",
    "yj2014",
    "yj2015",
    "yczh2016",
    "yczh2017",

    "sp",
    "sp_jsp",

    "ol_sp1",
    "ol_sp4",
    "ol_wende",

    "tenyear_xinghuo",

    "courage",
    "strictness",

    "overseas_strategizing",

    "sxfy_shaoyin",
    "sxfy_taiyin",

    "transition",
    "decline",

    "lunar_sp1",
  },
  winner_getter = function(self, victim)
    if not victim.surrendered and victim.rest > 0 then
      return ""
    end
    if victim.role == "cool_marshal" then
      return "warm_marshal+warm_vanguard"
    elseif victim.role == "warm_marshal" then
      return "cool_marshal+cool_vanguard"
    end
  end,
  get_adjusted = function (self, player)
    if player.role:endsWith("marshal") then
      return {hp = player.hp + 1, maxHp = player.maxHp + 1}
    end
    return {}
  end,
}

Fk:loadTranslationTable{
  ["m_3v3_mode"] = "3v3",
  [":m_3v3_mode"] = m_3v3_desc,
  ["cool"] = "冷色方",
  ["warm"] = "暖色方",
  ["cool_marshal"] = "冷方主帅",
  ["warm_marshal"] = "暖方主帅",
  ["cool_vanguard"] = "冷方先锋",
  ["warm_vanguard"] = "暖方先锋",

  ["#3v3ChooseGeneralsLog"] = "%arg 选择了 %arg2 %arg3",
  ["3v3_choose_general"] = "请为本方阵营选择选择武将，从左至右为：左方先锋 主帅 右方先锋",
  ["@&cool_generals"] = "冷方已选武将",
  ["@&warm_generals"] = "暖方已选武将",

  ["m_3v3_gamerule"] = "选择",
  ["#m_3v3_action"] = "选择一名友方角色行动",

  ["#m_3v3_aoe-choice"] = "选择你使用%arg结算的方向",
  ["left"] = "←顺时针方向",
  ["right"] = "逆时针方向→",

  ["cool_marshal+cool_vanguard"] = "冷色方",
  ["warm_marshal+warm_vanguard"] = "暖色方",
  ["vanguard_never_surrender"] = "先锋永不投降！",
  ["marshal_surrender"] = "本阵营先锋均阵亡",
}

return m_3v3_mode