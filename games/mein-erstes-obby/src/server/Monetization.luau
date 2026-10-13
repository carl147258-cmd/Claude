--!strict
-- ServerScriptService/Server/Monetization (ModuleScript)
-- Handles the "Skip stage" Developer Product. Only ONE script in the game may set ProcessReceipt.

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local PlayerData = require(script.Parent.PlayerData)

local MAX_STORED_RECEIPTS = 50

local Monetization = {}

function Monetization.Start(checkpoints: any)
	if Config.SkipStageProductId == 0 then
		return -- product not configured yet
	end

	MarketplaceService.ProcessReceipt = function(receipt)
		local player = Players:GetPlayerByUserId(receipt.PlayerId)
		local data = player and PlayerData.Get(player)
		if not player or not data then
			return Enum.ProductPurchaseDecision.NotProcessedYet -- Roblox retries later
		end

		-- Already granted earlier (e.g. Roblox retried the callback)?
		if table.find(data.Receipts, receipt.PurchaseId) then
			return Enum.ProductPurchaseDecision.PurchaseGranted
		end

		if receipt.ProductId ~= Config.SkipStageProductId then
			return Enum.ProductPurchaseDecision.NotProcessedYet
		end

		local previousStage = data.Stage
		PlayerData.SetStage(player, math.min(data.Stage + 1, checkpoints.MaxStage()))
		table.insert(data.Receipts, receipt.PurchaseId)
		if #data.Receipts > MAX_STORED_RECEIPTS then
			table.remove(data.Receipts, 1)
		end

		-- Confirm only after the grant is saved; otherwise undo and let Roblox retry.
		if not PlayerData.Save(player) then
			PlayerData.SetStage(player, previousStage)
			table.remove(data.Receipts, table.find(data.Receipts, receipt.PurchaseId))
			return Enum.ProductPurchaseDecision.NotProcessedYet
		end

		checkpoints.TeleportToStage(player)
		return Enum.ProductPurchaseDecision.PurchaseGranted
	end
end

return Monetization
