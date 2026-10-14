--!strict
-- ServerScriptService/Server/Shop (ModuleScript)
-- Handles "Buy" / "Equip" requests (validated against Catalog and the player's coins),
-- sends the profile to the client and puts the equipped sword into the avatar's hand.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Catalog = require(Shared:WaitForChild("Catalog"))
local Config = require(Shared:WaitForChild("Config"))
local SwordBuilder = require(Shared:WaitForChild("SwordBuilder"))
local PlayerData = require(script.Parent.PlayerData)

local SWORD_SCALE = 1.25 -- seen from ~12 studs behind the avatar, so chunkier than life

local remote: RemoteEvent
local lastRequest: { [Player]: number } = {}

local Shop = {}

local function sendProfile(player: Player)
	local profile = PlayerData.GetProfile(player)
	if profile and player.Parent then
		remote:FireClient(player, "Profile", profile.Coins, profile.Owned, profile.Equipped)
	end
end

-- Builds the equipped sword and welds it to the right hand (R15) or right arm (R6).
-- The blade continues the arm, so the client can aim the whole arm at the pointer.
function Shop.ApplySword(player: Player)
	local character = player.Character
	if not character then
		return
	end
	local hand = (character:FindFirstChild("RightHand") or character:FindFirstChild("Right Arm")) :: BasePart?
	if not hand then
		return
	end
	local old = character:FindFirstChild("Sword")
	if old then
		old:Destroy()
	end
	local id = PlayerData.GetEquipped(player, "Swords")
	local item = Catalog.Find("Swords", id) or Catalog.Find("Swords", Catalog.Defaults.Swords)
	if not item or not item.Style then
		return
	end
	local sword = SwordBuilder.Build(item.Style, SWORD_SCALE)
	sword:SetAttribute("SwordId", item.Id)
	local handle = sword.PrimaryPart :: BasePart
	for _, part in sword:GetDescendants() do
		if part:IsA("BasePart") then
			part.Anchored = false
			part.Massless = true
		end
	end
	-- Hand -Y points away from the shoulder; the blade (+Y) continues that direction.
	-- A Weld (not WeldConstraint) so the owning client can roll the blade around the arm
	-- axis locally and show its flat side to the camera.
	local gripOffset = if hand.Name == "RightHand" then -0.15 else -0.9
	local grip = Instance.new("Weld")
	grip.Name = "SwordGrip"
	grip.Part0 = hand
	grip.Part1 = handle
	grip.C0 = CFrame.new(0, gripOffset, 0) * CFrame.Angles(math.pi, 0, 0)
	grip.Parent = handle
	sword.Parent = character
end

local function onRequest(player: Player, action: string, category: any, id: any)
	local t = os.clock()
	if t - (lastRequest[player] or 0) < Config.ShopRateLimit then
		return
	end
	lastRequest[player] = t
	if not Catalog.IsCategory(category) or typeof(id) ~= "string" or #id > 40 then
		return
	end
	if action == "Buy" then
		local ok, message = PlayerData.Buy(player, category, id)
		remote:FireClient(player, "ShopResult", ok, message)
	elseif action == "Equip" then
		PlayerData.Equip(player, category, id)
	end
	sendProfile(player)
end

function Shop.Start(gameRemote: RemoteEvent)
	remote = gameRemote
	remote.OnServerEvent:Connect(function(player, action: any, category: any, id: any)
		if action == "Buy" or action == "Equip" then
			onRequest(player, action, category, id)
		elseif action == "GetProfile" then
			sendProfile(player)
		end
	end)

	local equippedSword: { [Player]: string } = {}
	PlayerData.OnChanged(function(player)
		sendProfile(player)
		local sword = PlayerData.GetEquipped(player, "Swords")
		if equippedSword[player] ~= sword then
			equippedSword[player] = sword
			Shop.ApplySword(player)
		end
	end)

	local function onPlayerAdded(player: Player)
		if RunService:IsStudio() then
			-- Studio-only test hook: set the attribute on the server (command bar / MCP)
			-- to grant coins. Clients cannot set server attributes, and live servers skip it.
			player:GetAttributeChangedSignal("StudioGrantCoins"):Connect(function()
				local amount = player:GetAttribute("StudioGrantCoins")
				if typeof(amount) == "number" then
					PlayerData.AddCoins(player, amount)
					player:SetAttribute("StudioGrantCoins", nil)
				end
			end)
		end
		player.CharacterAdded:Connect(function(character)
			character:WaitForChild("Humanoid")
			character:WaitForChild("RightHand", 5)
			PlayerData.WaitForProfile(player)
			Shop.ApplySword(player)
		end)
		if player.Character then
			task.spawn(Shop.ApplySword, player)
		end
	end
	Players.PlayerAdded:Connect(onPlayerAdded)
	for _, player in Players:GetPlayers() do
		task.spawn(onPlayerAdded, player)
	end
	Players.PlayerRemoving:Connect(function(player)
		lastRequest[player] = nil
		equippedSword[player] = nil
	end)
end

return Shop
