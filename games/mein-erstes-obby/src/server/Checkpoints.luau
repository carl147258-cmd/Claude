--!strict
-- ServerScriptService/Server/Checkpoints (ModuleScript)
-- Advances stages when players touch the next checkpoint and respawns them there.

local Players = game:GetService("Players")

local PlayerData = require(script.Parent.PlayerData)

local Checkpoints = {}

local checkpointFolder: Folder

local function getCheckpoint(stage: number): BasePart?
	return checkpointFolder:FindFirstChild(tostring(stage)) :: BasePart?
end

function Checkpoints.TeleportToStage(player: Player)
	local data = PlayerData.Get(player)
	local character = player.Character
	local checkpoint = data and getCheckpoint(data.Stage)
	if character and checkpoint then
		character:PivotTo(checkpoint.CFrame + Vector3.new(0, 4, 0))
	end
end

function Checkpoints.MaxStage(): number
	return #checkpointFolder:GetChildren()
end

local function onCheckpointTouched(checkpoint: BasePart, hit: BasePart)
	local character = hit.Parent
	local player = character and Players:GetPlayerFromCharacter(character)
	if not player then
		return
	end
	local humanoid = (character :: Model):FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then
		return
	end
	local data = PlayerData.Get(player)
	local stage = checkpoint:GetAttribute("Stage") or tonumber(checkpoint.Name)
	-- Only the NEXT stage counts: touching stage 9 from stage 3 (e.g. by teleport cheats) does nothing.
	if data and typeof(stage) == "number" and stage == data.Stage + 1 then
		PlayerData.SetStage(player, stage)
	end
end

local function onCharacterAdded(player: Player, character: Model)
	character:WaitForChild("HumanoidRootPart")
	task.wait() -- let the default spawn finish before moving the character
	Checkpoints.TeleportToStage(player)
end

function Checkpoints.Start(course: Folder)
	checkpointFolder = course:WaitForChild("Checkpoints") :: Folder

	for _, checkpoint in checkpointFolder:GetChildren() do
		if checkpoint:IsA("BasePart") then
			checkpoint.Touched:Connect(function(hit)
				onCheckpointTouched(checkpoint, hit)
			end)
		end
	end

	-- Respawn players at their checkpoint once their data is loaded.
	PlayerData.Loaded:Connect(function(player: Player)
		player.CharacterAdded:Connect(function(character)
			onCharacterAdded(player, character)
		end)
		if player.Character then
			task.spawn(onCharacterAdded, player, player.Character)
		end
	end)
end

return Checkpoints
