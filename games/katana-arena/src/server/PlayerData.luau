--!strict
-- ServerScriptService/Server/PlayerData (ModuleScript)
-- Loads and saves each player's profile: best score, coins, owned and equipped shop items.
-- Shows score, best and coins in leaderstats. Never saves if loading failed.

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Catalog = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Catalog"))

local STORE_NAME = "KatanaFruits_v1"
local DATA_VERSION = 2
local MAX_RETRIES = if RunService:IsStudio() then 1 else 5
local AUTOSAVE_SECONDS = 120

-- GetDataStore itself throws in unpublished places, so it must not run unprotected.
local storeOk, storeResult = pcall(function()
	return DataStoreService:GetDataStore(STORE_NAME)
end)
local store: DataStore? = if storeOk then storeResult else nil
if not storeOk then
	warn(`DataStore unavailable, progress will not be saved: {storeResult}`)
end

export type Profile = {
	Best: number,
	Coins: number,
	Owned: { [string]: { [string]: boolean } },
	Equipped: { [string]: string },
}

local profiles: { [Player]: Profile } = {}
local canSave: { [Player]: boolean } = {}
local dirty: { [Player]: boolean } = {}
local listeners: { (Player) -> () } = {}

local PlayerData = {}

local function key(player: Player): string
	return `Player_{player.UserId}`
end

local function withRetries(fn: () -> any): (boolean, any)
	local lastError
	for attempt = 1, MAX_RETRIES do
		local ok, result = pcall(fn)
		if ok then
			return true, result
		end
		lastError = result
		if attempt < MAX_RETRIES then
			task.wait(math.min(2 ^ attempt, 10))
		end
	end
	return false, lastError
end

local function setLeaderstat(player: Player, name: string, value: number)
	local leaderstats = player:FindFirstChild("leaderstats")
	local stat = leaderstats and leaderstats:FindFirstChild(name)
	if stat then
		(stat :: IntValue).Value = value
	end
end

-- Builds a valid profile from whatever was stored (nil, version 1 or version 2).
local function reconcile(stored: any): Profile
	local data = if typeof(stored) == "table" then stored else {}
	local profile: Profile = {
		Best = if typeof(data.Best) == "number" then math.max(0, math.floor(data.Best)) else 0,
		Coins = if typeof(data.Coins) == "number" then math.max(0, math.floor(data.Coins)) else 0,
		Owned = {},
		Equipped = {},
	}
	for _, category in Catalog.Categories do
		local owned = {}
		local storedOwned = if typeof(data.Owned) == "table" then data.Owned[category] else nil
		if typeof(storedOwned) == "table" then
			for _, id in storedOwned do
				if Catalog.Find(category, id) then
					owned[id] = true
				end
			end
		end
		local default = (Catalog.Defaults :: any)[category]
		owned[default] = true
		profile.Owned[category] = owned
		local equipped = if typeof(data.Equipped) == "table" then data.Equipped[category] else nil
		profile.Equipped[category] = if typeof(equipped) == "string" and owned[equipped] then equipped else default
	end
	return profile
end

local function serialise(profile: Profile): { [string]: any }
	local owned = {}
	for category, ids in profile.Owned do
		local list = {}
		for id in ids do
			table.insert(list, id)
		end
		owned[category] = list
	end
	return {
		Version = DATA_VERSION,
		Best = profile.Best,
		Coins = profile.Coins,
		Owned = owned,
		Equipped = table.clone(profile.Equipped),
	}
end

local function changed(player: Player)
	dirty[player] = true
	local profile = profiles[player]
	if profile then
		setLeaderstat(player, "Münzen", profile.Coins)
		setLeaderstat(player, "Rekord", profile.Best)
	end
	for _, listener in listeners do
		task.spawn(listener, player)
	end
end

local function onPlayerAdded(player: Player)
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	for _, name in { "Punkte", "Rekord", "Münzen" } do
		local stat = Instance.new("IntValue")
		stat.Name = name
		stat.Parent = leaderstats
	end
	leaderstats.Parent = player

	local ok, stored = withRetries(function()
		return assert(store, "DataStore unavailable"):GetAsync(key(player))
	end)
	if not player.Parent then
		return
	end
	profiles[player] = reconcile(if ok then stored else nil)
	canSave[player] = ok -- never overwrite real data if loading failed
	changed(player)
	dirty[player] = nil
end

-- Waits until the player's profile is loaded (or the player left). Returns nil on timeout.
function PlayerData.WaitForProfile(player: Player): Profile?
	local deadline = os.clock() + 30
	while not profiles[player] and player.Parent and os.clock() < deadline do
		task.wait(0.1)
	end
	return profiles[player]
end

function PlayerData.GetProfile(player: Player): Profile?
	return profiles[player]
end

function PlayerData.OnChanged(listener: (Player) -> ())
	table.insert(listeners, listener)
end

function PlayerData.GetBest(player: Player): number
	local profile = profiles[player]
	return if profile then profile.Best else 0
end

function PlayerData.SetScore(player: Player, score: number)
	setLeaderstat(player, "Punkte", score)
	local profile = profiles[player]
	if profile and score > profile.Best then
		profile.Best = score
		dirty[player] = true
		setLeaderstat(player, "Rekord", score)
	end
end

function PlayerData.AddCoins(player: Player, amount: number)
	local profile = profiles[player]
	if profile and amount > 0 then
		profile.Coins += math.floor(amount)
		changed(player)
	end
end

function PlayerData.GetEquipped(player: Player, category: string): string
	local profile = profiles[player]
	return if profile then profile.Equipped[category] else (Catalog.Defaults :: any)[category]
end

-- Returns ok plus a short reason for the client message.
function PlayerData.Buy(player: Player, category: string, id: string): (boolean, string)
	local profile = profiles[player]
	local item = Catalog.Find(category, id)
	if not profile or not item then
		return false, "Unbekannter Gegenstand"
	end
	if profile.Owned[category][id] then
		return false, "Gehört dir schon"
	end
	if profile.Coins < item.Price then
		return false, "Nicht genug Münzen"
	end
	profile.Coins -= item.Price
	profile.Owned[category][id] = true
	profile.Equipped[category] = id
	changed(player)
	return true, `{item.Name} gekauft!`
end

function PlayerData.Equip(player: Player, category: string, id: string): boolean
	local profile = profiles[player]
	if not profile or not Catalog.Find(category, id) or not profile.Owned[category][id] then
		return false
	end
	if profile.Equipped[category] ~= id then
		profile.Equipped[category] = id
		changed(player)
	end
	return true
end

function PlayerData.Save(player: Player)
	local profile = profiles[player]
	if not profile or not canSave[player] or not dirty[player] then
		return
	end
	local snapshot = serialise(profile)
	local ok = withRetries(function()
		return assert(store, "DataStore unavailable"):UpdateAsync(key(player), function(old)
			-- the best score never goes down, even if another server saved a higher one
			local oldBest = if typeof(old) == "table" and typeof(old.Best) == "number" then old.Best else 0
			snapshot.Best = math.max(oldBest, snapshot.Best)
			return snapshot
		end)
	end)
	if ok then
		dirty[player] = nil
	end
end

function PlayerData.Start()
	Players.PlayerAdded:Connect(onPlayerAdded)
	for _, player in Players:GetPlayers() do
		task.spawn(onPlayerAdded, player)
	end
	Players.PlayerRemoving:Connect(function(player)
		PlayerData.Save(player)
		profiles[player] = nil
		canSave[player] = nil
		dirty[player] = nil
	end)
	task.spawn(function()
		while true do
			task.wait(AUTOSAVE_SECONDS)
			for _, player in Players:GetPlayers() do
				task.spawn(PlayerData.Save, player)
			end
		end
	end)
	game:BindToClose(function()
		local pending = 0
		for _, player in Players:GetPlayers() do
			pending += 1
			task.spawn(function()
				PlayerData.Save(player)
				pending -= 1
			end)
		end
		local deadline = os.clock() + 25
		while pending > 0 and os.clock() < deadline do
			task.wait(0.25)
		end
	end)
end

return PlayerData
