-- ServerScriptService/Server (Script)
-- Entry point: all server modules are children of this script.

local Arena = require(script.Arena)
local PlayerData = require(script.PlayerData)
local FruitGame = require(script.FruitGame)
local Shop = require(script.Shop)

Arena.Build()
PlayerData.Start()
local remote = FruitGame.Start()
Shop.Start(remote)
