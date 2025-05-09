local DamageIndicator = {} --Basically the damage UI that appears in every hit

function DamageIndicator.new(position, damage)
	local billboardGui = Instance.new("BillboardGui")
	billboardGui.Name = "DamageNumber"
	billboardGui.Size = UDim2.new(0, 100, 0, 42)
	billboardGui.StudsOffset = Vector3.new(0, 2,0)
	billboardGui.AlwaysOnTop = true
	
	local damageLabel = Instance.new("TextLabel")
	damageLabel.Size = UDim2(1, 0, 1, 0)
	damageLabel.BackgroundTransparency = 1
	damageLabel.TextColor = Color3.fromRGB(255, 0, 0)
	damageLabel.TextScaled = true
	damageLabel.Font = Enum.Font.FredokaOne
	damageLabel.Parent = billboardGui
	
	billboardGui.Parent = position
	
	-- Animation for the damage Number
	local tweenService = game:GetService("TweenService")
	local tweenInfo = TweenInfo.new(
		0.5, --duration
		Enum.EasingStyle.Quad,
		Enum.EasingDirection.Out
	)
	
	local startPos = billboardGui.StudsOffset
	local endPos = startPos + Vector3.new(0, 2, 0)
	
	local positionTween = tweenService:Create(billboardGui, tweenInfo, {
		StudsOffset = endPos
	})
	
	local fadeOutTween = tweenService:Create(damageLabel, tweenInfo, {
		TextTransparency = 1
	})
	
	positionTween:Play()
	fadeOutTween:Play()
	
	fadeOutTween.Completed:Connect(function()
		billboardGui:Destroy()
	end)
	
	return billboardGui
end

return DamageIndicator
