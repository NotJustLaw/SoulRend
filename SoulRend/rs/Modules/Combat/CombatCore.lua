local CombatCore = {}

-- Store player states in a table
local playerStates = {}

-- Constants for combat
CombatCore.COMBAT_STATS = {
	-- Existing stats
	currentGuard = 100,
	maxGuard = 100,
	canAttack = true,
	isBlocking = false,
	isParried = false,

	-- New combo related stats
	currentCombo = 0,        -- Current position in combo chain (0-4 for 5 hits)
	lastComboTime = 0,       -- Time of last combo hit
	isInComboChain = false,  -- Whether player is currently in an active combo
	comboChainCooldown = false -- Whether the full chain cooldown is active
}

CombatCore.COOLDOWNS = {
	m1Cooldowns = 0.3,        -- Cooldown between individual M1s
	comboChainCooldown = 1.5, -- Cooldown after completing full chain
	comboResetTime = 1.5,     -- Time before combo resets if inactive
	parryCooldown = 2,
	blockCooldown = 0.5
}

CombatCore.DAMAGE = {
	m1Damage = {  -- All regular hits do 10, last hit does 20
		[0] = 10, -- First hit (combo count 1)
		[1] = 10, -- Second hit (combo count 2)
		[2] = 10, -- Third hit (combo count 3)
		[3] = 10, -- Fourth hit (combo count 4)
		[4] = 20  -- Final hit (combo count 5)
	},
	criticalDamage = 20,
	parryDamage = 5
}

-- Helper function to get/create player combat state
function CombatCore.getPlayerCombatState(player)
	if not playerStates[player.UserId] then
		playerStates[player.UserId] = table.clone(CombatCore.COMBAT_STATS)
	end
	return playerStates[player.UserId]
end

-- Combat validation functions
function CombatCore.canStartCombo(player)
	local state = CombatCore.getPlayerCombatState(player)
	return state.canAttack and not state.comboChainCooldown
end

function CombatCore.canContinueCombo(player)
	local state = CombatCore.getPlayerCombatState(player)
	local currentTime = tick()

	if currentTime - state.lastComboTime > CombatCore.COOLDOWNS.comboResetTime then
		return false
	end

	return state.canAttack and state.isInComboChain
end

function CombatCore.advanceCombo(player)
	local state = CombatCore.getPlayerCombatState(player)

	if not state.isInComboChain then
		state.currentCombo = 0
		state.isInComboChain = true
	else
		state.currentCombo = (state.currentCombo + 1) % 5
	end

	state.lastComboTime = tick()

	if state.currentCombo == 0 then
		state.comboChainCooldown = true
		state.isInComboChain = false

		task.delay(CombatCore.COOLDOWNS.comboChainCooldown, function()
			if playerStates[player.UserId] then
				state.comboChainCooldown = false
			end
		end)
	end

	return state.currentCombo
end

function CombatCore.resetCombo(player)
	local state = CombatCore.getPlayerCombatState(player)
	state.currentCombo = 0
	state.isInComboChain = false
	state.lastComboTime = 0
	state.comboChainCooldown = false
end

-- Clean up player state when they leave
game.Players.PlayerRemoving:Connect(function(player)
	playerStates[player.UserId] = nil
end)

function CombatCore.canBlock(player)
	local state = CombatCore.getPlayerCombatState(player)
	return state.currentGuard > 0
end

function CombatCore.canParry(player)
	return not player:GetAttribute("LastParryTime") or 
		tick() - player:GetAttribute("LastParryTime") >= CombatCore.COOLDOWNS.parryCooldown
end

return CombatCore