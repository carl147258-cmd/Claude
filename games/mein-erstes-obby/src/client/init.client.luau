-- StarterPlayer/StarterPlayerScripts/Client (LocalScript)
-- Builds the HUD in code: stage display + "skip stage" button.

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

local player = Players.LocalPlayer

local gui = Instance.new("ScreenGui")
gui.Name = "ObbyHUD"
gui.ResetOnSpawn = false
gui.ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets

local stageLabel = Instance.new("TextLabel")
stageLabel.AnchorPoint = Vector2.new(0.5, 0)
stageLabel.Position = UDim2.new(0.5, 0, 0, 8)
stageLabel.Size = UDim2.new(0.3, 0, 0.07, 0)
stageLabel.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
stageLabel.BackgroundTransparency = 0.3
stageLabel.TextColor3 = Color3.new(1, 1, 1)
stageLabel.TextScaled = true
stageLabel.Font = Enum.Font.GothamBold
stageLabel.Text = "Lädt..."
Instance.new("UICorner").Parent = stageLabel
local sizeLimit = Instance.new("UISizeConstraint")
sizeLimit.MinSize = Vector2.new(160, 36)
sizeLimit.MaxSize = Vector2.new(360, 60)
sizeLimit.Parent = stageLabel
stageLabel.Parent = gui

local skipButton: TextButton? = nil
if Config.SkipStageProductId ~= 0 then
	local button = Instance.new("TextButton")
	button.AnchorPoint = Vector2.new(1, 1)
	button.Position = UDim2.new(1, -12, 1, -12)
	button.Size = UDim2.new(0.22, 0, 0.09, 0)
	button.BackgroundColor3 = Color3.fromRGB(0, 170, 90)
	button.TextColor3 = Color3.new(1, 1, 1)
	button.TextScaled = true
	button.Font = Enum.Font.GothamBold
	button.Text = "⏭ Stufe überspringen"
	Instance.new("UICorner").Parent = button
	local buttonLimit = Instance.new("UISizeConstraint")
	buttonLimit.MinSize = Vector2.new(140, 48) -- big enough for thumbs
	buttonLimit.MaxSize = Vector2.new(300, 70)
	buttonLimit.Parent = button
	button.Parent = gui

	button.Activated:Connect(function()
		MarketplaceService:PromptProductPurchase(player, Config.SkipStageProductId)
	end)
	skipButton = button
end

gui.Parent = player:WaitForChild("PlayerGui")

local stageValue = player:WaitForChild("leaderstats"):WaitForChild("Stufe") :: IntValue
local function refresh()
	if stageValue.Value >= Config.StageCount then
		stageLabel.Text = "🏆 Geschafft!"
	else
		stageLabel.Text = `Stufe {stageValue.Value} / {Config.StageCount}`
	end
	if skipButton then
		skipButton.Visible = stageValue.Value < Config.StageCount
	end
end
stageValue.Changed:Connect(refresh)
refresh()
