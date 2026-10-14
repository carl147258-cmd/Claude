--!strict
-- StarterPlayerScripts/Client/Scenery (ModuleScript)
-- Builds the equipped scene (backdrop + lighting) locally, so every player sees their own.
-- Everything is decoration: anchored, no collisions, no queries. The object field sits
-- ~15 studs in front of the platforms, so scenery stays further than ~40 studs away.

local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

type LightingSpec = {
	ClockTime: number,
	Brightness: number,
	Ambient: Color3,
	OutdoorAmbient: Color3,
	Density: number,
	Haze: number,
	Glare: number,
	AtmosphereColor: Color3,
	Decay: Color3,
	Bloom: number,
	Saturation: number,
	Contrast: number,
	Tint: Color3,
	Stars: number,
}

local Scenery = {}

local folder: Folder? = nil
local current: string? = nil
local connections: { RBXScriptConnection } = {}

local DROP_TEXTURE = "rbxasset://textures/particles/explosion01_core_main.dds"
local Y_AXIS = CFrame.Angles(0, 0, math.rad(90))

local function rgb(r: number, g: number, b: number): Color3
	return Color3.fromRGB(r, g, b)
end

local centre = Config.SceneCentre()
local function at(x: number, y: number, z: number): CFrame
	return centre * CFrame.new(x, y, z)
end

local function deco(parent: Instance, props: { [string]: any }, cf: CFrame, className: string?): BasePart
	local p = Instance.new((className or "Part") :: any) :: BasePart
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.CastShadow = false
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Material = Enum.Material.SmoothPlastic
	for key, value in props do
		(p :: any)[key] = value
	end
	p.CFrame = cf
	p.Parent = parent
	return p
end

local function block(parent: Instance, size: Vector3, color: Color3, cf: CFrame, material: Enum.Material?): BasePart
	return deco(parent, { Size = size, Color = color, Material = material or Enum.Material.SmoothPlastic }, cf)
end

local function ball(parent: Instance, d: number, color: Color3, cf: CFrame, material: Enum.Material?): BasePart
	return deco(parent, {
		Shape = Enum.PartType.Ball,
		Size = Vector3.one * d,
		Color = color,
		Material = material or Enum.Material.SmoothPlastic,
	}, cf)
end

local function ellipsoid(parent: Instance, size: Vector3, color: Color3, cf: CFrame, material: Enum.Material?): BasePart
	local p = block(parent, size, color, cf, material)
	local mesh = Instance.new("SpecialMesh")
	mesh.MeshType = Enum.MeshType.Sphere
	mesh.Parent = p
	return p
end

-- Vertical cylinder standing with its centre at cf.
local function column(
	parent: Instance,
	height: number,
	d: number,
	color: Color3,
	cf: CFrame,
	material: Enum.Material?
): BasePart
	return deco(parent, {
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(height, d, d),
		Color = color,
		Material = material or Enum.Material.SmoothPlastic,
	}, cf * Y_AXIS)
end

-- Cube balanced on a corner: the top vertex reads as a mountain peak.
local function peak(parent: Instance, size: number, color: Color3, pos: CFrame, spin: number, snow: Color3?)
	local tilt = CFrame.Angles(0, spin, 0) * CFrame.Angles(math.rad(45), 0, math.rad(35.26))
	block(parent, Vector3.one * size, color, pos * tilt, Enum.Material.Rock)
	if snow then
		local capSize = size * 0.32
		local lift = (size - capSize) * math.sqrt(3) / 2
		block(parent, Vector3.one * capSize, snow, pos * CFrame.new(0, lift + 0.5, 0) * tilt, Enum.Material.Snow)
	end
end

local function emitter(parent: Instance, cf: CFrame, size: Vector3, props: { [string]: any }): ParticleEmitter
	local holder = deco(parent, { Size = size, Transparency = 1 }, cf)
	local e = Instance.new("ParticleEmitter")
	for key, value in props do
		(e :: any)[key] = value
	end
	e.Parent = holder
	return e
end

local function ensure(className: string, name: string): Instance
	local existing = Lighting:FindFirstChild(name)
	if existing then
		return existing
	end
	local inst = Instance.new(className :: any)
	inst.Name = name
	inst.Parent = Lighting
	return inst
end

local function applyLighting(spec: LightingSpec)
	Lighting.ClockTime = spec.ClockTime
	Lighting.Brightness = spec.Brightness
	Lighting.Ambient = spec.Ambient
	Lighting.OutdoorAmbient = spec.OutdoorAmbient
	Lighting.EnvironmentDiffuseScale = 0.5
	Lighting.EnvironmentSpecularScale = 1
	local atmosphere = ensure("Atmosphere", "Atmosphere") :: Atmosphere
	atmosphere.Density = spec.Density
	atmosphere.Offset = 0.1
	atmosphere.Color = spec.AtmosphereColor
	atmosphere.Decay = spec.Decay
	atmosphere.Glare = spec.Glare
	atmosphere.Haze = spec.Haze
	local bloom = ensure("BloomEffect", "Bloom") :: BloomEffect
	bloom.Intensity = spec.Bloom
	bloom.Size = 28
	bloom.Threshold = 1.3
	local grade = ensure("ColorCorrectionEffect", "Grade") :: ColorCorrectionEffect
	grade.Contrast = spec.Contrast
	grade.Saturation = spec.Saturation
	grade.TintColor = spec.Tint
	local sky = ensure("Sky", "SceneSky") :: Sky
	sky.CelestialBodiesShown = false -- every scene builds its own sun or moon
	sky.StarCount = spec.Stars
end

---------------------------------------------------------------- scenes

local scenes: { [string]: (Folder) -> () } = {}

scenes.blutmond = function(model)
	-- closer than the atmosphere fade distance, otherwise the haze swallows it
	ball(model, 170, rgb(255, 70, 60), at(-40, 95, -560), Enum.Material.Neon)
	local rng = Random.new(7)
	for i = 0, 15 do
		peak(
			model,
			rng:NextNumber(70, 140),
			rgb(38, 24, 44),
			at(-600 + i * 80 + rng:NextNumber(-20, 20), -75 + rng:NextNumber(-10, 25), -rng:NextNumber(330, 520)),
			rng:NextNumber(0, math.pi)
		)
	end
	block(model, Vector3.new(2048, 1, 1400), rgb(120, 60, 90), at(0, -70, -500)).Transparency = 0.1
	applyLighting({
		ClockTime = 21.5, -- night: no orange sunset light on the blades
		Brightness = 2,
		Ambient = rgb(105, 70, 95),
		OutdoorAmbient = rgb(150, 105, 135),
		Density = 0.2,
		Haze = 1.2,
		Glare = 0.3,
		AtmosphereColor = rgb(200, 110, 130),
		Decay = rgb(110, 50, 90),
		Bloom = 0.8,
		Saturation = 0.15,
		Contrast = 0.12,
		Tint = rgb(255, 235, 240),
		Stars = 3000,
	})
end

local function cherryTree(model: Folder, rng: Random, base: CFrame, size: number)
	local trunk = 26 * size
	column(model, trunk, 3.5 * size, rgb(95, 60, 50), base * CFrame.new(0, trunk / 2, 0), Enum.Material.Wood)
	local pinks = { rgb(255, 183, 213), rgb(255, 160, 200), rgb(255, 210, 228), rgb(250, 140, 190) }
	for i = 1, 6 do
		local offset = Vector3.new(rng:NextNumber(-12, 12), rng:NextNumber(-3, 9), rng:NextNumber(-12, 12)) * size
		ball(
			model,
			rng:NextNumber(16, 26) * size,
			pinks[i % #pinks + 1],
			base * CFrame.new(Vector3.new(0, trunk, 0) + offset)
		)
	end
end

scenes.kirschbluete = function(model)
	local rng = Random.new(11)
	local floor = -90
	block(model, Vector3.new(3000, 2, 2200), rgb(120, 185, 95), at(0, floor - 1, -700), Enum.Material.Grass)
	block(model, Vector3.new(520, 1, 240), rgb(110, 185, 225), at(40, floor + 0.2, -230)).Reflectance = 0.3
	for _ = 1, 9 do
		ball(
			model,
			rng:NextNumber(220, 420),
			rgb(100, 160, 80),
			at(rng:NextNumber(-800, 800), floor - 110, -rng:NextNumber(550, 950)),
			Enum.Material.Grass
		)
	end
	for i = 0, 13 do
		peak(
			model,
			rng:NextNumber(160, 260),
			rgb(120, 130, 165),
			at(-900 + i * 140 + rng:NextNumber(-30, 30), floor - 20, -rng:NextNumber(800, 950)),
			rng:NextNumber(0, math.pi),
			rgb(250, 250, 255)
		)
	end
	for _ = 1, 38 do
		local x = rng:NextNumber(-700, 700)
		local z = -rng:NextNumber(140, 700)
		if math.abs(x - 40) > 280 or z < -380 or z > -120 then -- keep the pond free
			cherryTree(model, rng, at(x, floor, z), rng:NextNumber(0.8, 1.3))
		end
	end
	-- Pagoda: five shrinking tiers with wide roofs and a golden spire
	local pagoda = at(-180, floor, -480)
	local y = 0
	for i = 0, 4 do
		local width = 44 - i * 6
		block(
			model,
			Vector3.new(width, 14, width),
			rgb(200, 40, 40),
			pagoda * CFrame.new(0, y + 7, 0),
			Enum.Material.Wood
		)
		block(model, Vector3.new(width + 22, 2.5, width + 22), rgb(55, 45, 60), pagoda * CFrame.new(0, y + 15, 0))
		block(model, Vector3.new(width + 10, 2.5, width + 10), rgb(55, 45, 60), pagoda * CFrame.new(0, y + 17, 0))
		y += 18
	end
	column(model, 26, 2.5, rgb(240, 190, 60), pagoda * CFrame.new(0, y + 12, 0), Enum.Material.Metal)
	-- Torii gate in the pond
	local torii = at(40, floor, -250)
	local red = rgb(220, 40, 30)
	for _, x in { -26, 26 } do
		column(model, 70, 5, red, torii * CFrame.new(x, 35, 0), Enum.Material.Wood)
	end
	block(model, Vector3.new(80, 5, 7), rgb(40, 30, 35), torii * CFrame.new(0, 71, 0))
	block(model, Vector3.new(66, 4, 5), red, torii * CFrame.new(0, 58, 0), Enum.Material.Wood)
	block(model, Vector3.new(4, 14, 4), red, torii * CFrame.new(0, 64, 0), Enum.Material.Wood)
	-- Petals drifting past the platforms
	emitter(model, at(0, 45, -30), Vector3.new(320, 1, 120), {
		Texture = DROP_TEXTURE,
		Color = ColorSequence.new(rgb(255, 190, 215), rgb(255, 150, 195)),
		Size = NumberSequence.new(0.6),
		Lifetime = NumberRange.new(8, 12),
		Rate = 35,
		Speed = NumberRange.new(2, 5),
		EmissionDirection = Enum.NormalId.Bottom,
		Acceleration = Vector3.new(3, -2, 1),
		RotSpeed = NumberRange.new(-90, 90),
		LightInfluence = 0.5,
	})
	applyLighting({
		ClockTime = 14.5,
		Brightness = 2.6,
		Ambient = rgb(140, 120, 140),
		OutdoorAmbient = rgb(170, 150, 170),
		Density = 0.18,
		Haze = 1.2,
		Glare = 0,
		AtmosphereColor = rgb(255, 220, 235),
		Decay = rgb(200, 170, 210),
		Bloom = 0.5,
		Saturation = 0.12,
		Contrast = 0.08,
		Tint = rgb(255, 245, 250),
		Stars = 0,
	})
end

local function palm(model: Folder, rng: Random, base: CFrame)
	-- the trunk bends a little more with every segment
	local leanStep = CFrame.Angles(rng:NextNumber(-0.05, 0.05), 0, rng:NextNumber(-0.07, 0.07))
	local cf = base
	for i = 0, 5 do
		local d = 3.2 - i * 0.25
		column(
			model,
			7.5,
			d,
			if i % 2 == 0 then rgb(150, 110, 70) else rgb(130, 95, 60),
			cf * CFrame.new(0, 3.5, 0),
			Enum.Material.Wood
		)
		cf = cf * CFrame.new(0, 7, 0) * leanStep
	end
	for i = 0, 7 do
		local leaf = cf
			* CFrame.Angles(0, i * math.pi / 4 + rng:NextNumber(-0.2, 0.2), 0)
			* CFrame.Angles(math.rad(-25), 0, 0)
		block(
			model,
			Vector3.new(4.5, 0.8, 22),
			if i % 2 == 0 then rgb(60, 160, 60) else rgb(80, 180, 70),
			leaf * CFrame.new(0, 0, -10),
			Enum.Material.Grass
		)
	end
	for i = 0, 2 do
		ball(model, 2.6, rgb(110, 75, 40), cf * CFrame.Angles(0, i * 2.1, 0) * CFrame.new(1.8, -1.5, 0))
	end
end

scenes.strand = function(model)
	local rng = Random.new(5)
	local sea = -80
	block(model, Vector3.new(4000, 2, 3200), rgb(30, 145, 205), at(0, sea - 1, -1300)).Reflectance = 0.15
	ellipsoid(model, Vector3.new(950, 4, 440), rgb(70, 205, 220), at(80, sea + 0.2, -400)).Transparency = 0.15
	ellipsoid(model, Vector3.new(720, 60, 300), rgb(240, 215, 160), at(80, sea - 22, -400), Enum.Material.Sand)
	for _ = 1, 11 do
		local x = rng:NextNumber(-220, 380)
		local z = -400 + rng:NextNumber(-90, 90)
		palm(model, rng, at(x, sea + 6, z))
	end
	for _ = 1, 5 do
		local x = rng:NextNumber(-900, 900)
		local z = -rng:NextNumber(700, 1000)
		ellipsoid(
			model,
			Vector3.new(rng:NextNumber(120, 260), 50, 90),
			rgb(90, 160, 80),
			at(x, sea - 10, z),
			Enum.Material.Grass
		)
	end
	-- Sun with a soft halo
	ball(model, 150, rgb(255, 245, 190), at(260, 170, -900), Enum.Material.Neon)
	ball(model, 260, rgb(255, 235, 170), at(260, 170, -900), Enum.Material.Neon).Transparency = 0.85
	for _ = 1, 12 do
		local cloud = at(rng:NextNumber(-900, 900), rng:NextNumber(110, 230), -rng:NextNumber(450, 900))
		for _ = 1, rng:NextInteger(4, 6) do
			ball(
				model,
				rng:NextNumber(40, 85),
				rgb(255, 255, 255),
				cloud * CFrame.new(rng:NextNumber(-60, 60), rng:NextNumber(-10, 15), rng:NextNumber(-20, 20))
			)
		end
	end
	-- Sailboat
	local boat = at(-260, sea, -560)
	block(model, Vector3.new(14, 6, 40), rgb(250, 250, 250), boat * CFrame.new(0, 2, 0))
	block(model, Vector3.new(15, 1.5, 41), rgb(30, 80, 160), boat * CFrame.new(0, 4.5, 0))
	column(model, 40, 1.4, rgb(120, 90, 60), boat * CFrame.new(0, 25, 2), Enum.Material.Wood)
	deco(model, {
		Size = Vector3.new(0.5, 34, 22),
		Color = rgb(255, 250, 240),
		Material = Enum.Material.Fabric,
	}, boat * CFrame.new(0, 25, -9) * CFrame.Angles(0, math.pi, 0), "WedgePart")
	applyLighting({
		ClockTime = 13.5,
		Brightness = 3,
		Ambient = rgb(150, 140, 130),
		OutdoorAmbient = rgb(170, 160, 150),
		Density = 0.15,
		Haze = 0.8,
		Glare = 0.4,
		AtmosphereColor = rgb(200, 230, 255),
		Decay = rgb(150, 190, 230),
		Bloom = 0.5,
		Saturation = 0.2,
		Contrast = 0.08,
		Tint = rgb(255, 250, 240),
		Stars = 0,
	})
end

scenes.skyline = function(model)
	local rng = Random.new(21)
	local ground = -170
	block(model, Vector3.new(4000, 2, 3000), rgb(22, 22, 32), at(0, ground - 1, -900))
	local windowColors = { rgb(255, 215, 140), rgb(120, 220, 255), rgb(255, 90, 210), rgb(255, 240, 200) }
	for _ = 1, 170 do
		local x = rng:NextNumber(-780, 780)
		local z = -rng:NextNumber(90, 1050)
		local height = rng:NextNumber(90, 200) + -z * rng:NextNumber(0.05, 0.18)
		local width = rng:NextNumber(26, 46)
		local depth = rng:NextNumber(26, 46)
		local shade = rng:NextNumber(28, 48)
		local body = at(x, ground + height / 2, z)
		block(model, Vector3.new(width, height, depth), Color3.fromRGB(shade, shade, shade + 18), body).Reflectance =
			0.05
		-- lit windows: vertical strips on the face towards the platforms (+Z)
		local color = windowColors[rng:NextInteger(1, #windowColors)]
		local strips = rng:NextInteger(2, 4)
		for s = 1, strips do
			local sx = (s / (strips + 1) - 0.5) * width
			deco(model, {
				Size = Vector3.new(1.4, height * 0.75, 0.4),
				Color = color,
				Material = Enum.Material.Neon,
				Transparency = 0.25,
			}, body * CFrame.new(sx, height * 0.05, depth / 2 + 0.2))
		end
		if height > 230 then
			ball(model, 3, rgb(255, 40, 40), body * CFrame.new(0, height / 2 + 2, 0), Enum.Material.Neon)
		end
	end
	-- Neon billboards
	local signColors = { rgb(255, 60, 200), rgb(60, 230, 255), rgb(255, 230, 60) }
	for i = 1, 7 do
		local sign = at(rng:NextNumber(-500, 500), rng:NextNumber(-60, 40), -rng:NextNumber(160, 420))
		block(model, Vector3.new(44, 22, 1.5), rgb(15, 15, 25), sign)
		deco(model, {
			Size = Vector3.new(40, 2, 1.8),
			Color = signColors[i % #signColors + 1],
			Material = Enum.Material.Neon,
		}, sign * CFrame.new(0, 6, 0))
		deco(model, {
			Size = Vector3.new(28, 2, 1.8),
			Color = signColors[(i + 1) % #signColors + 1],
			Material = Enum.Material.Neon,
		}, sign * CFrame.new(-4, -2, 0))
	end
	ball(model, 120, rgb(225, 230, 255), at(-260, 190, -800), Enum.Material.Neon)
	applyLighting({
		ClockTime = 0.5,
		Brightness = 1.2,
		Ambient = rgb(80, 70, 120),
		OutdoorAmbient = rgb(90, 80, 140),
		Density = 0.25,
		Haze = 1.4,
		Glare = 0,
		AtmosphereColor = rgb(120, 80, 170),
		Decay = rgb(60, 30, 100),
		Bloom = 1,
		Saturation = 0.25,
		Contrast = 0.15,
		Tint = rgb(240, 230, 255),
		Stars = 1500,
	})
end

scenes.unterwasser = function(model)
	local rng = Random.new(31)
	local floor = -70
	block(model, Vector3.new(4000, 2, 3000), rgb(210, 190, 140), at(0, floor - 1, -900), Enum.Material.Sand)
	block(model, Vector3.new(4000, 1, 3000), rgb(70, 170, 220), at(0, 170, -600)).Transparency = 0.15
	for _ = 1, 10 do
		deco(
			model,
			{
				Size = Vector3.new(14, 280, 1),
				Color = rgb(190, 245, 255),
				Material = Enum.Material.Neon,
				Transparency = 0.92,
			},
			at(rng:NextNumber(-350, 350), 40, -rng:NextNumber(60, 320))
				* CFrame.Angles(0, 0, math.rad(rng:NextNumber(-15, 15)))
		)
	end
	local coral = { rgb(255, 110, 150), rgb(255, 160, 60), rgb(180, 100, 255), rgb(255, 230, 90), rgb(90, 220, 200) }
	for _ = 1, 70 do
		local x = rng:NextNumber(-500, 500)
		local z = -rng:NextNumber(50, 520)
		local base = at(x, floor, z)
		local color = coral[rng:NextInteger(1, #coral)]
		local kind = rng:NextInteger(1, 3)
		if kind == 1 then
			ball(model, rng:NextNumber(8, 18), color, base * CFrame.new(0, 2, 0), Enum.Material.Pebble)
		elseif kind == 2 then
			for _ = 1, rng:NextInteger(3, 5) do
				local h = rng:NextNumber(6, 18)
				column(
					model,
					h,
					rng:NextNumber(1.5, 3),
					color,
					base * CFrame.new(rng:NextNumber(-4, 4), h / 2, rng:NextNumber(-4, 4))
				)
			end
		else
			ellipsoid(
				model,
				Vector3.new(rng:NextNumber(12, 20), rng:NextNumber(14, 22), 1.2),
				color,
				base * CFrame.new(0, 8, 0) * CFrame.Angles(0, rng:NextNumber(-0.5, 0.5), 0)
			)
		end
	end
	for _ = 1, 45 do
		local cf = at(rng:NextNumber(-500, 500), floor, -rng:NextNumber(50, 450))
		local green = if rng:NextNumber() < 0.5 then rgb(50, 150, 70) else rgb(80, 170, 60)
		for _ = 1, rng:NextInteger(4, 7) do
			block(model, Vector3.new(2.2, 8, 0.6), green, cf * CFrame.new(0, 4, 0))
			cf = cf * CFrame.new(0, 7.5, 0) * CFrame.Angles(rng:NextNumber(-0.25, 0.25), 0, rng:NextNumber(-0.25, 0.25))
		end
	end
	for _ = 1, 14 do
		ball(
			model,
			rng:NextNumber(10, 30),
			rgb(110, 110, 120),
			at(rng:NextNumber(-600, 600), floor, -rng:NextNumber(80, 600)),
			Enum.Material.Rock
		)
	end
	-- Treasure chest
	local chest = at(-60, floor, -110)
	block(model, Vector3.new(12, 7, 8), rgb(120, 70, 30), chest * CFrame.new(0, 3.5, 0), Enum.Material.Wood)
	block(model, Vector3.new(12.4, 1, 8.4), rgb(230, 180, 40), chest * CFrame.new(0, 7, 0), Enum.Material.Metal)
	ball(model, 3, rgb(255, 220, 60), chest * CFrame.new(2, 8, 0), Enum.Material.Neon)
	-- Rising bubbles
	for _ = 1, 8 do
		emitter(model, at(rng:NextNumber(-250, 250), floor + 2, -rng:NextNumber(40, 200)), Vector3.new(6, 1, 6), {
			Texture = DROP_TEXTURE,
			Color = ColorSequence.new(rgb(220, 250, 255)),
			Transparency = NumberSequence.new(0.4),
			Size = NumberSequence.new(0.8, 1.6),
			Lifetime = NumberRange.new(8, 12),
			Rate = 4,
			Speed = NumberRange.new(8, 14),
			EmissionDirection = Enum.NormalId.Top,
			LightEmission = 0.4,
		})
	end
	-- Fish swimming in circles behind the object field
	local fishColors =
		{ rgb(255, 140, 30), rgb(255, 230, 60), rgb(70, 170, 255), rgb(255, 90, 120), rgb(140, 255, 170) }
	local fish = {}
	for i = 1, 26 do
		local size = rng:NextNumber(1.5, 3.5)
		local color = fishColors[i % #fishColors + 1]
		local school = Instance.new("Model")
		local body = ellipsoid(school, Vector3.new(1.2, 2.4, 4.2) * size, color, CFrame.new())
		deco(
			school,
			{ Size = Vector3.new(0.4, 2.4, 1.8) * size, Color = color },
			CFrame.new(0, 0, 2.6 * size),
			"WedgePart"
		)
		ball(school, 0.5 * size, rgb(20, 20, 25), CFrame.new(0.5 * size, 0.4 * size, -1.3 * size))
		school.PrimaryPart = body
		school.Parent = model
		table.insert(fish, {
			model = school,
			centre = at(rng:NextNumber(-260, 260), rng:NextNumber(-40, 50), -rng:NextNumber(60, 160)).Position,
			radius = rng:NextNumber(18, 50),
			speed = rng:NextNumber(0.15, 0.4) * (if rng:NextNumber() < 0.5 then -1 else 1),
			phase = rng:NextNumber(0, math.pi * 2),
		})
	end
	table.insert(
		connections,
		RunService.Heartbeat:Connect(function()
			local t = os.clock()
			for _, f in fish do
				local a = f.phase + t * f.speed
				local pos = f.centre + Vector3.new(math.cos(a), math.sin(a * 2) * 0.08, math.sin(a)) * f.radius
				local tangent = Vector3.new(-math.sin(a), 0, math.cos(a)) * math.sign(f.speed)
				f.model:PivotTo(CFrame.lookAlong(pos, tangent))
			end
		end)
	)
	applyLighting({
		ClockTime = 12,
		Brightness = 1.6,
		Ambient = rgb(60, 110, 150),
		OutdoorAmbient = rgb(70, 130, 170),
		Density = 0.5,
		Haze = 2,
		Glare = 0,
		AtmosphereColor = rgb(40, 140, 190),
		Decay = rgb(10, 60, 120),
		Bloom = 0.6,
		Saturation = 0.1,
		Contrast = 0.1,
		Tint = rgb(200, 240, 255),
		Stars = 0,
	})
end

local function ring(model: Folder, cf: CFrame, radius: number, width: number, color: Color3, transparency: number)
	local segments = 48
	local length = 2 * math.pi * radius / segments + 1
	for i = 0, segments - 1 do
		local a = i * math.pi * 2 / segments
		deco(model, {
			Size = Vector3.new(width, 1, length),
			Color = color,
			Transparency = transparency,
		}, cf * CFrame.Angles(0, a, 0) * CFrame.new(radius, 0, 0))
	end
end

scenes.weltraum = function(model)
	local rng = Random.new(41)
	-- Ringed planet
	local saturn = at(-360, 130, -1000)
	ball(model, 300, rgb(230, 185, 125), saturn)
	ball(model, 302, rgb(210, 160, 110), saturn * CFrame.Angles(0, 0, 0.35)).Transparency = 0.6
	local tilt = saturn * CFrame.Angles(math.rad(14), 0, math.rad(22))
	ring(model, tilt, 230, 40, rgb(225, 205, 165), 0.25)
	ring(model, tilt, 290, 50, rgb(200, 180, 150), 0.45)
	-- Earth-like planet
	local earth = at(420, 40, -820)
	ball(model, 180, rgb(40, 110, 220), earth)
	for _ = 1, 7 do
		local dir = rng:NextUnitVector()
		ball(model, rng:NextNumber(50, 80), rgb(70, 170, 80), earth * CFrame.new(dir * 70), Enum.Material.Grass)
	end
	ball(model, 60, rgb(250, 250, 255), earth * CFrame.new(0, 72, 0))
	ball(model, 196, rgb(150, 200, 255), earth).Transparency = 0.93
	ball(model, 90, rgb(200, 80, 50), at(160, 270, -700), Enum.Material.Sand)
	local moon = at(-140, -70, -420)
	ball(model, 60, rgb(180, 180, 190), moon, Enum.Material.Slate)
	for _ = 1, 6 do
		ball(
			model,
			rng:NextNumber(8, 14),
			rgb(140, 140, 150),
			moon * CFrame.new(rng:NextUnitVector() * 27),
			Enum.Material.Slate
		)
	end
	ball(model, 120, rgb(255, 235, 190), at(820, 320, -1600), Enum.Material.Neon)
	ball(model, 240, rgb(255, 210, 150), at(820, 320, -1600), Enum.Material.Neon).Transparency = 0.85
	-- Distant stars (translucent "nebula" balls read as dark discs, so there are none)
	for _ = 1, 160 do
		local dir = Vector3.new(rng:NextNumber(-1, 1), rng:NextNumber(-0.4, 1), -rng:NextNumber(0.3, 1)).Unit
		ball(
			model,
			rng:NextNumber(1.5, 4),
			rgb(255, 255, 255),
			centre * CFrame.new(dir * rng:NextNumber(700, 1200)),
			Enum.Material.Neon
		)
	end
	-- Satellite
	local sat = at(-210, 70, -300) * CFrame.Angles(0.3, 0.6, 0.2)
	column(model, 16, 6, rgb(210, 210, 220), sat, Enum.Material.Metal)
	for _, x in { -14, 14 } do
		block(model, Vector3.new(18, 0.6, 8), rgb(40, 70, 160), sat * CFrame.new(x, 0, 0), Enum.Material.Glass)
	end
	-- Slowly tumbling asteroids (kept behind the object field)
	local rocks = {}
	for _ = 1, 55 do
		local size = rng:NextNumber(4, 18)
		local pos = at(rng:NextNumber(-500, 500), rng:NextNumber(-160, 160), -rng:NextNumber(60, 480))
		local shade = rng:NextNumber(80, 130)
		local rock = block(
			model,
			Vector3.new(size, size * rng:NextNumber(0.6, 1), size * rng:NextNumber(0.6, 1)),
			Color3.fromRGB(shade, shade * 0.9, shade * 0.8),
			pos,
			Enum.Material.Rock
		)
		table.insert(rocks, { part = rock, pos = pos, axis = rng:NextUnitVector(), speed = rng:NextNumber(0.1, 0.5) })
	end
	table.insert(
		connections,
		RunService.Heartbeat:Connect(function()
			local t = os.clock()
			for _, r in rocks do
				r.part.CFrame = r.pos * CFrame.fromAxisAngle(r.axis, t * r.speed)
			end
		end)
	)
	applyLighting({
		ClockTime = 0,
		Brightness = 2,
		Ambient = rgb(160, 150, 185), -- no sun in space: ambient light keeps the planets readable
		OutdoorAmbient = rgb(150, 145, 175),
		Density = 0,
		Haze = 0,
		Glare = 0,
		AtmosphereColor = rgb(0, 0, 0),
		Decay = rgb(0, 0, 0),
		Bloom = 1,
		Saturation = 0.2,
		Contrast = 0.1,
		Tint = rgb(240, 240, 255),
		Stars = 5000,
	})
end

---------------------------------------------------------------- public

function Scenery.Apply(sceneId: string)
	if sceneId == current then
		return
	end
	local build = scenes[sceneId] or scenes.blutmond
	for _, connection in connections do
		connection:Disconnect()
	end
	table.clear(connections)
	if folder then
		folder:Destroy()
	end
	local newFolder = Instance.new("Folder")
	newFolder.Name = "Scenery"
	build(newFolder)
	newFolder.Parent = workspace
	folder = newFolder
	current = sceneId
end

return Scenery
