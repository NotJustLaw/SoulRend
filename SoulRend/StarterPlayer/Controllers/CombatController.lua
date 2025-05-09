-- Services
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local rs = game:GetService("ReplicatedStorage")

-- Modules
local CombatCore = require(rs.Modules.Combat.CombatCore)

-- Remotes
local CombatRemotes = rs:WaitForChild("Remotes"):WaitForChild("Combat")
local attackEvent = CombatRemotes:WaitForChild("AttackEvent")
local blockEvent = CombatRemotes:WaitForChild("BlockEvent")
local parryEvent = CombatRemotes:WaitForChild("ParryEvent")
local damageEvent = CombatRemotes:WaitForChild("DamageEvent")

print("Testing RemoteEvent connection...")
local testSuccess = pcall(function()
	attackEvent:FireServer("TEST")
end)
print("Test fire completed:", testSuccess)

-- Player references
local player = Players.LocalPlayer
local Mouse = player:GetMouse()

-- Debug
local DEBUG = true
local function debugPrint(...)
	if DEBUG then
		print(...)
	end
end

-- Combat state
local playerCombatState = table.clone(CombatCore.COMBAT_STATS)
local lastParryTime = 0
local lastAttackTime = 0
local isOnCooldown = {
	attack = false,
	parry = false,
	block = false,
	finalCombo = false
}

-- Hitbox creation function
local function createHitbox(character, size)
	local hitbox = Instance.new("Part")
	hitbox.Size = size
	hitbox.Transparency = 1
	hitbox.CanCollide = false
	hitbox.Anchored = false
	hitbox.Name = "AttackHitbox"

	local weld = Instance.new("Weld")
	weld.Part0 = character.HumanoidRootPart
	weld.Part1 = hitbox
	weld.C0 = CFrame.new(0, 0, -2)
	weld.Parent = hitbox

	hitbox.Parent = character
	return hitbox
end

local function visualizeAttack(hitPosition)
	local character = player.Character
	if not character then return end

	local hrp = character:FindFirstChild("HumanoidRootPart")
	if not hrp then return end

	local arcPart = Instance.new("Part")
	arcPart.Size = Vector3.new(4, 4, 4)
	arcPart.Transparency = 0.5
	arcPart.CanCollide = false
	arcPart.Anchored = true
	arcPart.Color = Color3.fromRGB(255, 0, 0)

	if hitPosition then
		arcPart.CFrame = CFrame.new(hitPosition)
	else
		arcPart.CFrame = hrp.CFrame * CFrame.new(0, 0, -2)
	end

	arcPart.Parent = workspace
	game:GetService("Debris"):AddItem(arcPart, 0.1)
end

local function performAttackRaycast(character, overrideComboCount)
	if not character then return end

	local hrp = character:FindFirstChild("HumanoidRootPart")
	if not hrp then return end

	local hitbox = createHitbox(character, Vector3.new(4, 4, 4))
	local hitDetected = false
	local hitTarget = nil
	local touchConnection

	touchConnection = hitbox.Touched:Connect(function(part)
		if hitDetected then return end

		local model = part.Parent
		if not model then return end

		if model:FindFirstChild("Humanoid") or model.Name == "Dummy" then
			hitDetected = true
			hitTarget = model

			-- Disconnect the connection immediately to prevent double hits
			if touchConnection then
				touchConnection:Disconnect()
			end

			print("=====================================")
			print("COMBAT CONTROLLER - HIT DETECTED")
			print("Target acquired:")
			print("- Name:", model.Name)
			print("- Has Humanoid:", model:FindFirstChild("Humanoid") ~= nil)
			if model:FindFirstChild("Humanoid") then
				print("- Health:", model.Humanoid.Health)
			end

			-- Use override combo count if provided, otherwise use current combo
			local comboCount = overrideComboCount or playerCombatState.currentCombo
			print("Sending to server with combo:", comboCount)

			local success, err = pcall(function()
				attackEvent:FireServer(model, comboCount)
			end)
			print("Send success:", success)
			if not success then
				warn("Send error:", err)
			end

			visualizeAttack(part.Position)
			print("=====================================")
		end
	end)

	game:GetService("Debris"):AddItem(hitbox, 0.1)
	return hitTarget
end

local function handleComboReset()
	playerCombatState.currentCombo = 0
	playerCombatState.isInComboChain = false
	playerCombatState.lastComboTime = 0
	debugPrint("Combo reset")
end

local function canAttack()
	if isOnCooldown.attack then
		debugPrint("On attack cooldown")
		return false
	end

	if isOnCooldown.finalCombo then
		debugPrint("On final combo cooldown")
		return false
	end

	if playerCombatState.isParried then
		debugPrint("Player is parried")
		return false
	end

	return true
end

local function handleM1Attack()
	local character = player.Character
	if not character then return end

	if not canAttack() then return end

	local currentTime = tick()

	-- Check if this will be the 5th hit
	if playerCombatState.currentCombo == 4 then
		debugPrint("5th hit - Setting final cooldown")

		-- Set final combo cooldown
		isOnCooldown.finalCombo = true
		isOnCooldown.attack = true

		-- Increment combo before the hit
		playerCombatState.currentCombo += 1

		-- Perform attack with combo count 5
		local hitTarget = performAttackRaycast(character, 5)

		-- Reset combo after the hit
		playerCombatState.currentCombo = 0
		playerCombatState.isInComboChain = false

		-- Clear final combo cooldown
		task.delay(CombatCore.COOLDOWNS.comboChainCooldown, function()
			debugPrint("Final combo cooldown cleared")
			isOnCooldown.finalCombo = false
			isOnCooldown.attack = false
		end)
	else
		-- Regular hit (1-4)
		playerCombatState.currentCombo += 1
		local hitTarget = performAttackRaycast(character)
	end

	playerCombatState.lastComboTime = currentTime

	-- Set attack cooldown
	isOnCooldown.attack = true
	lastAttackTime = currentTime

	-- Clear regular attack cooldown
	task.delay(CombatCore.COOLDOWNS.m1Cooldowns, function()
		if not isOnCooldown.finalCombo then
			isOnCooldown.attack = false
			debugPrint("Regular cooldown cleared")
		end
	end)
end

local function handleBlock(isBlocking)
	if isBlocking and playerCombatState.currentGuard <= 0 then return end
	playerCombatState.isBlocking = isBlocking
	blockEvent:FireServer(isBlocking)
end

local function handleParry()
	if isOnCooldown.parry then return end

	local currentTime = tick()
	if currentTime - lastParryTime < CombatCore.COOLDOWNS.parryCooldown then
		return
	end

	isOnCooldown.parry = true
	lastParryTime = currentTime

	local hitPlayer = performAttackRaycast(player.Character)
	if hitPlayer then
		parryEvent:FireServer(hitPlayer)
		player:SetAttribute("LastParryTime", currentTime)
	end

	task.delay(CombatCore.COOLDOWNS.parryCooldown, function()
		isOnCooldown.parry = false
	end)
end

-- Combo timeout checker
RunService.Heartbeat:Connect(function()
	if playerCombatState.isInComboChain then
		local currentTime = tick()
		if currentTime - playerCombatState.lastComboTime > CombatCore.COOLDOWNS.comboResetTime then
			handleComboReset()
		end
	end
end)

-- Input handling
Mouse.Button1Down:Connect(handleM1Attack)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end

	if input.KeyCode == Enum.KeyCode.F then
		handleBlock(true)
	elseif input.KeyCode == Enum.KeyCode.T then
		handleParry()
	end
end)

UserInputService.InputEnded:Connect(function(input, gameProcessed)
	if gameProcessed then return end

	if input.KeyCode == Enum.KeyCode.F then
		handleBlock(false)
	end
end)

-- Handle damage feedback
damageEvent.OnClientEvent:Connect(function(target, damage, isParryDamage)
	if typeof(target) == "Instance" and target:IsA("Model") then
		-- It's a dummy
		local humanoidRootPart = target:FindFirstChild("HumanoidRootPart")
		if humanoidRootPart then
			visualizeAttack(humanoidRootPart.Position)
		end
	else
		-- It's a player
		if target and target.Character then
			local humanoidRootPart = target.Character:FindFirstChild("HumanoidRootPart")
			if humanoidRootPart then
				visualizeAttack(humanoidRootPart.Position)
			end
		end
	end
end)
