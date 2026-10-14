--!strict
-- StarterPlayerScripts/Client/Hud (ModuleScript)
-- Score, lives, combo popups, swipe streaks and the start / game-over panels.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

local FONT = Enum.Font.FredokaOne
local WHITE = Color3.new(1, 1, 1)

local Hud = {}

local gui: ScreenGui
local scoreLabel: TextLabel
local scoreScale: UIScale
local hearts: { TextLabel } = {}
local flash: Frame
local menu: Frame
local menuTitle: TextLabel
local menuText: TextLabel
local menuButton: TextButton
local coinLabel: TextLabel
local coinScale: UIScale
local onStart: () -> () = function() end
local onShop: () -> () = function() end

local function label(props: { [string]: any }): TextLabel
	local l = Instance.new("TextLabel")
	l.BackgroundTransparency = 1
	l.Font = FONT
	l.TextColor3 = WHITE
	l.TextScaled = true
	for key, value in props do
		(l :: any)[key] = value
	end
	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 2.5
	stroke.Color = Color3.fromRGB(40, 0, 15)
	stroke.Parent = l
	return l
end

local function pop(target: GuiObject, scale: UIScale, amount: number)
	scale.Scale = amount
	TweenService:Create(scale, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 })
		:Play()
	local _ = target
end

-- Rounded button with scaled text, used by the menu and the shop.
function Hud.Button(text: string, color: Color3): TextButton
	local button = Instance.new("TextButton")
	button.BackgroundColor3 = color
	button.Font = FONT
	button.Text = text
	button.TextScaled = true
	button.TextColor3 = WHITE
	button.AutoButtonColor = true
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 12)
	corner.Parent = button
	local padding = Instance.new("UIPadding")
	padding.PaddingTop = UDim.new(0.15, 0)
	padding.PaddingBottom = UDim.new(0.15, 0)
	padding.PaddingLeft = UDim.new(0.05, 0)
	padding.PaddingRight = UDim.new(0.05, 0)
	padding.Parent = button
	return button
end

Hud.Label = label

-- A gold coin drawn from frames: rim and inner face.
function Hud.CoinIcon(size: number): Frame
	local coin = Instance.new("Frame")
	coin.Size = UDim2.fromOffset(size, size)
	coin.BackgroundColor3 = Color3.fromRGB(255, 200, 40)
	local round = Instance.new("UICorner")
	round.CornerRadius = UDim.new(1, 0)
	round.Parent = coin
	local rim = Instance.new("UIStroke")
	rim.Color = Color3.fromRGB(170, 100, 10)
	rim.Thickness = math.max(2, size / 12)
	rim.Parent = coin
	local face = Instance.new("Frame")
	face.AnchorPoint = Vector2.new(0.5, 0.5)
	face.Position = UDim2.fromScale(0.5, 0.5)
	face.Size = UDim2.fromScale(0.62, 0.62)
	face.BackgroundColor3 = Color3.fromRGB(255, 225, 90)
	local faceRound = Instance.new("UICorner")
	faceRound.CornerRadius = UDim.new(1, 0)
	faceRound.Parent = face
	local faceRim = Instance.new("UIStroke")
	faceRim.Color = Color3.fromRGB(215, 145, 20)
	faceRim.Thickness = math.max(1, size / 20)
	faceRim.Parent = face
	face.Parent = coin
	return coin
end

function Hud.Gui(): ScreenGui
	return gui
end

function Hud.Init(startCallback: () -> (), shopCallback: () -> ())
	onStart = startCallback
	onShop = shopCallback
	local player = Players.LocalPlayer
	gui = Instance.new("ScreenGui")
	gui.Name = "FruitHud"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

	flash = Instance.new("Frame")
	flash.Size = UDim2.fromScale(1, 1)
	flash.BackgroundColor3 = Color3.fromRGB(255, 0, 40)
	flash.BackgroundTransparency = 1
	flash.BorderSizePixel = 0
	flash.ZIndex = 0
	flash.Parent = gui

	scoreLabel = label({
		Text = "0",
		AnchorPoint = Vector2.new(0, 0),
		Position = UDim2.new(0, 24, 0, 58),
		Size = UDim2.new(0.3, 0, 0.09, 0),
		TextXAlignment = Enum.TextXAlignment.Left,
		TextColor3 = Color3.fromRGB(255, 225, 120),
	})
	scoreScale = Instance.new("UIScale")
	scoreScale.Parent = scoreLabel
	local sizeLimit = Instance.new("UITextSizeConstraint")
	sizeLimit.MaxTextSize = 64
	sizeLimit.Parent = scoreLabel
	scoreLabel.Parent = gui

	for i = 1, Config.Lives do
		local heart = label({
			Text = "♥",
			AnchorPoint = Vector2.new(1, 0),
			Position = UDim2.new(1, -20 - (Config.Lives - i) * 52, 0, 58),
			Size = UDim2.fromOffset(48, 48),
			TextColor3 = Color3.fromRGB(255, 50, 80),
		})
		local scale = Instance.new("UIScale")
		scale.Parent = heart
		heart.Parent = gui
		hearts[i] = heart
	end

	menu = Instance.new("Frame")
	menu.AnchorPoint = Vector2.new(0.5, 0.5)
	menu.Position = UDim2.fromScale(0.5, 0.5)
	menu.Size = UDim2.fromScale(0.5, 0.5)
	menu.BackgroundColor3 = Color3.fromRGB(25, 8, 18)
	menu.BackgroundTransparency = 0.25
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 18)
	corner.Parent = menu
	local aspect = Instance.new("UIAspectRatioConstraint")
	aspect.AspectRatio = 1.6
	aspect.Parent = menu
	local menuSize = Instance.new("UISizeConstraint")
	menuSize.MinSize = Vector2.new(300, 190)
	menuSize.MaxSize = Vector2.new(640, 400)
	menuSize.Parent = menu
	local border = Instance.new("UIStroke")
	border.Color = Config.GlowColor
	border.Thickness = 3
	border.Parent = menu

	menuTitle = label({
		Text = "KATANA-FRÜCHTE",
		Position = UDim2.fromScale(0.05, 0.06),
		Size = UDim2.fromScale(0.9, 0.24),
		TextColor3 = Color3.fromRGB(255, 80, 100),
	})
	menuTitle.Parent = menu
	menuText = label({
		Text = "Wisch mit dem Finger (oder gedrückter Maustaste) schnell über die fliegenden Objekte.\nKeine Bomben treffen! 3 verpasste = vorbei. Punkte werden zu Münzen für den Shop.",
		Position = UDim2.fromScale(0.07, 0.33),
		Size = UDim2.fromScale(0.86, 0.32),
		TextColor3 = Color3.fromRGB(240, 225, 230),
	})
	menuText.Parent = menu

	menuButton = Hud.Button("START", Config.GlowColor)
	menuButton.Name = "StartButton"
	menuButton.AnchorPoint = Vector2.new(0.5, 1)
	menuButton.Position = UDim2.fromScale(0.28, 0.92)
	menuButton.Size = UDim2.fromScale(0.4, 0.2)
	menuButton.Parent = menu
	menuButton.Activated:Connect(function()
		onStart()
	end)
	local shopButton = Hud.Button("SHOP", Color3.fromRGB(230, 160, 20))
	shopButton.Name = "ShopButton"
	shopButton.AnchorPoint = Vector2.new(0.5, 1)
	shopButton.Position = UDim2.fromScale(0.72, 0.92)
	shopButton.Size = UDim2.fromScale(0.4, 0.2)
	shopButton.Parent = menu
	shopButton.Activated:Connect(function()
		onShop()
	end)

	-- coin counter: drawn coin icon + number (emoji do not render in this font)
	local coinBox = Instance.new("Frame")
	coinBox.AnchorPoint = Vector2.new(0.5, 0)
	coinBox.Position = UDim2.new(0.5, 0, 0, 58)
	coinBox.Size = UDim2.fromOffset(0, 44)
	coinBox.AutomaticSize = Enum.AutomaticSize.X
	coinBox.BackgroundTransparency = 1
	local row = Instance.new("UIListLayout")
	row.FillDirection = Enum.FillDirection.Horizontal
	row.VerticalAlignment = Enum.VerticalAlignment.Center
	row.Padding = UDim.new(0, 8)
	row.Parent = coinBox
	Hud.CoinIcon(34).Parent = coinBox
	coinLabel = label({
		Text = "0",
		Size = UDim2.fromOffset(0, 40),
		AutomaticSize = Enum.AutomaticSize.X,
		TextScaled = false,
		TextSize = 38,
		TextColor3 = Config.CoinColor,
		LayoutOrder = 2,
	})
	coinLabel.Parent = coinBox
	coinScale = Instance.new("UIScale")
	coinScale.Parent = coinBox
	coinBox.Parent = gui

	menu.Parent = gui
	gui.Parent = player:WaitForChild("PlayerGui")
end

function Hud.SetScore(score: number)
	if scoreLabel.Text ~= tostring(score) then
		scoreLabel.Text = tostring(score)
		pop(scoreLabel, scoreScale, 1.35)
	end
end

function Hud.SetLives(lives: number)
	for i, heart in hearts do
		local alive = i <= lives
		local wasAlive = heart.TextColor3 ~= Color3.fromRGB(70, 60, 65)
		heart.TextColor3 = if alive then Color3.fromRGB(255, 50, 80) else Color3.fromRGB(70, 60, 65)
		if wasAlive and not alive then
			pop(heart, heart:FindFirstChildOfClass("UIScale") :: UIScale, 1.8)
		end
	end
end

function Hud.Flash(color: Color3, strength: number)
	flash.BackgroundColor3 = color
	flash.BackgroundTransparency = 1 - strength
	TweenService:Create(flash, TweenInfo.new(0.45, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		BackgroundTransparency = 1,
	}):Play()
end

-- Floating text at a screen position (viewport pixels), e.g. "+1" or "4er-KOMBO!".
function Hud.Popup(text: string, position: Vector2, color: Color3, size: number)
	local l = label({
		Text = text,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromOffset(position.X, position.Y),
		Size = UDim2.fromOffset(size * 4, size),
		TextColor3 = color,
	})
	local scale = Instance.new("UIScale")
	scale.Parent = l
	l.Parent = gui
	pop(l, scale, 1.8)
	TweenService:Create(l, TweenInfo.new(0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Position = UDim2.fromOffset(position.X, position.Y - size * 1.5),
		TextTransparency = 1,
	}):Play()
	local stroke = l:FindFirstChildOfClass("UIStroke")
	if stroke then
		TweenService:Create(stroke, TweenInfo.new(0.8), { Transparency = 1 }):Play()
	end
	task.delay(0.85, function()
		l:Destroy()
	end)
end

-- Juice drops hitting the "lens": blobs around a screen point that slide down and fade.
function Hud.Splat(position: Vector2, color: Color3, strength: number)
	local rng = Random.new()
	for _ = 1, math.floor(4 + strength * 4) do
		local size = rng:NextNumber(10, 34) * strength
		local offset = Vector2.new(rng:NextNumber(-1, 1), rng:NextNumber(-1, 1)) * 70 * strength
		local blob = Instance.new("Frame")
		blob.AnchorPoint = Vector2.new(0.5, 0.5)
		blob.Position = UDim2.fromOffset(position.X + offset.X, position.Y + offset.Y)
		blob.Size = UDim2.fromOffset(size, size * rng:NextNumber(0.8, 1.25))
		blob.BackgroundColor3 = color
		blob.BackgroundTransparency = 0.15
		blob.BorderSizePixel = 0
		blob.ZIndex = 0
		local round = Instance.new("UICorner")
		round.CornerRadius = UDim.new(1, 0)
		round.Parent = blob
		blob.Parent = gui
		local life = rng:NextNumber(0.6, 1.1)
		TweenService:Create(blob, TweenInfo.new(life, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
			Position = UDim2.fromOffset(position.X + offset.X, position.Y + offset.Y + rng:NextNumber(20, 60)),
			Size = UDim2.fromOffset(size * 0.6, size * 1.4),
			BackgroundTransparency = 1,
		}):Play()
		task.delay(life + 0.05, function()
			blob:Destroy()
		end)
	end
end

function Hud.SetCoins(coins: number)
	local text = tostring(coins)
	if coinLabel.Text ~= text then
		coinLabel.Text = text
		pop(coinLabel, coinScale, 1.3)
	end
end

-- Short message near the top of the screen (shop results).
function Hud.Toast(text: string, color: Color3)
	local l = label({
		Text = text,
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 108),
		Size = UDim2.new(0.6, 0, 0, 40),
		TextColor3 = color,
		ZIndex = 20,
	})
	l.Parent = gui
	TweenService:Create(l, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.In, 0, false, 1.6), {
		TextTransparency = 1,
	}):Play()
	local stroke = l:FindFirstChildOfClass("UIStroke")
	if stroke then
		TweenService
			:Create(stroke, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.In, 0, false, 1.6), {
				Transparency = 1,
			})
			:Play()
	end
	task.delay(2.1, function()
		l:Destroy()
	end)
end

-- Bright streak along the swipe (viewport pixels) in the sword's trail colours.
function Hud.Streak(a: Vector2, b: Vector2, colors: { Color3 })
	local delta = b - a
	local length = delta.Magnitude
	if length < 1 then
		return
	end
	local streak = Instance.new("Frame")
	streak.AnchorPoint = Vector2.new(0.5, 0.5)
	streak.Position = UDim2.fromOffset((a.X + b.X) / 2, (a.Y + b.Y) / 2)
	streak.Size = UDim2.fromOffset(length + 30, 7)
	streak.Rotation = math.deg(math.atan2(delta.Y, delta.X))
	streak.BackgroundColor3 = WHITE
	streak.BorderSizePixel = 0
	local gradient = Instance.new("UIGradient")
	gradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, colors[1]),
		ColorSequenceKeypoint.new(0.6, colors[#colors]),
		ColorSequenceKeypoint.new(1, WHITE),
	})
	gradient.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(0.5, 0.2),
		NumberSequenceKeypoint.new(1, 0),
	})
	gradient.Parent = streak
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(1, 0)
	corner.Parent = streak
	streak.Parent = gui
	TweenService:Create(streak, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Size = UDim2.fromOffset(length + 50, 0),
		BackgroundTransparency = 1,
	}):Play()
	task.delay(0.22, function()
		streak:Destroy()
	end)
end

function Hud.ShowMenu(title: string, text: string, button: string)
	menuTitle.Text = title
	menuText.Text = text
	menuButton.Text = button
	menu.Visible = true
end

function Hud.HideMenu()
	menu.Visible = false
end

return Hud
