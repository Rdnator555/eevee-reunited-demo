local postGameStarted = {}

local pokeyMans = require("src_eevee.challenges.pokeyMansCrystal")
local triggerOnFire = require("src_eevee.items.triggerOnFire")
local activeItemRender = require("src_eevee.items.activeItemRender")
local ccp = require("src_eevee.player.characterCostumeProtector")
local badEgg = require("src_eevee.items.collectibles.badEgg")
local swiftBase = require("src_eevee.attacks.eevee.swiftBase")

---@param wasRunContinued boolean
function postGameStarted:main(wasRunContinued)
	EEVEEMOD.shouldSaveData = true
	if not wasRunContinued then
		activeItemRender:ResetOnGameStart()
	else
		ccp:GnawedOnLoad()
	end
	triggerOnFire:ResetOnGameStart()
	pokeyMans:InitChallenge()
	badEgg:GetFamiliarItemsOnGameStart()
	swiftBase.Instances = {}
	swiftBase.Weapons = {}
	swiftBase.Players = {}
end

function postGameStarted:init(EeveeReunited)
	EeveeReunited:AddCallback(ModCallbacks.MC_POST_GAME_STARTED, postGameStarted.main)
end

return postGameStarted
