local strangeEgg = {}

--[[ 
local function GetActiveItemBatteryCharge(player, itemID)
	return player:GetBatteryCharge(VeeHelper.GetActiveSlots(player, itemID))
end

local function CheckItemCanCharge(player, itemID, maxCharge)
	local canCharge = false

	if VeeHelper.GetActiveItemCharges(player, itemID) < maxCharge 	
	or
	(
	player:HasCollectible(CollectibleType.COLLECTIBLE_THE_BATTERY) 
	and GetActiveItemBatteryCharge(player, itemID) < maxCharge
	) then
	
		canCharge = true
	end

	return canCharge
end

local function AAABatteryProc(player, itemID, maxCharge)
	if player:HasCollectible(TrinketType.TRINKET_AAA_BATTERY) then
		if VeeHelper.GetActiveItemCharges(player, itemID) == (maxCharge - 1) then
			return true
		end
	end
end

local function WatchBatteryProc(player)
	if player:HasCollectible(TrinketType.TRINKET_WATCH_BATTERY) then
		if math.random(1, 100) <= 5 then
			return true
		else
			return false
		end
	end
end

local function GetBaseRoomClearCharge()
	local addCharge = 1
	for largeRoom = RoomShape.ROOMSHAPE_2x2, RoomShape.NUM_ROOMSHAPES - 1 do
		local CurrentRoom = EEVEEMOD.game:GetLevel():GetCurrentRoom():GetRoomShape()
		if CurrentRoom == largeRoom then
			addCharge = 2
		end
	end
	return addCharge
end

local function DetermineActiveCharge(player, itemID, maxCharge)
	local chargeToAdd = VeeHelper.GetActiveItemCharges(player, EEVEEMOD.CollectibleType.STRANGE_EGG) + GetBaseRoomClearCharge()
	if AAABatteryProc(player, itemID, maxCharge) then
		chargeToAdd = chargeToAdd + 1
	end
	if WatchBatteryProc(player) and chargeToAdd < maxCharge then
		chargeToAdd = chargeToAdd + 1
	end
	return chargeToAdd
end ]]

local function strangeEggReward(player, charge)
	local heartToSpawn = VeeHelper.IsJudasBirthrightActive(player) and HeartSubType.HEART_BLACK or HeartSubType.HEART_FULL
	if charge == 1 then
		if player:GetHearts() ~= player:GetEffectiveMaxHearts() then
			player:AddHearts(6)
			EEVEEMOD.sfx:Play(SoundEffect.SOUND_VAMP_GULP)
		else
			Isaac.Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_HEART, heartToSpawn,
				EEVEEMOD.game:GetRoom():FindFreePickupSpawnPosition(player.Position, 2), Vector(0, 0), player)
		end

	elseif charge == 2 then
		Isaac.Spawn(5, 100, CollectibleType.COLLECTIBLE_BREAKFAST,
			EEVEEMOD.game:GetRoom():FindFreePickupSpawnPosition(player.Position, 2), Vector(0, 0), player)

		for _ = 1, 2 do
			Isaac.Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_HEART, heartToSpawn,
				EEVEEMOD.game:GetRoom():FindFreePickupSpawnPosition(player.Position, 2), Vector(0, 0), player)
		end
	elseif charge == 3 then
		Isaac.Spawn(5, 100, EEVEEMOD.CollectibleType.LIL_EEVEE,
			EEVEEMOD.game:GetRoom():FindFreePickupSpawnPosition(player.Position, 2), Vector(0, 0), player)

		for _ = 1, 2 do
			Isaac.Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_HEART, heartToSpawn,
				EEVEEMOD.game:GetRoom():FindFreePickupSpawnPosition(player.Position, 2), Vector(0, 0), player)
		end
	end
	if player:HasCollectible(CollectibleType.COLLECTIBLE_BOOK_OF_VIRTUES) then
		for _ = 1, charge do
			player:AddWisp(EEVEEMOD.CollectibleType.STRANGE_EGG, player.Position, true)
		end
	end
end

---@param itemID CollectibleType
---@param player EntityPlayer
function strangeEgg:onUse(itemID, _, player, _, _, _)
	if player:GetActiveCharge() > 0 then
		strangeEggReward(player, player:GetActiveCharge())
	end

	if player:GetBatteryCharge() > 0 then
		strangeEggReward(player, player:GetBatteryCharge())
	end

	EEVEEMOD.sfx:Play(SoundEffect.SOUND_FORTUNE_COOKIE)
	player:RemoveCollectible(EEVEEMOD.CollectibleType.STRANGE_EGG, false, ActiveSlot.SLOT_PRIMARY, true)
	return true
end

---@param player EntityPlayer
function strangeEgg:ChargeOnlyOnRoomClear(player)
	--[[
	if player:HasCollectible(EEVEEMOD.CollectibleType.STRANGE_EGG)
	and VeeHelper.RoomCleared == true then
		local itemConfig = Isaac.GetItemConfig()
		local eggObject = itemConfig:GetCollectible(EEVEEMOD.CollectibleType.STRANGE_EGG)
		local maxCharge = eggObject.MaxCharges
		
		if CheckItemCanCharge(player, EEVEEMOD.CollectibleType.STRANGE_EGG, maxCharge) then
			local newCharge = DetermineActiveCharge(player, EEVEEMOD.CollectibleType.STRANGE_EGG, maxCharge)
			
			player:SetActiveCharge(newCharge, VeeHelper.GetActiveSlots(player, EEVEEMOD.CollectibleType.STRANGE_EGG))
			EEVEEMOD.sfx:Play(SoundEffect.SOUND_BEEP)
		end
	end]]
end

---@param player EntityPlayer
---@return boolean
local function IsWarm(player)
	local hot = false

	local items = {
		CollectibleType.COLLECTIBLE_FIRE_MIND,
		CollectibleType.COLLECTIBLE_HOT_BOMBS,
		CollectibleType.COLLECTIBLE_MATCH_BOOK
	}
	for i = 1, #items do
		if player:HasCollectible(items[i]) then
			hot = true
		end
	end
	return hot
end

---@param player EntityPlayer
function strangeEgg:ChargeOnlyOnNewLevel(player)
	if not player:HasCollectible(EEVEEMOD.CollectibleType.STRANGE_EGG) then return end

	local currentCharges, slot = VeeHelper.GetActiveItemCharges(player, EEVEEMOD.CollectibleType.STRANGE_EGG)
	local chargeUp = IsWarm(player) and 2 or 1

	for i = 1, #currentCharges do
		local newCharge = currentCharges[i] + chargeUp
		if currentCharges[i] >= 3 and not player:HasCollectible(CollectibleType.COLLECTIBLE_THE_BATTERY) then return end

		if currentCharges[i] == 0 then
			EEVEEMOD.sfx:Play(SoundEffect.SOUND_BATTERYCHARGE)
		end
		player:SetActiveCharge(newCharge, slot[i])
	end
end

---@param player EntityPlayer
function strangeEgg:ForceItemUse(player)
	local data = player:GetData()

	if player:GetActiveItem(ActiveSlot.SLOT_PRIMARY) == EEVEEMOD.CollectibleType.STRANGE_EGG then
		if data.StrangeEggWait and data.StrangeEggWait > 0 then
			data.StrangeEggWait = data.StrangeEggWait - 1
		elseif not data.StrangeEggWait or data.StrangeEggWait == 0 then
			if player:GetActiveCharge(ActiveSlot.SLOT_PRIMARY) > 0
				and Input.IsActionTriggered(ButtonAction.ACTION_ITEM, player.ControllerIndex)
			then
				local useFlags = UseFlag.USE_OWNED | UseFlag.USE_REMOVEACTIVE
				if player:HasCollectible(CollectibleType.COLLECTIBLE_CAR_BATTERY) then
					useFlags = useFlags | UseFlag.USE_CAR_BATTERY
				end
				player:UseActiveItem(EEVEEMOD.CollectibleType.STRANGE_EGG, useFlags, ActiveSlot.SLOT_PRIMARY)
			end
		end
	elseif player:GetActiveItem(ActiveSlot.SLOT_SECONDARY) == EEVEEMOD.CollectibleType.STRANGE_EGG then
		data.StrangeEggWait = 15
	end
end

---@param familiar EntityFamiliar
function strangeEgg:OnStrangeEggWispDeath(familiar)
	if familiar.Variant ~= FamiliarVariant.WISP or familiar.SubType ~= EEVEEMOD.CollectibleType.STRANGE_EGG then return end
	Isaac.Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_HEART, HeartSubType.HEART_FULL, familiar.Position,
		Vector.Zero, nil)
end

return strangeEgg
