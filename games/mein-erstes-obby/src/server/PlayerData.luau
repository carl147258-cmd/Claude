--!strict
-- ServerScriptService/Server/PlayerData (ModuleScript)
-- Loads, caches and saves each player's progress in a DataStore.

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

export type Data = {
	Version: number,
	Stage: number,
	Receipts: { string }, -- recent Developer Product purchase IDs (prevents double grants)
}

local DEFAULT_DATA: Data = {
	Version = 1,
	Stage = 1,
	Receipts = {},
}

-- In Studio, fail fast so unpublished places stay playable without saving.
local MAX_RETRIES = if RunService:IsStudio() then 1 else 5

local store = DataStoreService:GetDataStore(Config.DataStoreName)
local cache: { [Player]: Data } = {}
local canSave: { [Player]: boolean } = {}

local PlayerData = {}

local loadedEvent = Instance.new("BindableEvent")
PlayerData.Loaded = loadedEvent.Event -- fires (player, data)

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
		warn(`DataStore attempt {attempt} failed: {result}`)
		if attempt < MAX_RETRIES then
			task.wait(math.min(2 ^ attempt, 10))
		end
	end
	return false, lastError
end

local function fromStored(stored: any): Data
	local data: Data = table.clone(DEFAULT_DATA)
	data.Receipts = {}
	if typeof(stored) == "table" then
		if typeof(stored.Stage) == "number" then
			data.Stage = math.clamp(math.floor(stored.Stage), 1, Config.StageCount)
		end
		if typeof(stored.Receipts) == "table" then
			data.Receipts = stored.Receipts
		end
	end
	return data
end

local function onPlayerAdded(player: Player)
	local ok, stored = withRetries(function()
		return store:GetAsync(key(player))
	end)

	if not ok then
		if RunService:IsStudio() then
			warn(
				"DataStore unavailable in Studio: progress will NOT be saved. "
					.. "Publish the place and enable 'Studio Access to API Services' to test saving."
			)
		else
			player:Kick("Dein Spielstand konnte nicht geladen werden. Bitte tritt erneut bei.")
			return
		end
	end
	if not player.Parent then
		return -- left while loading
	end

	local data = fromStored(stored)
	cache[player] = data
	canSave[player] = ok -- never overwrite real data if loading failed

	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	local stageValue = Instance.new("IntValue")
	stageValue.Name = "Stufe"
	stageValue.Value = data.Stage
	stageValue.Parent = leaderstats
	leaderstats.Parent = player

	loadedEvent:Fire(player, data)
end

function PlayerData.Get(player: Player): Data?
	return cache[player]
end

function PlayerData.SetStage(player: Player, stage: number)
	local data = cache[player]
	if not data then
		return
	end
	data.Stage = stage
	local leaderstats = player:FindFirstChild("leaderstats")
	local stageValue = leaderstats and leaderstats:FindFirstChild("Stufe")
	if stageValue then
		(stageValue :: IntValue).Value = stage
	end
end

-- Returns true only if the data was actually written.
function PlayerData.Save(player: Player): boolean
	local data = cache[player]
	if not data or not canSave[player] then
		return false
	end
	local ok = withRetries(function()
		return store:UpdateAsync(key(player), function()
			return data
		end)
	end)
	return ok
end

function PlayerData.Start()
	Players.PlayerAdded:Connect(onPlayerAdded)
	for _, player in Players:GetPlayers() do
		task.spawn(onPlayerAdded, player)
	end

	Players.PlayerRemoving:Connect(function(player)
		PlayerData.Save(player)
		cache[player] = nil
		canSave[player] = nil
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
		local deadline = os.clock() + 25 -- Roblox allows ~30 s
		while pending > 0 and os.clock() < deadline do
			task.wait(0.25)
		end
	end)

	task.spawn(function()
		while true do
			task.wait(Config.AutosaveInterval)
			for _, player in Players:GetPlayers() do
				task.spawn(PlayerData.Save, player)
			end
		end
	end)
end

return PlayerData
