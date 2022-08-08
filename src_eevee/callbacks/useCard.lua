local useCard = {}

local eeveeSFX = require("src_eevee.player.eeveeSFX")
local pokeball = require("src_eevee.items.pickups.pokeball")
local lilEevee = require("src_eevee.items.collectibles.lilEevee")

function useCard:main(card, player, useFlags)
	if card == Card.CARD_SOUL_SAMSON then
		eeveeSFX:OnSamsonSoul(card, player, useFlags)
	end
	lilEevee:OnRune(card, player, useFlags)
	pokeball:OnPokeballUse(card, player, useFlags)
end

function useCard:init(EeveeReunited)
	EeveeReunited:AddCallback(ModCallbacks.MC_USE_CARD, useCard.main)
end

return useCard
