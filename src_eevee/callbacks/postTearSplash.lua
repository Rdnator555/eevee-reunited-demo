local postTearSplash = {}

local wonderousLauncher = require("src_eevee.items.collectibles.wonderousLauncher")
local swiftTear = require("src_eevee.attacks.eevee.swiftTear")

function postTearSplash:main(tear, splashType, collider)
	if splashType == "Wall" and tear:HasTearFlags(TearFlags.TEAR_SPECTRAL) then return end
	if splashType == "Collision" then
		if collider.Type == EntityType.ENTITY_FIREPLACE and tear:HasTearFlags(TearFlags.TEAR_SPECTRAL) then
			return
		end
		if tear:HasTearFlags(TearFlags.TEAR_PIERCING) then
			return
		end
	end
	wonderousLauncher:OnCoinDiscDestroy(tear)
	swiftTear:OnSwiftStarDestroy(tear, splashType)
end

function postTearSplash:init(EeveeReunited)
	EeveeReunited:AddCallback(ModCallbacks.MC_POST_ENTITY_REMOVE, postTearSplash.OnPostEntityRemove)
	EeveeReunited:AddCallback(ModCallbacks.MC_PRE_TEAR_COLLISION, postTearSplash.OnTearCollision)
	EeveeReunited:AddCallback(ModCallbacks.MC_POST_TEAR_UPDATE, postTearSplash.OnTearUpdate)
end

--Hitting the floor
function postTearSplash:OnPostEntityRemove(tear)
	if not tear:ToTear() or tear:ToTear().Height <= -5 then
		return
	end
	postTearSplash:main(tear:ToTear(), "Floor")
end

--Hitting an enemy
function postTearSplash:OnTearCollision(tear, collider)
	postTearSplash:main(tear, "Collision", collider)
end

--Hitting a wall or grid entity
function postTearSplash:OnTearUpdate(tear)
	if tear.Height > -5 then
		return
	end

	if not tear:GetData().TearDeaded and tear:IsDead() then
		tear:GetData().TearDeaded = true
		postTearSplash:main(tear, "Wall")
	end
end

return postTearSplash
