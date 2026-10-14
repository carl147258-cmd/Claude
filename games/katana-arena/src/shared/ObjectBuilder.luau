--!strict
-- ReplicatedStorage/Shared/ObjectBuilder (ModuleScript)
-- Builds the sliceable objects (fruits, vegetables, sweets, toys, plush animals, bomb)
-- from primitive parts. Every model is centred on its PrimaryPart "Body" at the origin,
-- front facing -Z, and fits roughly inside a sphere of the kind's Radius.

local Catalog = require(script.Parent.Catalog)

type Builder = (model: Model, r: number, kind: Catalog.ObjectKind) -> ()

local ObjectBuilder = {}

local BLACK = Color3.fromRGB(20, 18, 22)
local WHITE = Color3.fromRGB(250, 250, 250)
local Y_AXIS = CFrame.Angles(0, 0, math.rad(90)) -- cylinder axis X -> Y
local Z_AXIS = CFrame.Angles(0, math.rad(90), 0) -- cylinder axis X -> Z

local function newPart(props: { [string]: any }, className: string?): BasePart
	local p = Instance.new((className or "Part") :: any) :: BasePart
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.CastShadow = false
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	for key, value in props do
		(p :: any)[key] = value
	end
	return p
end

local function add(model: Model, props: { [string]: any }, cf: CFrame, className: string?): BasePart
	local p = newPart(props, className)
	p.CFrame = cf
	p.Parent = model
	return p
end

local function ball(model: Model, d: number, color: Color3, cf: CFrame, material: Enum.Material?): BasePart
	return add(model, {
		Shape = Enum.PartType.Ball,
		Size = Vector3.one * d,
		Color = color,
		Material = material or Enum.Material.SmoothPlastic,
	}, cf)
end

local function ellipsoid(model: Model, size: Vector3, color: Color3, cf: CFrame, material: Enum.Material?): BasePart
	local p = add(model, { Size = size, Color = color, Material = material or Enum.Material.SmoothPlastic }, cf)
	local mesh = Instance.new("SpecialMesh")
	mesh.MeshType = Enum.MeshType.Sphere
	mesh.Parent = p
	return p
end

local function box(model: Model, size: Vector3, color: Color3, cf: CFrame, material: Enum.Material?): BasePart
	return add(model, { Size = size, Color = color, Material = material or Enum.Material.SmoothPlastic }, cf)
end

-- Cylinder along its local X axis (rotate with Y_AXIS / Z_AXIS).
local function cyl(
	model: Model,
	length: number,
	d: number,
	color: Color3,
	cf: CFrame,
	material: Enum.Material?
): BasePart
	return add(model, {
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(length, d, d),
		Color = color,
		Material = material or Enum.Material.SmoothPlastic,
	}, cf)
end

local function at(x: number, y: number, z: number): CFrame
	return CFrame.new(x, y, z)
end

local function eyes(model: Model, r: number, y: number, spread: number, depth: number)
	for _, side in { -1, 1 } do
		ball(model, 0.18 * r, BLACK, at(side * spread * r, y * r, -depth * r))
		-- tiny highlight makes plush eyes read as shiny buttons
		ball(model, 0.06 * r, WHITE, at(side * spread * r + 0.03 * r, y * r + 0.04 * r, -(depth + 0.08) * r))
	end
end

local function stemAndLeaf(model: Model, r: number)
	box(model, Vector3.new(0.08, 0.35, 0.08) * r / 0.9, Color3.fromRGB(90, 55, 25), at(0, r + 0.1 * r, 0))
	box(
		model,
		Vector3.new(0.05, 0.22, 0.4) * r / 0.9,
		Color3.fromRGB(60, 170, 50),
		at(0.12 * r, r + 0.15 * r, 0.1 * r) * CFrame.Angles(0.5, 0, 0.6)
	)
end

local builders: { [string]: Builder } = {}

---------------------------------------------------------------- fruits

builders.Melon = function(model, r)
	-- dark stripes: thin discs through the poles show as meridian bands
	for i = 0, 3 do
		cyl(model, 0.22 * r / 1.45, r * 2.02, Color3.fromRGB(25, 85, 30), CFrame.Angles(0, i * math.pi / 4, 0))
	end
end

builders.Orange = function(model, r)
	stemAndLeaf(model, r)
end
builders.Apple = builders.Orange
builders.Lemon = builders.Orange

builders.Kiwi = function() end

builders.Dragonfruit = function(model, r)
	for i = 0, 7 do
		add(
			model,
			{ Size = Vector3.new(0.08, 0.5, 0.35) * r, Color = Color3.fromRGB(110, 200, 70) },
			CFrame.Angles(0, i * math.pi / 4, 0)
				* CFrame.Angles(0, 0, math.rad(if i % 2 == 0 then 35 else -40))
				* CFrame.new(0, r, 0),
			"WedgePart"
		)
	end
end

builders.Bomb = function(model, r)
	cyl(model, 0.4 * r, 0.25 * r, Color3.fromRGB(60, 60, 60), at(0, r + 0.1 * r, 0) * Y_AXIS)
	local spark = ball(model, 0.35 * r, Color3.fromRGB(255, 200, 80), at(0, r + 0.4 * r, 0), Enum.Material.Neon)
	spark.Name = "Spark"
	local fire = Instance.new("ParticleEmitter")
	fire.Color = ColorSequence.new(Color3.fromRGB(255, 230, 120), Color3.fromRGB(255, 60, 0))
	fire.LightEmission = 1
	fire.Size = NumberSequence.new(0.25 * r, 0)
	fire.Lifetime = NumberRange.new(0.2, 0.4)
	fire.Rate = 40
	fire.Speed = NumberRange.new(2, 4)
	fire.SpreadAngle = Vector2.new(60, 60)
	fire.Parent = spark
	local glow = Instance.new("PointLight")
	glow.Color = Color3.fromRGB(255, 60, 40)
	glow.Range = 8 * r
	glow.Brightness = 3
	glow.Parent = spark
	local warning = Instance.new("Highlight")
	warning.FillColor = Color3.fromRGB(255, 0, 40)
	warning.FillTransparency = 0.75
	warning.OutlineColor = Color3.fromRGB(255, 40, 40)
	warning.Parent = model
end

---------------------------------------------------------------- vegetables

builders.Tomato = function(model, r, kind)
	ellipsoid(model, Vector3.new(2, 1.8, 2) * r, kind.Skin, CFrame.new())
	local green = Color3.fromRGB(50, 140, 45)
	for i = 0, 4 do
		box(
			model,
			Vector3.new(0.22, 0.06, 0.7) * r,
			green,
			CFrame.Angles(0, i * math.pi * 2 / 5, 0) * at(0, 0.86 * r, -0.28 * r) * CFrame.Angles(math.rad(-15), 0, 0)
		)
	end
	cyl(model, 0.3 * r, 0.12 * r, green, at(0, 1.0 * r, 0) * Y_AXIS)
end

builders.Pumpkin = function(model, r, kind)
	ellipsoid(model, Vector3.new(2, 1.6, 2) * r, kind.Skin, CFrame.new())
	local rib = kind.Skin:Lerp(Color3.fromRGB(180, 70, 10), 0.35)
	for i = 0, 3 do
		ellipsoid(model, Vector3.new(0.85, 1.62, 2.06) * r, rib, CFrame.Angles(0, i * math.pi / 4, 0))
	end
	cyl(model, 0.45 * r, 0.22 * r, Color3.fromRGB(90, 110, 40), at(0, 0.88 * r, 0) * Y_AXIS * CFrame.Angles(0.2, 0, 0))
end

builders.Eggplant = function(model, r, kind)
	local tilt = CFrame.Angles(0, 0, math.rad(25))
	ellipsoid(model, Vector3.new(1.3, 2, 1.3) * r, kind.Skin, tilt, Enum.Material.SmoothPlastic).Reflectance = 0.1
	local green = Color3.fromRGB(70, 130, 50)
	ellipsoid(model, Vector3.new(0.85, 0.35, 0.85) * r, green, tilt * at(0, 0.85 * r, 0))
	cyl(model, 0.4 * r, 0.15 * r, green, tilt * at(0, 1.1 * r, 0) * Y_AXIS)
end

builders.Carrot = function(model, r, kind)
	for i = 0, 4 do
		local d = r * (1.05 - i * 0.19)
		cyl(model, 0.44 * r, d, kind.Skin, at(0, 0.75 * r - i * 0.42 * r, 0) * Y_AXIS)
	end
	ball(model, 0.25 * r, kind.Skin, at(0, -1.1 * r, 0))
	local green = Color3.fromRGB(70, 170, 60)
	for _, angle in { -25, 0, 25 } do
		box(
			model,
			Vector3.new(0.12, 0.85, 0.3) * r,
			green,
			at(0, 1.0 * r, 0) * CFrame.Angles(0, 0, math.rad(angle)) * at(0, 0.35 * r, 0)
		)
	end
end

builders.Broccoli = function(model, r, kind)
	cyl(model, 1.0 * r, 0.55 * r, kind.Flesh, at(0, -0.5 * r, 0) * Y_AXIS)
	ball(model, 1.0 * r, kind.Skin, at(0, 0.35 * r, 0), Enum.Material.Sand)
	for i = 0, 5 do
		local a = i * math.pi / 3
		ball(
			model,
			0.75 * r,
			kind.Skin,
			at(math.cos(a) * 0.55 * r, 0.15 * r, math.sin(a) * 0.55 * r),
			Enum.Material.Sand
		)
	end
end

---------------------------------------------------------------- sweets

builders.Donut = function(model, r, kind)
	local icing = Color3.fromRGB(255, 120, 180)
	for i = 0, 11 do
		local a = i * math.pi / 6
		local x, z = math.cos(a) * 0.62 * r, math.sin(a) * 0.62 * r
		ball(model, 0.8 * r, kind.Skin, at(x, 0, z))
		ball(model, 0.72 * r, icing, at(x, 0.14 * r, z))
	end
	local rng = Random.new(3)
	local colours = {
		Color3.fromRGB(255, 255, 255),
		Color3.fromRGB(80, 200, 255),
		Color3.fromRGB(255, 230, 60),
		Color3.fromRGB(120, 230, 110),
	}
	for i = 1, 14 do
		local a = rng:NextNumber(0, math.pi * 2)
		local d = rng:NextNumber(0.42, 0.85) * r
		box(
			model,
			Vector3.new(0.06, 0.06, 0.22) * r,
			colours[i % #colours + 1],
			at(math.cos(a) * d, 0.5 * r, math.sin(a) * d) * CFrame.Angles(0, rng:NextNumber(0, math.pi), 0)
		)
	end
end

builders.Cupcake = function(model, r, kind)
	cyl(model, 0.9 * r, 1.35 * r, Color3.fromRGB(110, 190, 240), at(0, -0.5 * r, 0) * Y_AXIS)
	for i = 0, 7 do
		box(
			model,
			Vector3.new(0.08, 0.9, 0.08) * r,
			Color3.fromRGB(80, 160, 220),
			CFrame.Angles(0, i * math.pi / 4, 0) * at(0, -0.5 * r, -0.66 * r)
		)
	end
	ball(model, 1.55 * r, kind.Skin, at(0, 0.05 * r, 0))
	ball(model, 1.1 * r, kind.Skin:Lerp(WHITE, 0.25), at(0, 0.5 * r, 0))
	ball(model, 0.6 * r, kind.Skin:Lerp(WHITE, 0.5), at(0, 0.85 * r, 0))
	ball(model, 0.38 * r, Color3.fromRGB(220, 20, 40), at(0, 1.12 * r, 0)).Reflectance = 0.15
end

builders.Candy = function(model, r, kind)
	ellipsoid(model, Vector3.new(1.5, 1.0, 1.0) * r, kind.Skin, CFrame.new()).Reflectance = 0.15
	for _, x in { -0.3, 0.3 } do
		ellipsoid(model, Vector3.new(0.18, 1.02, 1.02) * r, WHITE, at(x * r, 0, 0))
	end
	for _, side in { -1, 1 } do
		cyl(model, 0.25 * r, 0.3 * r, kind.Skin, at(side * 0.8 * r, 0, 0))
		ellipsoid(model, Vector3.new(0.5, 1.0, 0.2) * r, kind.Skin:Lerp(WHITE, 0.3), at(side * 1.05 * r, 0, 0))
	end
end

builders.Lollipop = function(model, r, kind)
	for i = 0, 3 do
		local d = r * (2 - i * 0.5)
		cyl(
			model,
			0.3 * r + i * 0.03 * r,
			d,
			if i % 2 == 0 then kind.Skin else Color3.fromRGB(255, 240, 250),
			at(0, 0.2 * r, 0) * Z_AXIS
		)
	end
	cyl(model, 1.3 * r, 0.18 * r, WHITE, at(0, -1.25 * r, 0) * Y_AXIS)
end

builders.IceCream = function(model, r, kind)
	local waffle = Color3.fromRGB(215, 160, 85)
	for i = 0, 4 do
		local d = 1.15 * r * (1 - i * 0.18)
		cyl(model, 0.3 * r, d, waffle, at(0, -0.15 * r - i * 0.28 * r, 0) * Y_AXIS, Enum.Material.Fabric)
	end
	ball(model, 1.35 * r, kind.Skin, at(0, 0.35 * r, 0))
	ball(model, 0.45 * r, kind.Skin, at(0.45 * r, -0.05 * r, -0.3 * r))
	ball(model, 0.38 * r, Color3.fromRGB(220, 20, 40), at(0, 1.1 * r, 0)).Reflectance = 0.15
end

---------------------------------------------------------------- toys

builders.BeachBall = function(model, r)
	local colours = { Color3.fromRGB(235, 40, 50), Color3.fromRGB(255, 215, 40), Color3.fromRGB(40, 120, 235) }
	for i = 0, 2 do
		cyl(model, 0.55 * r, 2.02 * r, colours[i + 1], CFrame.Angles(0, i * math.pi / 3, 0))
	end
	cyl(model, 2.06 * r, 0.35 * r, WHITE, Y_AXIS)
end

local function pips(model: Model, r: number, normal: Vector3, count: number)
	local s = 0.45 * r
	local layouts: { [number]: { { number } } } = {
		[1] = { { 0, 0 } },
		[2] = { { -1, -1 }, { 1, 1 } },
		[3] = { { -1, -1 }, { 0, 0 }, { 1, 1 } },
		[4] = { { -1, -1 }, { 1, 1 }, { -1, 1 }, { 1, -1 } },
		[5] = { { -1, -1 }, { 1, 1 }, { -1, 1 }, { 1, -1 }, { 0, 0 } },
		[6] = { { -1, -1 }, { -1, 0 }, { -1, 1 }, { 1, -1 }, { 1, 0 }, { 1, 1 } },
	}
	local face = CFrame.lookAlong(normal * 0.875 * r, normal) -- -Z of this frame faces outward
	for _, uv in layouts[count] do
		cyl(model, 0.04 * r, 0.3 * r, BLACK, face * at(uv[1] * s, uv[2] * s, 0) * Z_AXIS)
	end
end

builders.Dice = function(model, r)
	pips(model, r, Vector3.yAxis, 1)
	pips(model, r, -Vector3.yAxis, 6)
	pips(model, r, Vector3.xAxis, 3)
	pips(model, r, -Vector3.xAxis, 4)
	pips(model, r, Vector3.zAxis, 2)
	pips(model, r, -Vector3.zAxis, 5)
end

builders.Cube = function(model, r)
	local faces = {
		{ normal = Vector3.yAxis, color = Color3.fromRGB(250, 250, 250) },
		{ normal = -Vector3.yAxis, color = Color3.fromRGB(255, 215, 0) },
		{ normal = Vector3.xAxis, color = Color3.fromRGB(220, 30, 40) },
		{ normal = -Vector3.xAxis, color = Color3.fromRGB(255, 130, 0) },
		{ normal = Vector3.zAxis, color = Color3.fromRGB(30, 90, 230) },
		{ normal = -Vector3.zAxis, color = Color3.fromRGB(30, 180, 70) },
	}
	local step = 0.6 * r
	for _, f in faces do
		local face = CFrame.lookAlong(f.normal * 0.9 * r, f.normal)
		for u = -1, 1 do
			for v = -1, 1 do
				box(model, Vector3.new(0.52 * r, 0.52 * r, 0.04 * r), f.color, face * at(u * step, v * step, 0))
			end
		end
	end
end

builders.Top = function(model, r, kind)
	cyl(model, 0.5 * r, 2 * r, kind.Skin, Y_AXIS)
	cyl(model, 0.16 * r, 2.03 * r, Color3.fromRGB(230, 40, 60), Y_AXIS)
	cyl(model, 0.4 * r, 1.3 * r, Color3.fromRGB(230, 40, 60), at(0, 0.42 * r, 0) * Y_AXIS)
	cyl(model, 0.4 * r, 1.3 * r, Color3.fromRGB(40, 120, 230), at(0, -0.42 * r, 0) * Y_AXIS)
	cyl(model, 0.4 * r, 0.6 * r, Color3.fromRGB(40, 120, 230), at(0, -0.8 * r, 0) * Y_AXIS)
	cyl(model, 0.7 * r, 0.25 * r, WHITE, at(0, 0.95 * r, 0) * Y_AXIS)
	ball(model, 0.25 * r, Color3.fromRGB(80, 80, 90), at(0, -1.05 * r, 0))
end

builders.Car = function(model, r, kind)
	box(model, Vector3.new(1.1, 0.55, 2.0) * r, kind.Skin, at(0, -0.1 * r, 0)).Reflectance = 0.1
	box(model, Vector3.new(1.0, 0.45, 1.0) * r, kind.Skin, at(0, 0.38 * r, 0.15 * r))
	local glass = Color3.fromRGB(150, 210, 255)
	box(model, Vector3.new(0.85, 0.32, 0.05) * r, glass, at(0, 0.4 * r, -0.36 * r), Enum.Material.Glass)
	box(model, Vector3.new(0.85, 0.32, 0.05) * r, glass, at(0, 0.4 * r, 0.66 * r), Enum.Material.Glass)
	for _, side in { -1, 1 } do
		box(model, Vector3.new(0.05, 0.3, 0.8) * r, glass, at(side * 0.51 * r, 0.4 * r, 0.15 * r), Enum.Material.Glass)
		for _, z in { -0.6, 0.6 } do
			cyl(model, 0.25 * r, 0.6 * r, BLACK, at(side * 0.55 * r, -0.38 * r, z * r))
			cyl(model, 0.27 * r, 0.25 * r, Color3.fromRGB(200, 200, 210), at(side * 0.55 * r, -0.38 * r, z * r))
		end
		box(
			model,
			Vector3.new(0.22, 0.15, 0.05) * r,
			Color3.fromRGB(255, 240, 160),
			at(side * 0.35 * r, -0.05 * r, -1.0 * r),
			Enum.Material.Neon
		)
	end
end

---------------------------------------------------------------- plush animals

local FABRIC = Enum.Material.Fabric

builders.Teddy = function(model, r, kind)
	local light = kind.Skin:Lerp(Color3.fromRGB(255, 230, 190), 0.5)
	for _, side in { -1, 1 } do
		ball(model, 0.6 * r, kind.Skin, at(side * 0.68 * r, 0.68 * r, 0), FABRIC)
		ball(model, 0.36 * r, light, at(side * 0.7 * r, 0.7 * r, -0.16 * r), FABRIC)
	end
	ellipsoid(model, Vector3.new(0.75, 0.55, 0.5) * r, light, at(0, -0.2 * r, -0.8 * r), FABRIC)
	ellipsoid(model, Vector3.new(0.28, 0.18, 0.15) * r, BLACK, at(0, -0.08 * r, -1.05 * r))
	eyes(model, r, 0.22, 0.32, 0.9)
end

builders.Bunny = function(model, r, kind)
	local pink = Color3.fromRGB(255, 170, 190)
	for _, side in { -1, 1 } do
		local ear = at(side * 0.35 * r, 1.2 * r, 0) * CFrame.Angles(0, 0, math.rad(-side * 12))
		ellipsoid(model, Vector3.new(0.38, 1.25, 0.22) * r, kind.Skin, ear, FABRIC)
		ellipsoid(model, Vector3.new(0.2, 0.9, 0.1) * r, pink, ear * at(0, 0, -0.08 * r), FABRIC)
		ellipsoid(model, Vector3.new(0.3, 0.18, 0.08) * r, pink, at(side * 0.5 * r, -0.2 * r, -0.83 * r))
	end
	ball(model, 0.2 * r, pink, at(0, -0.1 * r, -0.98 * r))
	box(model, Vector3.new(0.2, 0.18, 0.05) * r, WHITE, at(0, -0.32 * r, -0.94 * r))
	eyes(model, r, 0.2, 0.32, 0.9)
end

builders.Duck = function(model, r, kind)
	local orange = Color3.fromRGB(255, 140, 20)
	ellipsoid(model, Vector3.new(0.8, 0.25, 0.7) * r, orange, at(0, -0.15 * r, -0.9 * r))
	ellipsoid(model, Vector3.new(0.15, 0.4, 0.3) * r, kind.Skin, at(0, 1.05 * r, 0) * CFrame.Angles(-0.4, 0, 0), FABRIC)
	for _, side in { -1, 1 } do
		ellipsoid(
			model,
			Vector3.new(0.25, 0.7, 0.9) * r,
			kind.Skin:Lerp(orange, 0.15),
			at(side * 0.95 * r, -0.2 * r, 0.1 * r),
			FABRIC
		)
	end
	eyes(model, r, 0.28, 0.33, 0.88)
end

builders.Penguin = function(model, r, kind)
	-- the body is an ellipsoid, so hide the default ball and build the shape on top
	ellipsoid(model, Vector3.new(1.8, 2, 1.8) * r, kind.Skin, CFrame.new(), FABRIC)
	ellipsoid(model, Vector3.new(1.3, 1.5, 1.0) * r, WHITE, at(0, -0.15 * r, -0.45 * r), FABRIC)
	local orange = Color3.fromRGB(255, 150, 30)
	ellipsoid(model, Vector3.new(0.35, 0.2, 0.4) * r, orange, at(0, 0.25 * r, -0.92 * r))
	for _, side in { -1, 1 } do
		ball(model, 0.3 * r, WHITE, at(side * 0.28 * r, 0.48 * r, -0.74 * r))
		ball(model, 0.15 * r, BLACK, at(side * 0.28 * r, 0.48 * r, -0.88 * r))
		ellipsoid(model, Vector3.new(0.5, 0.18, 0.6) * r, orange, at(side * 0.35 * r, -0.98 * r, -0.3 * r))
		ellipsoid(
			model,
			Vector3.new(0.2, 0.9, 0.5) * r,
			kind.Skin,
			at(side * 0.92 * r, -0.1 * r, 0) * CFrame.Angles(0, 0, math.rad(side * 15)),
			FABRIC
		)
	end
end

builders.Unicorn = function(model, r, kind)
	local gold = Color3.fromRGB(255, 200, 60)
	local horn = at(0, 0.9 * r, -0.25 * r) * CFrame.Angles(math.rad(-20), 0, 0)
	for i = 0, 3 do
		cyl(model, 0.27 * r, (0.4 - i * 0.1) * r, gold, horn * at(0, i * 0.24 * r, 0) * Y_AXIS, Enum.Material.Metal)
	end
	local mane = {
		Color3.fromRGB(255, 120, 190),
		Color3.fromRGB(180, 110, 255),
		Color3.fromRGB(90, 210, 255),
		Color3.fromRGB(255, 220, 90),
		Color3.fromRGB(255, 120, 190),
	}
	for i = 0, 4 do
		local a = math.rad(15 + i * 30)
		ball(model, 0.45 * r, mane[i + 1], at(0, math.cos(a) * 0.95 * r, math.sin(a) * 0.95 * r), FABRIC)
	end
	for _, side in { -1, 1 } do
		ellipsoid(model, Vector3.new(0.25, 0.45, 0.2) * r, kind.Skin, at(side * 0.45 * r, 0.85 * r, 0.1 * r), FABRIC)
		ellipsoid(
			model,
			Vector3.new(0.25, 0.15, 0.08) * r,
			Color3.fromRGB(255, 170, 200),
			at(side * 0.5 * r, -0.15 * r, -0.83 * r)
		)
	end
	ellipsoid(model, Vector3.new(0.8, 0.55, 0.4) * r, Color3.fromRGB(255, 220, 235), at(0, -0.38 * r, -0.8 * r), FABRIC)
	eyes(model, r, 0.15, 0.32, 0.9)
end

---------------------------------------------------------------- build

-- Shapes whose body is a plain visible ball of the skin colour.
local BALL_BODY = {
	Melon = true,
	Orange = true,
	Apple = true,
	Lemon = true,
	Kiwi = true,
	Dragonfruit = true,
	Bomb = true,
	BeachBall = true,
	Teddy = true,
	Bunny = true,
	Duck = true,
	Unicorn = true,
}
local BOX_BODY = { Dice = true, Cube = true }

function ObjectBuilder.Build(kind: Catalog.ObjectKind): Model
	local r = kind.Radius
	local model = Instance.new("Model")
	model.Name = kind.Name

	local body: BasePart
	if BALL_BODY[kind.Shape] then
		body = newPart({
			Shape = Enum.PartType.Ball,
			Size = Vector3.one * r * 2,
			Color = kind.Skin,
			Material = if kind.Shape == "Kiwi"
				then Enum.Material.Fabric
				elseif kind.Burst == "Fluff" then FABRIC
				else Enum.Material.SmoothPlastic,
			Reflectance = if kind.IsBomb then 0.1 elseif kind.Burst == "Fluff" then 0 else 0.05,
		})
	elseif BOX_BODY[kind.Shape] then
		local size = if kind.Shape == "Cube" then 1.8 else 1.75
		body = newPart({ Size = Vector3.one * r * size, Color = kind.Skin, Material = Enum.Material.SmoothPlastic })
	else
		-- invisible pivot at the centre; the visible shape is built by the builder
		body = newPart({ Size = Vector3.one * 0.2, Transparency = 1 })
	end
	body.Name = "Body"
	body.CFrame = CFrame.new()
	body.Parent = model
	model.PrimaryPart = body

	local builder = builders[kind.Shape]
	if builder then
		builder(model, r, kind)
	end
	return model
end

return ObjectBuilder
