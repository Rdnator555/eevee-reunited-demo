local shinyCharm = {}

local baseShinyChance = 4096
local forceSpawn = false

function shinyCharm:MakeNPCShiny(npc)
	local colorRNG = RNG()
	colorRNG:SetSeed(npc.Type + 1000, 35)
	local color = npc.Color
	local sprite = npc:GetSprite()
	if npc.Type == EntityType.ENTITY_HENRY then
		color:SetColorize(4, 2, 0.5, 1)
		sprite.Color = color
	else
		local r, g, b = (colorRNG:RandomInt(50) + 1) * 0.1, (colorRNG:RandomInt(50) + 1) * 0.1, (colorRNG:RandomInt(50) + 1) * 0.1
		color:SetColorize(r, g, b, 0.5)
		sprite.Color = color
	end
	local data = npc:GetData()

	npc:AddEntityFlags(EntityFlag.FLAG_FEAR)
	npc.MaxHitPoints = npc.MaxHitPoints * 4
	npc:AddHealth(npc.MaxHitPoints)
	data.ShinyColor = color
	data.IsShinyEnemy = true
	data.ShinyFleeTimer = 300
	EEVEEMOD.sfx:Play(EEVEEMOD.SoundEffect.SHINY_APPEAR)
	local shiny = Isaac.Spawn(EntityType.ENTITY_EFFECT, EEVEEMOD.EffectVariant.SHINY_APPEAR, 0, Vector(npc.Position.X, npc.Position.Y), Vector.Zero, npc):ToEffect()
	shiny.RenderZOffset = 100
	shiny.Parent = npc
	shiny:FollowParent(shiny.Parent)
end

function shinyCharm:TryMakeShinyOnNPCInit(npc)
	if npc.FrameCount <= 2 --If it makes through in its spawn frames
		and npc:IsActiveEnemy()
		and not npc:IsInvincible()
		and npc:IsVulnerableEnemy()
		and not npc:IsBoss()
		and not npc:IsChampion()
		and npc.Type ~= EntityType.ENITY_FIREPLACE
		and npc.Type ~= EntityType.ENTITY_SHOPKEEPER
		and not npc.SpawnerEntity
		and not npc:GetData().ShinyChecked --So it doesn't check multiple times
	then
		local players = VeeHelper.GetAllPlayers()
		local shinyRNG = baseShinyChance
		for i = 1, #players do
			local player = players[i]
			if player:HasCollectible(EEVEEMOD.CollectibleType.SHINY_CHARM) then
				shinyRNG = shinyRNG / (player:GetCollectibleNum(EEVEEMOD.CollectibleType.SHINY_CHARM) + 1)
			end
		end

		--Go through if shinies are enabled passively, and if not, require Shiny Charm (RNG being below 4096 means it triggered)
		if forceSpawn or ((EEVEEMOD.PERSISTENT_DATA.PassiveShiny == true or shinyRNG < baseShinyChance)
			and EEVEEMOD.RunSeededRNG:RandomInt(baseShinyChance) + 1 == shinyRNG) then
			shinyCharm:MakeNPCShiny(npc)
		end
		npc:GetData().ShinyChecked = true
	end
end

local frequency = 10
local duration = 25

function shinyCharm:ShinyColoredNPCUpdate(npc)
	local data = npc:GetData()

	if not data.IsShinyEnemy then return end

	if data.ShinyColor then
		npc:GetSprite().Color = data.ShinyColor
	end

	if npc.FrameCount % frequency == 0 then
		local sparkle = Isaac.Spawn(EntityType.ENTITY_EFFECT, EEVEEMOD.EffectVariant.SHINY_SPARKLE, 0, Vector(npc.Position.X, npc.Position.Y - 10), Vector.Zero, nil):ToEffect()
		local sprite = sparkle:GetSprite()
		sprite.Offset = Vector(EEVEEMOD.RandomNum(-20, 20), EEVEEMOD.RandomNum(10, 30) * -1)
		sprite.Rotation = EEVEEMOD.RandomNum(360)
		sparkle.FallingSpeed = EEVEEMOD.RandomNum(7, 13) * 0.1
		sparkle.Timeout = duration
	end

	if data.ShinyFleeTimer then
		if data.ShinyFleeTimer > 0 then
			data.ShinyFleeTimer = data.ShinyFleeTimer - 1
		else
			local poof = Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.POOF01, 0, npc.Position, Vector.Zero, npc):ToEffect()
			poof:GetSprite().PlaybackSpeed = 1.5
			npc:Remove()
		end
	end
end

function shinyCharm:PostShinyKill(npc)
	local data = npc:GetData()
	local pos = EEVEEMOD.game:GetRoom():FindFreePickupSpawnPosition(npc.Position)
	local dropRNG = RNG()
	dropRNG:SetSeed(npc.DropSeed, 35)
	local subType = EEVEEMOD.game:GetItemPool():GetTrinket(false) + TrinketType.TRINKET_GOLDEN_FLAG

	if data.IsShinyEnemy then
		EEVEEMOD.game:Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_TRINKET, pos, Vector.Zero, nil, subType, npc.DropSeed)
	end
end

function shinyCharm:Stats(player, itemStats)
	if player:HasCollectible(EEVEEMOD.CollectibleType.SHINY_CHARM) then
		itemStats.LUCK = itemStats.LUCK + (2 * player:GetCollectibleNum(EEVEEMOD.CollectibleType.SHINY_CHARM))
	end
end

function shinyCharm:ShinyParticleEffectUpdate(effect)
	local sprite = effect:GetSprite()
	local alpha = (effect.Timeout / duration)
	local eC = effect.Color
	effect:SetColor(VeeHelper.SetColorAlpha(eC, alpha), -1, 1, false, false)
	if sprite.Offset.Y < 0 then
		sprite.Offset = sprite.Offset + Vector(0, effect.FallingSpeed)
	end
	if effect.Timeout == 0 then
		effect:Remove()
	end
end

return shinyCharm
