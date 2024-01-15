local role_mode = fk.CreateGameMode{
  name = "aab_role_mode", -- just to let it at the top of list
  minPlayer = 8,
  maxPlayer = 8,
  logic = function()
    local l = GameLogic:subclass("aab_role_mode_logic")
    function l:run()
      self.room.settings.enableDeputy = false
      GameLogic.run(self)
    end
    return l
  end,
  surrender_func = Fk.game_modes["aaa_role_mode"].surrenderFunc
}

Fk:loadTranslationTable{
  ["aab_role_mode"] = "单将军八",
  [":aab_role_mode"] = "就是禁用了副将且人数必须为8的身份模式。这个模式创立的目的是便于统计数据。",
}

return role_mode
