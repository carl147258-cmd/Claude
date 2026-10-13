-- ServerScriptService/Server (Script): single entry point for all server logic.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Remotes = ReplicatedStorage.Shared.Remotes

local coins: { [Player]: IntValue } = {}
local lastBuy: { [Player]: number } = {}

local function onPlayerAdded(player: Player)
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	local c = Instance.new("IntValue")
	c.Name = "Coins"
	c.Value = Config.StartingCoins
	c.Parent = leaderstats
	leaderstats.Parent = player
	coins[player] = c
end

Players.PlayerAdded:Connect(onPlayerAdded)
for _, player in Players:GetPlayers() do
	task.spawn(onPlayerAdded, player)
end

Players.PlayerRemoving:Connect(function(player)
	coins[player] = nil
	lastBuy[player] = nil
end)

Remotes.BuyItem.OnServerEvent:Connect(function(player: Player, itemName: unknown)
	local now = os.clock()
	if lastBuy[player] and now - lastBuy[player] < 0.5 then
		return
	end
	lastBuy[player] = now

	if typeof(itemName) ~= "string" then
		return
	end
	local price = Config.Items[itemName]
	local c = coins[player]
	if not price or not c or c.Value < price then
		return
	end
	c.Value -= price
	print(`{player.Name} bought {itemName}`)
end)
