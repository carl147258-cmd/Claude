--!strict
-- StarterPlayerScripts/Client/Sfx (ModuleScript)
-- Sound effects with random pitch so repeated slices never sound identical.
-- Creator Store sounds: ProSoundEffects / RBLXEssentials (licensed for Roblox);
-- bomb and miss use sounds that ship with the Roblox client.

local ContentProvider = game:GetService("ContentProvider")
local SoundService = game:GetService("SoundService")

type Def = { ids: { string }, volume: number, pitch: { number } }

local DEFS: { [string]: Def } = {
	Swish = {
		ids = { "rbxassetid://9126015464", "rbxassetid://9126015484" },
		volume = 0.45,
		pitch = { 1.05, 1.35 },
	},
	Slash = { ids = { "rbxassetid://9114483458" }, volume = 0.6, pitch = { 1.0, 1.25 } },
	Splat = { ids = { "rbxassetid://9120572959" }, volume = 0.7, pitch = { 0.9, 1.2 } },
	Combo = { ids = { "rbxassetid://97069579625373" }, volume = 0.6, pitch = { 1, 1 } },
	Bomb = { ids = { "rbxasset://sounds/impact_explosion_03.mp3" }, volume = 0.8, pitch = { 0.9, 1 } },
	Miss = { ids = { "rbxasset://sounds/impact_water.mp3" }, volume = 0.35, pitch = { 1.2, 1.4 } },
}

local Sfx = {}

local templates: { [string]: { Sound } } = {}
local rng = Random.new()

function Sfx.Init()
	local preload = {}
	for name, def in DEFS do
		templates[name] = {}
		for _, id in def.ids do
			local sound = Instance.new("Sound")
			sound.SoundId = id
			sound.Volume = def.volume
			sound.Parent = SoundService
			table.insert(templates[name], sound)
			table.insert(preload, sound)
		end
	end
	task.spawn(function()
		pcall(function()
			ContentProvider:PreloadAsync(preload)
		end)
	end)
end

-- pitchBoost multiplies the random pitch (used to raise the combo sound per extra fruit).
function Sfx.Play(name: string, pitchBoost: number?)
	local list = templates[name]
	local def = DEFS[name]
	if not list or not def then
		return
	end
	local sound = list[rng:NextInteger(1, #list)]:Clone()
	sound.PlaybackSpeed = rng:NextNumber(def.pitch[1], def.pitch[2]) * (pitchBoost or 1)
	sound.Parent = SoundService
	sound:Play()
	sound.Ended:Once(function()
		sound:Destroy()
	end)
	task.delay(4, function()
		if sound.Parent then
			sound:Destroy()
		end
	end)
end

return Sfx
