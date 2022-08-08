local cookieJar = {}

local function IsFat(player)
	local fatty = false

	local items = {
		CollectibleType.COLLECTIBLE_BUCKET_OF_LARD,
		CollectibleType.COLLECTIBLE_BINGE_EATER,
		CollectibleType.COLLECTIBLE_JUPITER,
		CollectibleType.COLLECTIBLE_CAMBION_CONCEPTION,
		CollectibleType.COLLECTIBLE_IMMACULATE_CONCEPTION
	}
	for i = 1, #items do
		if player:HasCollectible(items[i]) then
			fatty = true
		end
	end
	return fatty
end

local function UpdateCookieSpeedData(player)
	local ID = player:GetData().Identifier

	if EEVEEMOD.PERSISTENT_DATA.PlayerData[ID]
		and EEVEEMOD.PERSISTENT_DATA.PlayerData[ID].CookieSpeed
		and player.MoveSpeed >= 0.2
		and not IsFat(player)
	then
		EEVEEMOD.PERSISTENT_DATA.PlayerData[ID].CookieSpeed = EEVEEMOD.PERSISTENT_DATA.PlayerData[ID].CookieSpeed - 0.2
	end
end

function cookieJar:onUse(itemID, _, player, _, _, _)
	for i = 1, 6 do
		local cookieJarIDs = EEVEEMOD.CollectibleType.COOKIE_JAR[i]
		local cookieJarNextJar = EEVEEMOD.CollectibleType.COOKIE_JAR[i - 1]
		local cookieJarFinal = EEVEEMOD.CollectibleType.COOKIE_JAR[1]

		if itemID == cookieJarIDs and player:GetActiveItem() == cookieJarIDs then

			player:RemoveCollectible(cookieJarIDs)

			if itemID ~= cookieJarFinal then
				player:AddCollectible(cookieJarNextJar)
			else
				player:AddMaxHearts(4)
				player:AddHearts(2)
			end

			player:AddHearts(2)
			EEVEEMOD.sfx:Play(SoundEffect.SOUND_VAMP_GULP)

			UpdateCookieSpeedData(player)

			player:AddCacheFlags(CacheFlag.CACHE_SPEED)
			player:EvaluateItems()

			if player:HasCollectible(CollectibleType.COLLECTIBLE_BOOK_OF_VIRTUES)
			and itemID ~= EEVEEMOD.CollectibleType.COOKIE_JAR[2] --Literally have no clue why but #2 specifically doesn't even spawn a wisp
			then
				player:AddWisp(EEVEEMOD.CollectibleType.COOKIE_JAR[1], player.Position, true)
				local data = player:GetData()
				data.CookieJarRemoveWisp = true
			end
			return true
		end
	end
end

function cookieJar:Stats(player, itemStats)
	local ID = player:GetData().Identifier

	if EEVEEMOD.PERSISTENT_DATA.PlayerData[ID]
		and EEVEEMOD.PERSISTENT_DATA.PlayerData[ID].CookieSpeed
	then
		itemStats.SPEED = itemStats.SPEED + EEVEEMOD.PERSISTENT_DATA.PlayerData[ID].CookieSpeed
	end
end

function cookieJar:SpeedUpdate(player)
	local data = player:GetData()
	local cookieSpeedDelay = 30
	local ID = player:GetData().Identifier

	if EEVEEMOD.PERSISTENT_DATA.PlayerData[ID]
		and EEVEEMOD.PERSISTENT_DATA.PlayerData[ID].CookieSpeed
		and EEVEEMOD.PERSISTENT_DATA.PlayerData[ID].CookieSpeed < 0 then
		if not data.CookieSpeedWait then
			data.CookieSpeedWait = cookieSpeedDelay
			player:AddCacheFlags(CacheFlag.CACHE_SPEED)
			player:EvaluateItems()
		else
			if data.CookieSpeedWait <= 0 then
				EEVEEMOD.PERSISTENT_DATA.PlayerData[ID].CookieSpeed = EEVEEMOD.PERSISTENT_DATA.PlayerData[ID].CookieSpeed + 0.01
				player:AddCacheFlags(CacheFlag.CACHE_SPEED)
				player:EvaluateItems()
				data.CookieSpeedWait = cookieSpeedDelay
			end
			data.CookieSpeedWait = data.CookieSpeedWait - 1
		end
	end
end

return cookieJar
