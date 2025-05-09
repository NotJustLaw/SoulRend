local Players = game:GetService("Players")

local function setupCharacterHitboxes(character)
	-- Main hitbox
	local hitboxMain = Instance.new("Part")
	hitboxMain.Name = "HitboxMain"
	hitboxMain.Size = Vector3.new(3, 5, 3)
	hitboxMain.Transparency = 1
	hitboxMain.CanCollide = false

	local weld = Instance.new("Weld")
	weld.Part0 = character.HumanoidRootPart
	weld.Part1 = hitboxMain
	weld.Parent = hitboxMain

	hitboxMain.Parent = character
end

Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(setupCharacterHitboxes)
end)
