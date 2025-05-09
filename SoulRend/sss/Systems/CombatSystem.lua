local CombatSystem = {}

-- Services
local rs = game:GetService("ReplicatedStorage")
print("1. Starting CombatSystem initialization...")

-- Modules
local CombatCore = require(rs.Modules.Combat.CombatCore)
print("2. CombatCore loaded")
print("M1 Damage array:", table.concat(CombatCore.DAMAGE.m1Damage, ", "))

-- Remotes
local CombatRemotes = rs:WaitForChild("Remotes"):WaitForChild("Combat")
print("3. CombatRemotes found:", CombatRemotes ~= nil)

local attackEvent = CombatRemotes:WaitForChild("AttackEvent")
local blockEvent = CombatRemotes:WaitForChild("BlockEvent")
local parryEvent = CombatRemotes:WaitForChild("ParryEvent")
local damageEvent = CombatRemotes:WaitForChild("DamageEvent")

print("4. Setting up test handler...")

-- State Management
local alreadyProcessing = {}
local playerStates = {}

-- Helper Functions
local function debugPrint(...)
	print("[CombatSystem]", ...)
end

-- Core Functions
function CombatSystem.initializePlayer(player)
	debugPrint("Initializing player:", player.Name)
	playerStates[player] = {
		currentCombo = 0,
		isInComboChain = false,
		lastComboTime = 0,
		comboChainCooldown = false,
		isBlocking = false,
		isParried = false
	}
end

function CombatSystem.handleAttack(attacker, target, comboCount)
	if not attacker or not target then 
		debugPrint("Invalid attacker or target")
		return 
	end

	debugPrint("Processing attack from:", attacker.Name)
	debugPrint("Target Type:", typeof(target))
	debugPrint("Target Name:", target.Name)
	debugPrint("Incoming combo count:", comboCount)

	local targetHumanoid
	if typeof(target) == "Instance" then
		if target.Name == "Dummy" then
			targetHumanoid = target:FindFirstChild("Humanoid")
			debugPrint("Found dummy humanoid:", targetHumanoid ~= nil)
		else
			-- Player case
			local character = target.Character
			if character then
				targetHumanoid = character:FindFirstChild("Humanoid")
				debugPrint("Found player humanoid:", targetHumanoid ~= nil)
			end
		end
	end

	if not targetHumanoid then
		debugPrint("No humanoid found in target")
		return
	end

	-- Calculate and apply damage
	local arrayIndex = math.max(0, (comboCount >= 5) and 4 or (comboCount - 1))  -- Use index 4 for 5th hit
	local damage = CombatCore.DAMAGE.m1Damage[arrayIndex] or CombatCore.DAMAGE.m1Damage[0]

	debugPrint("Array Index:", arrayIndex)
	debugPrint("Damage Amount:", damage)
	debugPrint("Current Health:", targetHumanoid.Health)

	local oldHealth = targetHumanoid.Health
	targetHumanoid.Health = math.max(0, oldHealth - damage)

	debugPrint("New Health:", targetHumanoid.Health)
	debugPrint("Health Change:", oldHealth - targetHumanoid.Health)

	-- Notify clients about the hit
	damageEvent:FireAllClients(target, damage)

	return damage
end

-- Event Connections
print("5. Setting up event handlers...")

attackEvent.OnServerEvent:Connect(function(player, target, comboCount)
	print("=====================================")
	print("COMBAT SYSTEM - ATTACK RECEIVED")
	print("From Player:", player.Name)
	print("Target Type:", typeof(target))
	print("Target Name:", target and target.Name)
	print("Combo Count:", comboCount)

	local success, result = pcall(function()
		return CombatSystem.handleAttack(player, target, comboCount)
	end)

	if success then
		print("Attack processed successfully")
		print("Damage dealt:", result)
	else
		warn("Error processing attack:", result)
	end
	print("=====================================")
end)

blockEvent.OnServerEvent:Connect(function(player, isBlocking)
	CombatSystem.handleBlock(player, isBlocking)
end)

parryEvent.OnServerEvent:Connect(function(player, target)
	CombatSystem.handleParry(player, target)
end)

-- Player Management
game.Players.PlayerAdded:Connect(function(player)
	debugPrint("Player joined:", player.Name)
	CombatSystem.initializePlayer(player)
end)

game.Players.PlayerRemoving:Connect(function(player)
	debugPrint("Player left:", player.Name)
	playerStates[player] = nil
end)

print("6. CombatSystem initialization complete!")
return CombatSystem
