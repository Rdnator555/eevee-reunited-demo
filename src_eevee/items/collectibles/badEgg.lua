local badEgg = {}

local maxOGCracks = 8
local maxDupeCracks = maxOGCracks / 4
local familiarItems = {}

local variantToCrackCount = {
	[EEVEEMOD.FamiliarVariant.BAD_EGG] = maxOGCracks,
	[EEVEEMOD.FamiliarVariant.BAD_EGG_DUPE] = maxDupeCracks
}

function badEgg:BlockProjectile(proj, collider)
	if collider.Type == EntityType.ENTITY_FAMILIAR
		and variantToCrackCount[collider.Variant] ~= nil then
		local familiar = collider:ToFamiliar()
		local maxCracks = variantToCrackCount[familiar.Variant]
		familiar.State = familiar.State + 1
		if familiar.State >= maxCracks and not familiar:GetSprite():IsPlaying("Break") then
			collider.EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE
			familiar:GetSprite():Play("Break", true)
		end
		proj:Die()
	end
end

function badEgg:GetFamiliarItemsOnGameStart()
	local itemConfig = Isaac.GetItemConfig()
	local MaxCollectibles = Isaac.GetItemConfig():GetCollectibles().Size - 1

	familiarItems = {}
	for itemID = 1, MaxCollectibles do
		local itemConfigItem = itemConfig:GetCollectible(itemID)
		if itemConfigItem ~= nil and itemConfigItem.Type == ItemType.ITEM_FAMILIAR and not itemConfigItem:HasTags(ItemConfig.TAG_QUEST) then
			table.insert(familiarItems, itemID)
		end
	end
end

local function SpawnShells(familiar, maxNum)
	for i = 1, maxNum do
		local vel = Vector(3, 0):Rotated(EEVEEMOD.RandomNum(360))
		local chip = Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.TOOTH_PARTICLE, 0, familiar.Position, vel, nil)
		chip:GetSprite():ReplaceSpritesheet(0, "gfx/effects/effect_egg_gibs.png")
		chip:GetSprite():LoadGraphics()
	end
end

local function SpawnGlitch(familiar)
	local glitch = Isaac.Spawn(EntityType.ENTITY_EFFECT, EEVEEMOD.EffectVariant.BAD_EGG_GLITCH, 0, familiar.Position, Vector.Zero, nil):ToEffect()
	glitch.Parent = familiar
	glitch:FollowParent(glitch.Parent)
	EEVEEMOD.sfx:Play(SoundEffect.SOUND_EDEN_GLITCH)
end

local function ResetState(familiar)
	familiar.State = 0
	familiar.EntityCollisionClass = EntityCollisionClass.ENTCOLL_ALL
	badEgg:OnFamiliarInit(familiar)
end

--[[ local function SpawnGlitchPoolItem(familiar, pos, rng)
	local glitchPool = VeeHelper.GetCustomItemPool(EEVEEMOD.ItemPool.POOL_GLITCH)

	if #glitchPool == 0 then
		local treasureRoomItem = EEVEEMOD.game:GetItemPool():GetCollectible(ItemPoolType.POOL_TREASURE, true, rng:GetSeed())
		EEVEEMOD.game:Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_COLLECTIBLE, pos, Vector.Zero, familiar, treasureRoomItem, rng:GetSeed())
	else
		local getRandomItem = function() return rng:RandomInt(#glitchPool) + 1 end
		local randomGlitchItem = glitchPool[getRandomItem()]
		EEVEEMOD.game:Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_COLLECTIBLE, pos, Vector.Zero, familiar, randomGlitchItem, rng:GetSeed())
	end
end ]]

local function RemoveDupedEgg(player, familiar)
	local effects = player:GetEffects()

	effects:AddCollectibleEffect(EEVEEMOD.CollectibleType.BAD_EGG_DUPE, false, 1)
	SpawnGlitch(familiar)
	familiar:Remove()
	player:AddCacheFlags(CacheFlag.CACHE_FAMILIARS)
	player:EvaluateItems()
end

local function BFFSSpawnItem(familiar, pos, rng)
	local itemConfig = Isaac.GetItemConfig()
	local MaxCollectibles = itemConfig:GetCollectibles().Size - 2
	local getRandomItem = function() return rng:RandomInt(MaxCollectibles) + 1 end
	local randomItem = getRandomItem()
	while itemConfig:GetCollectible(randomItem) == nil or itemConfig:GetCollectible(randomItem).Quality >= 3 do
		randomItem = getRandomItem()
	end
	local players = VeeHelper.GetAllPlayers()
	if VeeHelper.IsTrinketOwned(TrinketType.TRINKET_NO) then
		local itemConfig = Isaac.GetItemConfig()

		while itemConfig:GetCollectible(randomItem).Type == ItemType.ITEM_ACTIVE do
			randomItem = getRandomItem()
		end
	end
	EEVEEMOD.game:Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_COLLECTIBLE, pos, Vector.Zero, familiar, randomItem, rng:GetSeed())
end

local function BreakEgg(familiar)
	local player = familiar.Player
	if not player then return end
	local effects = player:GetEffects()

	if familiar.Variant == EEVEEMOD.FamiliarVariant.BAD_EGG_DUPE then
		RemoveDupedEgg(player, familiar)
		return
	end

	local ownedFamiliars = {}
	for i = 1, #familiarItems do
		if player:HasCollectible(familiarItems[i]) then
			table.insert(ownedFamiliars, familiarItems[i])
		end
	end
	local rng = player:GetCollectibleRNG(EEVEEMOD.CollectibleType.BAD_EGG)
	local pos = Game():GetRoom():FindFreePickupSpawnPosition(familiar.Position)
	local shouldItem = player:HasCollectible(CollectibleType.COLLECTIBLE_BFFS) and rng:RandomInt(2) == 1 or false
	local alreadyReset = false

	if #ownedFamiliars > 0 then

		local randomNum = rng:RandomInt(#ownedFamiliars) + 1
		local selectedFamiliar = ownedFamiliars[randomNum]
		if selectedFamiliar == CollectibleType.COLLECTIBLE_GB_BUG then
			local bug = Isaac.Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_COLLECTIBLE, CollectibleType.COLLECTIBLE_GB_BUG, pos, Vector.Zero, nil):ToPickup()
			bug:AddEntityFlags(EntityFlag.FLAG_GLITCH)
			bug:Morph(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_COLLECTIBLE, CollectibleType.COLLECTIBLE_GB_BUG)
		else
			if shouldItem then
				BFFSSpawnItem(familiar, pos, rng)
			else
				player:AddCollectible(EEVEEMOD.CollectibleType.BAD_EGG_DUPE)
			end
		end
		player:RemoveCollectible(selectedFamiliar)

		SpawnGlitch(familiar)
		ResetState(familiar)
		alreadyReset = true
	end
	if player:HasCollectible(EEVEEMOD.CollectibleType.BAD_EGG_DUPE) then
		effects:RemoveCollectibleEffect(EEVEEMOD.CollectibleType.BAD_EGG_DUPE, 1)
		if not alreadyReset then
			SpawnGlitch(familiar)
			ResetState(familiar)
		end
	elseif #ownedFamiliars == 0 then
		player:RemoveCollectible(EEVEEMOD.CollectibleType.BAD_EGG)
		Isaac.Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_COLLECTIBLE, EEVEEMOD.CollectibleType.STRANGE_EGG, pos, Vector.Zero, familiar)
		EEVEEMOD.sfx:Play(SoundEffect.SOUND_EDEN_GLITCH, 1, 2, false, 0.5)
		SpawnShells(familiar, 9)
	end
end

local function GetCrackState(familiar)
	local maxCracks = variantToCrackCount[familiar.Variant]
	local interVal = (maxCracks / 4)
	local crackState = (familiar.State < maxCracks and familiar.State > 0 and familiar.State % interVal == 0) and math.floor(familiar.State / interVal) or 0
	return crackState
end

function badEgg:OnFamiliarInit(familiar)
	familiar:GetSprite():Play("FloatDown_" .. GetCrackState(familiar), true)
end

function badEgg:OnFamiliarUpdate(familiar)
	local crackState = GetCrackState(familiar)
	local currentAnim = string.gsub(familiar:GetSprite():GetAnimation(), "FloatDown_", "")
	local sprite = familiar:GetSprite()

	if familiar.FrameCount > 0 and #familiarItems == 0 then
		badEgg:GetFamiliarItemsOnGameStart()
	end

	if currentAnim ~= tostring(crackState) and crackState > 0 then
		sprite:Play("FloatDown_" .. crackState, true)
		EEVEEMOD.sfx:Play(SoundEffect.SOUND_FORTUNE_COOKIE)
		SpawnShells(familiar, 3)
	end

	if sprite:IsEventTriggered("Prize") then
		BreakEgg(familiar)
	end
end

function badEgg:RemoveGlitchOnAnimEnd(effect)
	if effect:GetSprite():IsFinished("Glitch") then
		effect:Remove()
	end
end

return badEgg
