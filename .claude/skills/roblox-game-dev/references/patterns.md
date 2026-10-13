# Proven Luau Patterns for Roblox

Copy-ready patterns. Adapt names, keep the safety properties.

## Table of contents
1. Player lifecycle
2. Secure RemoteEvent handler (validation + rate limit)
3. DataStore (load / save / autosave / BindToClose)
4. Leaderstats
5. Monetization: Game Passes & Developer Products (ProcessReceipt)
6. Tag-driven behavior (CollectionService)
7. Round / game-state loop
8. Client UI binding
9. Cooldowns, debounce, hit detection
10. Global leaderboard (OrderedDataStore)
11. Teleporting between places

---

## 1. Player lifecycle

```lua
-- ServerScriptService/PlayerLifecycle (Script)
local Players = game:GetService("Players")

local function onCharacterAdded(player: Player, character: Model)
	local humanoid = character:WaitForChild("Humanoid") :: Humanoid
	humanoid.Died:Connect(function()
		-- handle death (stats, respawn rules, etc.)
	end)
end

local function onPlayerAdded(player: Player)
	player.CharacterAdded:Connect(function(character)
		onCharacterAdded(player, character)
	end)
	if player.Character then
		onCharacterAdded(player, player.Character)
	end
end

Players.PlayerAdded:Connect(onPlayerAdded)
for _, player in Players:GetPlayers() do -- players who joined before this ran
	task.spawn(onPlayerAdded, player)
end
```

## 2. Secure RemoteEvent handler

```lua
-- ServerScriptService/ShopServer (Script)
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local BuyItem = Remotes:WaitForChild("BuyItem") :: RemoteEvent

local ITEMS = { -- server-side source of truth for prices
	Sword = 100,
	Shield = 250,
}
local COOLDOWN = 0.5
local lastRequest: { [Player]: number } = {}

BuyItem.OnServerEvent:Connect(function(player: Player, itemName: unknown)
	-- 1. rate limit
	local now = os.clock()
	if lastRequest[player] and now - lastRequest[player] < COOLDOWN then
		return
	end
	lastRequest[player] = now

	-- 2. type + whitelist validation (never trust a price sent by the client)
	if typeof(itemName) ~= "string" then return end
	local price = ITEMS[itemName]
	if not price then return end

	-- 3. state validation
	local coins = player:FindFirstChild("leaderstats") and player.leaderstats:FindFirstChild("Coins")
	if not coins or coins.Value < price then return end

	coins.Value -= price
	-- grant item here (clone from ServerStorage into player.Backpack, update profile data, ...)
end)

Players.PlayerRemoving:Connect(function(player)
	lastRequest[player] = nil
end)
```

Validation cheat-sheet:
- Numbers: `typeof(x) == "number" and x == x` (rejects NaN) `and x >= min and x <= max`; use `math.floor` for counts.
- Instances: `typeof(x) == "Instance" and x:IsDescendantOf(workspace.Targets)`.
- Distance: compare server-side `HumanoidRootPart.Position` against target with a generous tolerance (latency).
- Vectors/CFrames: check `typeof`, and that components are finite.

## 3. DataStore

For production games with trading or purchases, prefer **ProfileStore** (session locking built in). For simpler games this pattern is safe:

```lua
-- ServerScriptService/Data/PlayerData (ModuleScript)
--!strict
local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")

local STORE = DataStoreService:GetDataStore("PlayerData_v1")
local AUTOSAVE_INTERVAL = 90
local MAX_RETRIES = 5

local DEFAULT_DATA = {
	Version = 1,
	Coins = 0,
	Level = 1,
	Inventory = {},
}

export type Data = typeof(DEFAULT_DATA)

local PlayerData = {}
local cache: { [Player]: Data } = {}
local loadFailed: { [Player]: boolean } = {}

local function deepCopy<T>(t: T): T
	if typeof(t) ~= "table" then return t end
	local copy = {}
	for k, v in t :: any do
		copy[k] = deepCopy(v)
	end
	return copy :: any
end

local function reconcile(data: any, template: any)
	for k, v in template do
		if data[k] == nil then
			data[k] = deepCopy(v)
		elseif typeof(v) == "table" and typeof(data[k]) == "table" then
			reconcile(data[k], v)
		end
	end
end

local function withRetries<T>(fn: () -> T): (boolean, T?)
	for attempt = 1, MAX_RETRIES do
		local ok, result = pcall(fn)
		if ok then return true, result end
		warn(`DataStore attempt {attempt} failed: {result}`)
		task.wait(2 ^ attempt)
	end
	return false, nil
end

local function key(player: Player): string
	return `Player_{player.UserId}`
end

function PlayerData.Load(player: Player): Data?
	local ok, stored = withRetries(function()
		return STORE:GetAsync(key(player))
	end)
	if not ok then
		loadFailed[player] = true
		player:Kick("Could not load your data. Please rejoin.")
		return nil
	end
	local data = (stored or deepCopy(DEFAULT_DATA)) :: Data
	reconcile(data, DEFAULT_DATA)
	cache[player] = data
	return data
end

function PlayerData.Get(player: Player): Data?
	return cache[player]
end

function PlayerData.Save(player: Player)
	if loadFailed[player] then return end -- never overwrite real data with defaults
	local data = cache[player]
	if not data then return end
	withRetries(function()
		return STORE:UpdateAsync(key(player), function(_old)
			return data
		end)
	end)
end

Players.PlayerRemoving:Connect(function(player)
	PlayerData.Save(player)
	cache[player] = nil
	loadFailed[player] = nil
end)

game:BindToClose(function()
	local threads = {}
	for _, player in Players:GetPlayers() do
		table.insert(threads, task.spawn(PlayerData.Save, player))
	end
	-- BindToClose gives ~30 s; wait for saves to finish
	local deadline = os.clock() + 25
	while os.clock() < deadline do
		local allDone = true
		for _, t in threads do
			if coroutine.status(t) ~= "dead" then allDone = false break end
		end
		if allDone then break end
		task.wait(0.5)
	end
end)

task.spawn(function()
	while true do
		task.wait(AUTOSAVE_INTERVAL)
		for _, player in Players:GetPlayers() do
			task.spawn(PlayerData.Save, player)
		end
	end
end)

return PlayerData
```

Key facts:
- Max value size per key: 4 MB; keys ≤ 50 chars. Request budgets scale with player count — don't save on every coin change, mark dirty and autosave.
- Studio: File → Experience Settings → Security → "Enable Studio Access to API Services" (place must be published).
- Never store Instances; store plain tables, strings, numbers, booleans. Store item **IDs**, not item objects.
- GDPR/right-to-erasure requests arrive by message; delete with `RemoveAsync(key)`.

## 4. Leaderstats

```lua
local function createLeaderstats(player: Player, data)
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats" -- exact lowercase name, shows in player list
	local coins = Instance.new("IntValue")
	coins.Name = "Coins"
	coins.Value = data.Coins
	coins.Parent = leaderstats
	leaderstats.Parent = player
	coins.Changed:Connect(function(v) data.Coins = v end) -- keep cache in sync
end
```

## 5. Monetization

```lua
-- ServerScriptService/Monetization (Script) — exactly ONE script may set ProcessReceipt
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")

local PurchaseHistory = DataStoreService:GetDataStore("PurchaseHistory")

local VIP_PASS_ID = 0000000 -- replace
local PRODUCTS = {
	[1111111] = function(player: Player) -- 100 coins
		local coins = player.leaderstats.Coins
		coins.Value += 100
	end,
}

-- Game Pass: check on join and when bought in-game
local function applyVip(player: Player)
	player:SetAttribute("VIP", true)
end

Players.PlayerAdded:Connect(function(player)
	local ok, owns = pcall(MarketplaceService.UserOwnsGamePassAsync, MarketplaceService, player.UserId, VIP_PASS_ID)
	if ok and owns then applyVip(player) end
end)

MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, passId, purchased)
	if purchased and passId == VIP_PASS_ID then applyVip(player) end
end)

-- Developer Products: idempotent receipt handling
MarketplaceService.ProcessReceipt = function(receipt)
	local purchaseKey = `{receipt.PlayerId}_{receipt.PurchaseId}`

	local ok, alreadyGranted = pcall(PurchaseHistory.GetAsync, PurchaseHistory, purchaseKey)
	if ok and alreadyGranted then
		return Enum.ProductPurchaseDecision.PurchaseGranted
	end

	local player = Players:GetPlayerByUserId(receipt.PlayerId)
	local handler = PRODUCTS[receipt.ProductId]
	if not player or not handler then
		return Enum.ProductPurchaseDecision.NotProcessedYet -- Roblox retries later
	end

	local granted = pcall(handler, player)
	if not granted then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	-- Persist the grant (save player data here too) BEFORE confirming
	local saved = pcall(PurchaseHistory.SetAsync, PurchaseHistory, purchaseKey, true)
	if not saved then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	return Enum.ProductPurchaseDecision.PurchaseGranted
end
```

Client prompt: `MarketplaceService:PromptGamePassPurchase(player, id)` / `PromptProductPurchase(player, id)` from a LocalScript.

## 6. Tag-driven behavior

```lua
-- ServerScriptService/KillBricks (Script) — tag parts "KillBrick" via Tag Editor / Properties → Tags
local CollectionService = game:GetService("CollectionService")

local function setup(part: BasePart)
	part.Touched:Connect(function(hit)
		local humanoid = hit.Parent and hit.Parent:FindFirstChildOfClass("Humanoid")
		if humanoid then humanoid.Health = 0 end
	end)
end

CollectionService:GetInstanceAddedSignal("KillBrick"):Connect(setup)
for _, part in CollectionService:GetTagged("KillBrick") do
	setup(part)
end
```

Use attributes for per-instance config: `part:GetAttribute("Damage") or 10`.

## 7. Round / game-state loop

```lua
-- ServerScriptService/RoundManager (Script)
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local MIN_PLAYERS = 2
local INTERMISSION = 15
local ROUND_TIME = 120

local state = ReplicatedStorage:WaitForChild("GameState") -- StringValue; clients read it
local timer = ReplicatedStorage:WaitForChild("Timer")     -- IntValue

local function countdown(seconds: number)
	for t = seconds, 0, -1 do
		timer.Value = t
		task.wait(1)
	end
end

while true do
	state.Value = "Waiting"
	repeat task.wait(1) until #Players:GetPlayers() >= MIN_PLAYERS

	state.Value = "Intermission"
	countdown(INTERMISSION)

	state.Value = "InRound"
	-- load map from ServerStorage, teleport players, start round logic
	countdown(ROUND_TIME)

	state.Value = "Ended"
	-- award winners, clean up map, respawn players
	task.wait(5)
end
```

## 8. Client UI binding

```lua
-- StarterGui/HUD/HUDController (LocalScript)
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local gui = script.Parent
local coinsLabel = gui:WaitForChild("Coins") :: TextLabel
local timerLabel = gui:WaitForChild("Timer") :: TextLabel

local coins = player:WaitForChild("leaderstats"):WaitForChild("Coins") :: IntValue
local function refreshCoins() coinsLabel.Text = `💰 {coins.Value}` end
coins.Changed:Connect(refreshCoins)
refreshCoins()

local timer = ReplicatedStorage:WaitForChild("Timer") :: IntValue
timer.Changed:Connect(function(v) timerLabel.Text = `{v}s` end)
```

UI rules: use `Scale` sizing (+ `UIAspectRatioConstraint`, `UISizeConstraint`), `UIListLayout`/`UIGridLayout`, `UIPadding`, `UICorner`, `UIStroke`. Respect `GuiService:GetGuiInset()` / `ScreenGui.ScreenInsets` (`CoreUISafeInsets`) so the top bar and notches don't cover buttons. Buttons ≥ 44 px on phones.

## 9. Cooldowns, debounce, hit detection

```lua
local debounce: { [Player]: boolean } = {}
part.Touched:Connect(function(hit)
	local player = Players:GetPlayerFromCharacter(hit.Parent)
	if not player or debounce[player] then return end
	debounce[player] = true
	-- effect
	task.delay(1, function() debounce[player] = nil end)
end)
```

Combat: client plays animation/VFX instantly and fires `Attack` remote; the server checks cooldown + range + line of sight (`workspace:Raycast`) and applies damage. Never accept "I hit player X for N damage".

## 10. Global leaderboard

```lua
local ods = DataStoreService:GetOrderedDataStore("TopCoins")
-- write (throttle: on leave / every few minutes)
pcall(ods.SetAsync, ods, tostring(player.UserId), coins)
-- read top 10
local ok, pages = pcall(ods.GetSortedAsync, ods, false, 10)
if ok then
	for rank, entry in pages:GetCurrentPage() do
		local name = Players:GetNameFromUserIdAsync(tonumber(entry.key)) -- pcall in real code
		print(rank, name, entry.value)
	end
end
```

For real-time cross-server data (matchmaking queues, live events) use `MemoryStoreService` (sorted maps / queues) and `MessagingService`.

## 11. Teleporting

```lua
local TeleportService = game:GetService("TeleportService")
local options = Instance.new("TeleportOptions")
options:SetTeleportData({ mode = "Ranked" }) -- not secure; validate on arrival
local ok, err = pcall(TeleportService.TeleportAsync, TeleportService, PLACE_ID, { player }, options)
if not ok then warn(err) end -- retry on TeleportInitFailed
```

Private servers for a group: `TeleportService:ReserveServer(placeId)` → `options.ReservedServerAccessCode`.
