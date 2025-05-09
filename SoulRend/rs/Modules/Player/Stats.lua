-- PlayerStats.lua
local PlayerStats = {}

PlayerStats.DEFAULT_STATS = {
	-- Base Stats
	baseHealth = 100,
	baseMaxHealth = 100,
	baseStamina = 100,
	baseMaxStamina = 100,

	-- Combat Related Stats (these affect combat but aren't combat states)
	attack = 10,
	defense = 0,
	guard = 50,
	maxGuard = 100,

	-- Resources
	experience = 0,
	level = 1,
	mahni = 0
}

-- Calculation methods
function PlayerStats.calculateMaxHealth(level)
	return PlayerStats.DEFAULT_STATS.baseMaxHealth + (level * 10)
end

function PlayerStats.calculateMaxStamina(level)
	return PlayerStats.DEFAULT_STATS.baseMaxStamina + (level * 5)
end

-- Initialize a player's basic stats
function PlayerStats.initializePlayer(player)
	local character = player.Character
	if not character then return end

	local humanoid = character:FindFirstChild("Humanoid")
	if not humanoid then return end

	-- Set up health
	humanoid.MaxHealth = PlayerStats.calculateMaxHealth(PlayerStats.DEFAULT_STATS.level)
	humanoid.Health = humanoid.MaxHealth

	-- Set up stamina
	character:SetAttribute("MaxStamina", PlayerStats.calculateMaxStamina(PlayerStats.DEFAULT_STATS.level))
	character:SetAttribute("CurrentStamina", character:GetAttribute("MaxStamina"))

	-- Set up resources
	character:SetAttribute("Level", PlayerStats.DEFAULT_STATS.level)
	character:SetAttribute("Experience", PlayerStats.DEFAULT_STATS.experience)
	character:SetAttribute("Mahni", PlayerStats.DEFAULT_STATS.mahni)
end

-- Rest of PlayerStats methods...
return PlayerStats