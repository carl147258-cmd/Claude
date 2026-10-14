--!strict
-- ReplicatedStorage/Shared/Config (ModuleScript)
-- Tuning values shared by server and client. Shop items live in Catalog.

local Config = {
	RemoteName = "FruitGame",

	Lives = 3,
	CoinsPerPoint = 1,

	-- Objects are tossed up from below the platform, fly in arcs across the screen in a
	-- "field" in front of the avatar and fall back down (Fruit Ninja style).
	-- Offsets are relative to the slot origin (centre of the platform surface, facing -Z).
	FieldForward = 15, -- distance of the field in front of the platform centre
	FieldDepth = 2.5, -- random +/- depth jitter
	GravityStart = 30, -- low gravity = floaty, easy tosses
	GravityEnd = 52, -- reached after RampSeconds: faster tosses
	SpawnBelow = 26,
	SpawnSide = 17,
	ApexSide = 13,
	ApexUp = { 4, 15 },
	SpawnIntervalStart = 1.6,
	SpawnIntervalEnd = 0.55,
	RampSeconds = 120,
	MaxPerWave = 5,
	BombChance = 0.12,
	BombsAfter = 15, -- seconds into a round before bombs appear
	MissMargin = 0.25, -- seconds after falling back to launch height before an object counts as missed

	-- Third-person camera behind the avatar (slot space)
	CameraOffset = Vector3.new(2.5, 8, 12),
	CameraLookAt = Vector3.new(0, 8, -20),

	Reach = 48, -- max distance from the camera at which an object can be cut
	ReachTolerance = 8, -- extra server tolerance for latency
	SliceRateLimit = 0.03, -- min seconds between slice requests (server)
	MaxIdsPerSlice = 8,
	ComboMin = 3, -- objects in one swipe for a combo bonus
	ShopRateLimit = 0.25, -- min seconds between shop requests (server)

	PlatformHeight = 80, -- y of the platform surface
	SlotSpacing = 45, -- distance between player platforms
	MaxSlots = 6,

	GlowColor = Color3.fromRGB(255, 35, 70),
	GlowColorAlt = Color3.fromRGB(170, 60, 255),
	CoinColor = Color3.fromRGB(255, 215, 70),
}

function Config.SlotOrigin(slot: number): CFrame
	return CFrame.new((slot - 1) * Config.SlotSpacing, Config.PlatformHeight, 0)
end

-- Centre between all platforms; shared scenery is built around it.
function Config.SceneCentre(): CFrame
	return Config.SlotOrigin((Config.MaxSlots + 1) / 2)
end

function Config.CameraCFrame(slot: number): CFrame
	local origin = Config.SlotOrigin(slot)
	return CFrame.lookAt(origin * Config.CameraOffset, origin * Config.CameraLookAt)
end

-- Ballistic flight with per-object gravity `g`: position `t` seconds after launch.
function Config.FruitPosition(p0: Vector3, v0: Vector3, g: number, t: number): Vector3
	return p0 + v0 * t - Vector3.new(0, 0.5 * g * t * t, 0)
end

function Config.FruitVelocity(v0: Vector3, g: number, t: number): Vector3
	return v0 - Vector3.new(0, g * t, 0)
end

return Config
