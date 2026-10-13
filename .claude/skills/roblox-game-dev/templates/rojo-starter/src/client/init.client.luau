-- StarterPlayerScripts/Client (LocalScript): single entry point for client logic.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ContextActionService = game:GetService("ContextActionService")

local Remotes = ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Remotes")
local BuyItem = Remotes:WaitForChild("BuyItem") :: RemoteEvent

-- Press B (or tap the on-screen button on mobile) to request a Sword.
ContextActionService:BindAction("BuySword", function(_, state)
	if state == Enum.UserInputState.Begin then
		BuyItem:FireServer("Sword")
	end
	return Enum.ContextActionResult.Sink
end, true, Enum.KeyCode.B, Enum.KeyCode.ButtonY)
ContextActionService:SetTitle("BuySword", "Buy")
