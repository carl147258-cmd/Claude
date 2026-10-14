--!strict
-- ServerScriptService/Server/Shop (ModuleScript)
-- Handles "Buy" / "Equip" requests (validated against Catalog and the player's coins),
-- Robux offers (game pass + coin packs via ProcessReceipt), the daily reward, sends the
-- profile to the client and puts the equipped sword into the avatar's hand.

local MarketplaceService = game:GetService("MarketplaceService")
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
local doubleCoins: { [Player]: boolean } = {}

local Shop = {}

local function sendProfile(player: Player)
	local profile = PlayerData.GetProfile(player)
	if profile and player.Parent then
		remote:FireClient(
			player,
			"Profile",
			profile.Coins,
			profile.Owned,
			profile.Equipped,
			doubleCoins[player] == true,
			profile.DailyStreak
		)
	end
end

-- Coins per point for this player: equipped sword bonus, doubled with the game pass.
function Shop.CoinMultiplier(player: Player): number
	local sword = Catalog.Find("Swords", PlayerData.GetEquipped(player, "Swords"))
	local multiplier = Config.CoinsPerPoint * (1 + (sword and sword.CoinBonus or 0))
	if doubleCoins[player] then
		multiplier *= 2
	end
	return multiplier
end

local function checkDoubleCoins(player: Player)
	local passId = Catalog.Robux.DoubleCoins.PassId
	if passId == 0 then
		return
	end
	local ok, owns = pcall(function()
		return MarketplaceService:UserOwnsGamePassAsync(player.UserId, passId)
	end)
	if ok and owns and player.Parent then
		doubleCoins[player] = true
		sendProfile(player)
	end
end

-- Swords sold as game passes: ownership comes from Roblox, so it survives any data loss.
local function checkSwordPasses(player: Player)
	for _, item in Catalog.Swords do
		local passId = item.RobuxPassId
		if passId and passId ~= 0 then
			local ok, owns = pcall(function()
				return MarketplaceService:UserOwnsGamePassAsync(player.UserId, passId)
			end)
			if ok and owns and player.Parent then
				PlayerData.GrantItem(player, "Swords", item.Id, false)
			end
		end
	end
end

-- Developer products: grant coins exactly once and only after they are saved.
local function processReceipt(receipt: { [string]: any }): Enum.ProductPurchaseDecision
	local player = Players:GetPlayerByUserId(receipt.PlayerId)
	local pack = Catalog.CoinPackByProduct(receipt.ProductId)
	if not player or not pack then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	if not PlayerData.WaitForProfile(player) then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	if PlayerData.GrantPurchase(player, receipt.PurchaseId, pack.Coins) then
		remote:FireClient(player, "ShopResult", true, `+{pack.Coins} Münzen gekauft!`)
		return Enum.ProductPurchaseDecision.PurchaseGranted
	end
	return Enum.ProductPurchaseDecision.NotProcessedYet
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
	MarketplaceService.ProcessReceipt = processReceipt
	MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, passId, purchased)
		if not purchased or passId == 0 then
			return
		end
		if passId == Catalog.Robux.DoubleCoins.PassId then
			doubleCoins[player] = true
			remote:FireClient(player, "ShopResult", true, "Doppelte Münzen aktiviert!")
			sendProfile(player)
			return
		end
		local sword = Catalog.SwordByPass(passId)
		if sword then
			PlayerData.GrantItem(player, "Swords", sword.Id, true)
			remote:FireClient(player, "ShopResult", true, `{sword.Name} freigeschaltet!`)
		end
	end)
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
		task.spawn(function()
			checkDoubleCoins(player)
			if PlayerData.WaitForProfile(player) then
				checkSwordPasses(player)
				local reward, day = PlayerData.ClaimDaily(player)
				if reward then
					remote:FireClient(player, "Daily", reward, day)
				end
			end
		end)
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
		doubleCoins[player] = nil
	end)
end

return Shop
