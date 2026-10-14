--!strict
-- StarterPlayerScripts/Client/Shop (ModuleScript)
-- Shop window: tabs for swords, object sets, scenes and Robux offers; a card per item with
-- a 3D preview, rarity colour and price or equip button. It only sends intents ("Buy" /
-- "Equip", Robux prompts); the server decides and grants.

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Catalog = require(Shared:WaitForChild("Catalog"))
local Config = require(Shared:WaitForChild("Config"))
local ObjectBuilder = require(Shared:WaitForChild("ObjectBuilder"))
local SwordBuilder = require(Shared:WaitForChild("SwordBuilder"))
local Hud = require(script.Parent:WaitForChild("Hud"))

type Card = { item: Catalog.Item, button: TextButton, frame: Frame, robux: TextButton? }

local PANEL_COLOR = Color3.fromRGB(25, 8, 18)
local CARD_COLOR = Color3.fromRGB(45, 20, 35)
local OWNED_COLOR = Color3.fromRGB(60, 120, 230)
local EQUIPPED_COLOR = Color3.fromRGB(70, 70, 80)
local BUY_COLOR = Color3.fromRGB(230, 160, 20)
local POOR_COLOR = Color3.fromRGB(120, 80, 40)

local Shop = {}

local remote: RemoteEvent
local panel: Frame
local coinLabel: TextLabel
local pages: { [string]: ScrollingFrame } = {}
local tabs: { [string]: TextButton } = {}
local cards: { [string]: { Card } } = {}
local coins = 0
local owned: { [string]: { [string]: boolean } } = {}
local equipped: { [string]: string } = {}
local hasDoubleCoins = false
local robuxRefresh: { () -> () } = {}

local function corner(parent: Instance, radius: number)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, radius)
	c.Parent = parent
end

-- Frames a model in a ViewportFrame: the camera looks at the bounding box from the front.
local function preview(parent: GuiObject, model: Model, angle: CFrame)
	local viewport = Instance.new("ViewportFrame")
	viewport.Size = UDim2.fromScale(1, 0.62)
	viewport.BackgroundTransparency = 1
	viewport.Ambient = Color3.fromRGB(170, 160, 170)
	viewport.LightColor = Color3.fromRGB(255, 250, 245)
	viewport.LightDirection = Vector3.new(-1, -1, -1)
	model:PivotTo(angle)
	model.Parent = viewport
	local cf, size = model:GetBoundingBox()
	local camera = Instance.new("Camera")
	camera.FieldOfView = 30
	-- fit height and width (preview area is about twice as wide as tall)
	local tanHalf = math.tan(math.rad(camera.FieldOfView) / 2)
	local distance = math.max(size.Y / (2 * tanHalf), size.X / (4 * tanHalf)) * 1.1 + size.Z / 2
	camera.CFrame = CFrame.lookAt(cf.Position + Vector3.new(0, 0, distance), cf.Position)
	camera.Parent = viewport
	viewport.CurrentCamera = camera
	viewport.Parent = parent
end

local function previewFor(category: string, item: Catalog.Item, parent: Frame)
	if category == "Swords" and item.Style then
		-- flat side to the camera, then tilted diagonally across the card
		preview(
			parent,
			SwordBuilder.Build(item.Style),
			CFrame.Angles(0, 0, math.rad(-55)) * CFrame.Angles(0, math.rad(90), 0)
		)
	elseif category == "Sets" and item.Kinds then
		local group = Instance.new("Model")
		local count = math.min(#item.Kinds, 3)
		for i = 1, count do
			local object = ObjectBuilder.Build(item.Kinds[i])
			object:PivotTo(
				CFrame.new((i - (count + 1) / 2) * 5.5, 0, 0) * CFrame.Angles(math.rad(10), math.rad(-15), 0)
			)
			object.Parent = group
		end
		preview(parent, group, CFrame.new())
	else
		local swatch = Instance.new("Frame")
		swatch.Size = UDim2.new(1, -12, 0.62, -12)
		swatch.Position = UDim2.fromOffset(6, 6)
		swatch.BackgroundColor3 = Color3.new(1, 1, 1)
		corner(swatch, 10)
		local gradient = Instance.new("UIGradient")
		local colors = item.Swatch or { Color3.new(1, 1, 1), Color3.new(0, 0, 0) }
		gradient.Color = ColorSequence.new(colors[1], colors[2])
		gradient.Rotation = 90
		gradient.Parent = swatch
		swatch.Parent = parent
	end
end

local function refreshCard(category: string, card: Card)
	local id = card.item.Id
	local stroke = card.frame:FindFirstChildOfClass("UIStroke") :: UIStroke
	local rarity = Catalog.Rarities[card.item.Rarity] or Catalog.Rarities.Common
	stroke.Color = rarity.Color
	if equipped[category] == id then
		card.button.Text = "AUSGERÜSTET"
		card.button.BackgroundColor3 = EQUIPPED_COLOR
		stroke.Thickness = 4
	elseif owned[category] and owned[category][id] then
		card.button.Text = "AUSRÜSTEN"
		card.button.BackgroundColor3 = OWNED_COLOR
		stroke.Thickness = 2
	else
		card.button.Text = `{card.item.Price} Münzen`
		card.button.BackgroundColor3 = if coins >= card.item.Price then BUY_COLOR else POOR_COLOR
		stroke.Thickness = 2
	end
	local robux = card.robux
	if robux then
		local isOwned = owned[category] and owned[category][id]
		robux.Visible = not isOwned
		local ready = (card.item.RobuxPassId or 0) ~= 0
		robux.Text = if ready then `oder {card.item.Robux} R$` else `oder {card.item.Robux} R$ (bald)`
		robux.BackgroundColor3 = if ready then Color3.fromRGB(0, 170, 90) else EQUIPPED_COLOR
	end
end

local function refresh()
	coinLabel.Text = if hasDoubleCoins then `Münzen: {coins}  (x2)` else `Münzen: {coins}`
	for category, list in cards do
		for _, card in list do
			refreshCard(category, card)
		end
	end
	for _, update in robuxRefresh do
		update()
	end
end

-- Small coloured tag in a card corner (rarity, coin bonus).
local function tag(parent: Frame, text: string, color: Color3, right: boolean)
	local l = Hud.Label({
		Text = text,
		AnchorPoint = Vector2.new(if right then 1 else 0, 0),
		Position = UDim2.new(if right then 1 else 0, if right then -8 else 8, 0, 6),
		Size = UDim2.new(0.45, 0, 0, 18),
		TextXAlignment = if right then Enum.TextXAlignment.Right else Enum.TextXAlignment.Left,
		TextColor3 = color,
		ZIndex = 3,
	})
	l.Parent = parent
end

local function makeCard(category: string, item: Catalog.Item, order: number, page: ScrollingFrame): Card
	local frame = Instance.new("Frame")
	frame.LayoutOrder = item.Price * 100 + order -- cheapest first
	frame.BackgroundColor3 = CARD_COLOR
	corner(frame, 12)
	local stroke = Instance.new("UIStroke")
	stroke.Parent = frame

	previewFor(category, item, frame)
	local rarity = Catalog.Rarities[item.Rarity] or Catalog.Rarities.Common
	tag(frame, rarity.Name, rarity.Color, false)
	if item.CoinBonus then
		tag(frame, `+{math.round(item.CoinBonus * 100)} % Münzen`, Config.CoinColor, true)
	end

	local name = Hud.Label({
		Text = item.Name,
		Position = UDim2.fromScale(0.05, 0.6),
		Size = UDim2.fromScale(0.9, 0.14),
	})
	name.Parent = frame

	local button = Hud.Button("", BUY_COLOR)
	button.AnchorPoint = Vector2.new(0.5, 1)
	button.Position = UDim2.fromScale(0.5, 0.96)
	button.Size = UDim2.fromScale(0.86, 0.18)
	button.Parent = frame
	button.Activated:Connect(function()
		if equipped[category] == item.Id then
			return
		end
		if owned[category] and owned[category][item.Id] then
			remote:FireServer("Equip", category, item.Id)
		elseif coins < item.Price then
			Hud.Toast(`Dir fehlen noch {item.Price - coins} Münzen`, Color3.fromRGB(255, 120, 120))
		else
			remote:FireServer("Buy", category, item.Id)
		end
	end)

	frame.Parent = page
	-- optional Robux price as a pill over the bottom of the preview
	local robux: TextButton? = nil
	if item.Robux then
		local pill = Hud.Button("", Color3.fromRGB(0, 170, 90))
		pill.AnchorPoint = Vector2.new(0.5, 0)
		pill.Position = UDim2.fromScale(0.5, 0.44)
		pill.Size = UDim2.fromScale(0.6, 0.14)
		pill.ZIndex = 4
		pill.Parent = frame
		pill.Activated:Connect(function()
			local passId = item.RobuxPassId or 0
			if passId ~= 0 then
				MarketplaceService:PromptGamePassPurchase(Players.LocalPlayer, passId)
			else
				Hud.Toast("Robux-Kauf ist noch nicht eingerichtet", Color3.fromRGB(255, 120, 120))
			end
		end)
		robux = pill
	end
	return { item = item, button = button, frame = frame, robux = robux }
end

-- Robux offers: the double-coins game pass and coin packs (developer products). The
-- purchase prompts come from Roblox; the server grants coins in ProcessReceipt.
local function robuxCard(page: ScrollingFrame, order: number, headline: string, name: string): (Frame, TextButton)
	local frame = Instance.new("Frame")
	frame.LayoutOrder = order
	frame.BackgroundColor3 = CARD_COLOR
	corner(frame, 12)
	local stroke = Instance.new("UIStroke")
	stroke.Color = Catalog.Rarities.Legendary.Color
	stroke.Thickness = 2
	stroke.Parent = frame
	local icon = Hud.CoinIcon(52)
	icon.AnchorPoint = Vector2.new(0.5, 0)
	icon.Position = UDim2.new(0.5, 0, 0, 14)
	icon.Parent = frame
	local big = Hud.Label({
		Text = headline,
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 72),
		Size = UDim2.new(0.9, 0, 0, 40),
		TextColor3 = Config.CoinColor,
	})
	big.Parent = frame
	local label = Hud.Label({
		Text = name,
		Position = UDim2.fromScale(0.05, 0.6),
		Size = UDim2.fromScale(0.9, 0.14),
	})
	label.Parent = frame
	local button = Hud.Button("", Color3.fromRGB(0, 170, 90))
	button.AnchorPoint = Vector2.new(0.5, 1)
	button.Position = UDim2.fromScale(0.5, 0.96)
	button.Size = UDim2.fromScale(0.86, 0.18)
	button.Parent = frame
	frame.Parent = page
	return frame, button
end

local function setRobuxButton(button: TextButton, id: number, robux: number, active: boolean)
	if active then
		button.Text = "AKTIV"
		button.BackgroundColor3 = EQUIPPED_COLOR
	elseif id == 0 then
		button.Text = "Bald verfügbar"
		button.BackgroundColor3 = EQUIPPED_COLOR
	else
		button.Text = `{robux} R$`
		button.BackgroundColor3 = Color3.fromRGB(0, 170, 90)
	end
end

local function buildRobuxPage(page: ScrollingFrame)
	local player = Players.LocalPlayer
	local pass = Catalog.Robux.DoubleCoins
	local _, passButton = robuxCard(page, 0, "x2", pass.Name)
	passButton.Activated:Connect(function()
		if pass.PassId ~= 0 and not hasDoubleCoins then
			MarketplaceService:PromptGamePassPurchase(player, pass.PassId)
		end
	end)
	table.insert(robuxRefresh, function()
		setRobuxButton(passButton, pass.PassId, pass.Robux, hasDoubleCoins)
	end)
	for i, pack in Catalog.Robux.CoinPacks do
		local _, button = robuxCard(page, i, `+{pack.Coins}`, "Münzpaket")
		button.Activated:Connect(function()
			if pack.ProductId ~= 0 then
				MarketplaceService:PromptProductPurchase(player, pack.ProductId)
			end
		end)
		table.insert(robuxRefresh, function()
			setRobuxButton(button, pack.ProductId, pack.Robux, false)
		end)
	end
end

local function showTab(category: string)
	for name, page in pages do
		page.Visible = name == category
		tabs[name].BackgroundColor3 = if name == category then Config.GlowColor else CARD_COLOR
	end
end

function Shop.Init(gameRemote: RemoteEvent)
	remote = gameRemote
	local gui = Hud.Gui()

	panel = Instance.new("Frame")
	panel.Name = "Shop"
	panel.AnchorPoint = Vector2.new(0.5, 0.5)
	panel.Position = UDim2.fromScale(0.5, 0.53)
	panel.Size = UDim2.fromScale(0.92, 0.8)
	panel.BackgroundColor3 = PANEL_COLOR
	panel.BackgroundTransparency = 0.05
	panel.Visible = false
	panel.Active = true -- swallow clicks so the menu behind it does not react
	panel.ZIndex = 10
	corner(panel, 18)
	local limit = Instance.new("UISizeConstraint")
	limit.MaxSize = Vector2.new(960, 640)
	limit.Parent = panel
	local border = Instance.new("UIStroke")
	border.Color = Config.CoinColor
	border.Thickness = 3
	border.Parent = panel

	local title = Hud.Label({
		Text = "SHOP",
		Position = UDim2.new(0, 16, 0, 10),
		Size = UDim2.new(0.3, 0, 0, 44),
		TextXAlignment = Enum.TextXAlignment.Left,
		TextColor3 = Config.CoinColor,
	})
	title.Parent = panel
	coinLabel = Hud.Label({
		Text = "Münzen: 0",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 12),
		Size = UDim2.new(0.3, 0, 0, 40),
		TextColor3 = Config.CoinColor,
	})
	coinLabel.Parent = panel
	local close = Hud.Button("X", Config.GlowColor) -- symbols like ✕ do not render in this font
	close.AnchorPoint = Vector2.new(1, 0)
	close.Position = UDim2.new(1, -12, 0, 10)
	close.Size = UDim2.fromOffset(48, 44)
	close.Parent = panel
	close.Activated:Connect(Shop.Close)

	local tabNames = table.clone(Catalog.Categories)
	table.insert(tabNames, "Robux")
	for i, category in tabNames do
		local tab = Hud.Button((Catalog.CategoryNames :: any)[category] or "Robux", CARD_COLOR)
		tab.Position = UDim2.new((i - 1) / #tabNames, if i == 1 then 16 else 6, 0, 64)
		tab.Size = UDim2.new(1 / #tabNames, -22, 0, 44)
		tab.Parent = panel
		tab.Activated:Connect(function()
			showTab(category)
		end)
		tabs[category] = tab

		local page = Instance.new("ScrollingFrame")
		page.Position = UDim2.new(0, 16, 0, 120)
		page.Size = UDim2.new(1, -32, 1, -134)
		page.BackgroundTransparency = 1
		page.BorderSizePixel = 0
		page.ScrollBarThickness = 8
		page.AutomaticCanvasSize = Enum.AutomaticSize.Y
		page.CanvasSize = UDim2.new()
		page.ScrollingDirection = Enum.ScrollingDirection.Y
		page.Visible = false
		local grid = Instance.new("UIGridLayout")
		grid.CellSize = UDim2.new(1 / 3, -10, 0, 210)
		grid.CellPadding = UDim2.fromOffset(10, 10)
		grid.SortOrder = Enum.SortOrder.LayoutOrder
		grid.Parent = page
		page.Parent = panel
		pages[category] = page

		if category == "Robux" then
			buildRobuxPage(page)
		else
			cards[category] = {}
			for order, item in (Catalog :: any)[category] :: { Catalog.Item } do
				table.insert(cards[category], makeCard(category, item, order, page))
			end
		end
	end
	showTab("Swords")
	panel.Parent = gui
	refresh()
end

function Shop.SetProfile(newCoins: number, newOwned: any, newEquipped: any, doubleCoins: boolean?)
	coins = newCoins
	owned = newOwned
	equipped = newEquipped
	hasDoubleCoins = doubleCoins == true
	refresh()
end

function Shop.Open()
	panel.Visible = true
end

function Shop.Close()
	panel.Visible = false
end

function Shop.IsOpen(): boolean
	return panel.Visible
end

return Shop
