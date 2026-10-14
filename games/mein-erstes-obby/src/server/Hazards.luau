--!strict
-- ServerScriptService/Server/Hazards (ModuleScript)
-- Tag-driven obstacles. Add the tag in Studio (Properties -> Tags) to any part:
--   "KillBrick"    kills on touch
--   "Disappearing" fades out after being touched, comes back after a few seconds

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

local Hazards = {}

local FADE_TIME = 0.6
local RESPAWN_TIME = 3

local function getHumanoid(hit: BasePart): Humanoid?
	local model = hit.Parent
	return model and model:FindFirstChildOfClass("Humanoid")
end

local function setupKillBrick(part: Instance)
	if not part:IsA("BasePart") then
		return
	end
	part.Touched:Connect(function(hit)
		local humanoid = getHumanoid(hit)
		if humanoid then
			humanoid.Health = 0
		end
	end)
end

local function setupDisappearing(part: Instance)
	if not part:IsA("BasePart") then
		return
	end
	local originalTransparency = part.Transparency
	local busy = false
	local sound: Sound? = nil
	if Config.Sounds.Disappear ~= 0 then
		local s = Instance.new("Sound")
		s.SoundId = `rbxassetid://{Config.Sounds.Disappear}`
		s.RollOffMaxDistance = 80 -- only nearby players hear it
		s.Parent = part
		sound = s
	end
	part.Touched:Connect(function(hit)
		if busy or not getHumanoid(hit) then
			return
		end
		busy = true
		if sound then
			sound:Play()
		end
		local fade = TweenService:Create(part, TweenInfo.new(FADE_TIME), { Transparency = 1 })
		fade:Play()
		fade.Completed:Wait()
		part.CanCollide = false
		task.wait(RESPAWN_TIME)
		part.CanCollide = true
		part.Transparency = originalTransparency
		busy = false
	end)
end

local function bindTag(tag: string, setup: (Instance) -> ())
	CollectionService:GetInstanceAddedSignal(tag):Connect(setup)
	for _, instance in CollectionService:GetTagged(tag) do
		setup(instance)
	end
end

function Hazards.Start()
	bindTag("KillBrick", setupKillBrick)
	bindTag("Disappearing", setupDisappearing)
end

return Hazards
