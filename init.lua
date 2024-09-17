-- SPDX-License-Identifier: GPL-3.0-or-later

local extension = Package:new("gamemode", Package.SpecialPack)

extension:addGameMode(require "packages/gamemode/role")
extension:addGameMode(require "packages/gamemode/1v2")
extension:addGameMode(require "packages/gamemode/1v2brawl")
extension:addGameMode(require "packages/gamemode/2v2")
-- extension:addGameMode(require "packages/gamemode/rand")
extension:addGameMode(require "packages/gamemode/1v1")
extension:addGameMode(require "packages/gamemode/3v3")
extension:addGameMode(require "packages/gamemode/1v3")
extension:addGameMode(require "packages/gamemode/chaos_mode")
extension:addGameMode(require "packages/gamemode/espionage")
extension:addGameMode(require "packages/gamemode/variation")
extension:addGameMode(require "packages/gamemode/vanished_dragon")
extension:addGameMode(require "packages/gamemode/qixi")
extension:addGameMode(require "packages/gamemode/zombie_mode")
extension:addGameMode(require "packages/gamemode/kangqin")
extension:addGameMode(require "packages/gamemode/jiange")

local chaos_mode_cards = require "packages/gamemode/chaos_mode_cards"
local espionage_cards = require "packages/gamemode/espionage_cards"
local vanished_dragon_cards = require "packages/gamemode/vanished_dragon_cards"
local variation_cards = require "packages/gamemode/variation_cards"
local v33_cards = require "packages/gamemode/3v3_cards"
local v11_cards = require "packages/gamemode/1v1_cards"

local gamemode_generals = require "packages/gamemode/gamemode_generals"
local jiange_generals = require "packages/gamemode/jiange_generals"
local m_1v1_generals = require "packages/gamemode/1v1_generals"

Fk:loadTranslationTable{ ["gamemode"] = "游戏模式" }
Fk:loadTranslationTable(require 'packages/gamemode/i18n/en_US', 'en_US')

return {
  extension,

  chaos_mode_cards,
  espionage_cards,
  vanished_dragon_cards,
  variation_cards,
  v33_cards,
  v11_cards,

  gamemode_generals,
  jiange_generals,
  m_1v1_generals,
}
