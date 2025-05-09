-- ServerScriptService/ServerInit.lua
local ServerScriptService = game:GetService("ServerScriptService")

print("Server initialization starting...")

-- Get the Systems folder handle first
local SystemsFolder = ServerScriptService:FindFirstChild("Systems")
if not SystemsFolder then
	warn("Systems folder not found in ServerScriptService!")
	return
end

-- Get the CombatSystem module handle
local CombatSystemModule = SystemsFolder:FindFirstChild("CombatSystem")
if not CombatSystemModule then
	warn("CombatSystem not found in Systems folder!")
	return
end

print("Found CombatSystem at:", CombatSystemModule:GetFullName())

-- Require combat system
local success, CombatSystem = pcall(function()
	return require(CombatSystemModule)
end)

if success then
	print("CombatSystem loaded successfully")
	print("CombatSystem functions available:", CombatSystem ~= nil)

	-- Store in _G for other scripts
	_G.CombatSystem = CombatSystem
else
	warn("Failed to load CombatSystem:", CombatSystem)
end
