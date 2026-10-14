--!strict
-- StarterPlayerScripts/Client/FruitView (ModuleScript)
-- Renders the objects the server launched (deterministic flight, so no network jitter),
-- finds objects under a swipe and plays the cut effects: two real halves, juice or fluff, flash.

local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Catalog = require(Shared:WaitForChild("Catalog"))
local Config = require(Shared:WaitForChild("Config"))
local ObjectBuilder = require(Shared:WaitForChild("ObjectBuilder"))

type Fruit = {
	kind: Catalog.ObjectKind,
	kindId: number,
	model: Model,
	p0: Vector3,
	v0: Vector3,
	g: number,
	t0: number,
	spinAxis: Vector3,
	spinSpeed: number,
	shine: BasePart?,
	trailAnchor: BasePart,
}

local FruitView = {}

local folder: Folder
local fruits: { [number]: Fruit } = {}
local rng = Random.new()

local function now(): number
	return workspace:GetServerTimeNow()
end

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

function FruitView.Init()
	folder = Instance.new("Folder")
	folder.Name = "Fruits"
	folder.Parent = workspace
end

function FruitView.Add(id: number, setId: string, kindId: number, p0: Vector3, v0: Vector3, g: number, t0: number)
	local kind = Catalog.GetKind(setId, kindId)
	if not kind then
		return
	end
	local model = ObjectBuilder.Build(kind)
	model:PivotTo(CFrame.new(p0))
	model.Parent = folder
	-- Specular highlight on glossy objects: kept separate from the spinning model so it
	-- always faces the light. Plush and toys stay matte.
	local shine: BasePart? = nil
	if kind.Burst == nil then
		local part = newPart({
			Name = "Shine",
			Shape = Enum.PartType.Ball,
			Size = Vector3.one * kind.Radius * 0.42,
			Color = Color3.new(1, 1, 1),
			Transparency = if kind.IsBomb then 0.6 else 0.25,
		})
		part.Parent = model
		shine = part
	end
	-- Cartoon outline so objects read clearly against every scene
	if not kind.IsBomb then
		local outline = Instance.new("Highlight")
		outline.FillTransparency = 1
		outline.OutlineColor = kind.Skin:Lerp(Color3.new(0, 0, 0), 0.65)
		outline.OutlineTransparency = 0.05
		outline.DepthMode = Enum.HighlightDepthMode.Occluded
		outline.Parent = model
	end
	-- Short motion trail in the object's colour (on a non-spinning anchor)
	local anchor = newPart({ Name = "TrailAnchor", Transparency = 1, Size = Vector3.one * 0.2 })
	local top = Instance.new("Attachment")
	top.Position = Vector3.new(0, kind.Radius * 0.22, 0) -- narrow: a wide trail washes over the object
	top.Parent = anchor
	local bottom = Instance.new("Attachment")
	bottom.Position = Vector3.new(0, -kind.Radius * 0.22, 0)
	bottom.Parent = anchor
	local trail = Instance.new("Trail")
	trail.Attachment0 = top
	trail.Attachment1 = bottom
	trail.FaceCamera = true
	trail.Lifetime = 0.22
	trail.LightEmission = 0.25
	trail.Color = ColorSequence.new(kind.Skin)
	trail.Transparency = NumberSequence.new(0.6, 1)
	trail.WidthScale = NumberSequence.new(1, 0.1)
	trail.Parent = anchor
	anchor.CFrame = CFrame.new(p0)
	anchor.Parent = model
	fruits[id] = {
		kind = kind,
		kindId = kindId,
		model = model,
		p0 = p0,
		v0 = v0,
		g = g,
		t0 = t0,
		spinAxis = rng:NextUnitVector(),
		-- plush animals tumble slowly so their faces stay readable
		spinSpeed = if kind.Burst == "Fluff" then rng:NextNumber(1, 2.5) else rng:NextNumber(2, 6),
		shine = shine,
		trailAnchor = anchor,
	}
end

function FruitView.Update(cameraCFrame: CFrame)
	local t = now()
	for id, fruit in fruits do
		local age = t - fruit.t0
		if age > 8 then
			fruit.model:Destroy()
			fruits[id] = nil
		else
			local pos = Config.FruitPosition(fruit.p0, fruit.v0, fruit.g, math.max(age, 0))
			fruit.model:PivotTo(CFrame.new(pos) * CFrame.fromAxisAngle(fruit.spinAxis, age * fruit.spinSpeed))
			fruit.trailAnchor.CFrame = CFrame.new(pos)
			local shine = fruit.shine
			if shine then
				local r = fruit.kind.Radius
				local toCamera = (cameraCFrame.Position - pos).Unit
				shine.CFrame = CFrame.new(
					pos + (toCamera * 0.62 + cameraCFrame.UpVector * 0.5 - cameraCFrame.RightVector * 0.38) * r
				)
			end
		end
	end
end

local function distanceToSegment(p: Vector2, a: Vector2, b: Vector2): number
	local ab = b - a
	local lengthSq = ab:Dot(ab)
	local u = if lengthSq > 0 then math.clamp((p - a):Dot(ab) / lengthSq, 0, 1) else 0
	return (a + ab * u - p).Magnitude
end

-- Ids of objects whose on-screen disc touches the swipe segment a→b (viewport pixels)
-- and that are within reach.
function FruitView.FindHits(camera: Camera, a: Vector2, b: Vector2): { number }
	local hits = {}
	local t = now()
	local pixelsPerStudAtOne = camera.ViewportSize.Y / (2 * math.tan(math.rad(camera.FieldOfView) / 2))
	for id, fruit in fruits do
		local pos = Config.FruitPosition(fruit.p0, fruit.v0, fruit.g, t - fruit.t0)
		local screen, onScreen = camera:WorldToViewportPoint(pos)
		if onScreen and screen.Z > 0 and screen.Z <= Config.Reach then
			local radiusPx = fruit.kind.Radius * pixelsPerStudAtOne / screen.Z
			if distanceToSegment(Vector2.new(screen.X, screen.Y), a, b) <= radiusPx + 30 then
				table.insert(hits, id)
			end
		end
	end
	return hits
end

local hemisphere = ReplicatedStorage:WaitForChild("Hemisphere", 5) :: BasePart?

local function weldTo(half: BasePart, part: BasePart)
	part.Anchored = false
	part.Massless = true
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = half
	weld.Part1 = part
	weld.Parent = half
	part.Parent = half
end

local function makeHalf(kind: Catalog.ObjectKind, centre: Vector3, normal: Vector3, across: Vector3): BasePart
	local r = kind.Radius
	local up = normal.Unit
	local right = across:Cross(up).Unit
	local back = right:Cross(up)
	local isBox = kind.Half == "Box"
	local thickness = if isBox then r * 0.875 else r
	local cf = CFrame.fromMatrix(centre + up * (thickness / 2), right, up, back)
	local half: BasePart
	if isBox then
		half = newPart({ Size = Vector3.new(2 * thickness, thickness, 2 * thickness) })
	elseif hemisphere then
		half = hemisphere:Clone()
		half.Size = Vector3.new(2 * r, r, 2 * r);
		(half :: any).UsePartColor = true
	else
		half = newPart({ Shape = Enum.PartType.Ball, Size = Vector3.one * r * 1.6 })
	end
	half.Color = kind.Skin
	half.Material = if kind.Burst == "Fluff" then Enum.Material.Fabric else Enum.Material.SmoothPlastic
	half.Anchored = false
	half.CanCollide = false
	half.CFrame = cf

	-- cut face
	local face: BasePart
	if isBox then
		face = newPart({ Size = Vector3.new(2 * thickness - 0.1, 0.06, 2 * thickness - 0.1), Color = kind.Flesh })
		face.CFrame = cf * CFrame.new(0, -thickness / 2 + 0.02, 0)
	else
		face = newPart({
			Shape = Enum.PartType.Cylinder,
			Size = Vector3.new(0.06, r * 1.9, r * 1.9),
			Color = kind.Flesh,
			Material = if kind.Burst == "Fluff" then Enum.Material.Fabric else Enum.Material.SmoothPlastic,
		})
		face.CFrame = cf * CFrame.new(0, -r / 2 + 0.02, 0) * CFrame.Angles(0, 0, math.pi / 2)
	end
	weldTo(half, face)
	if kind.Shape == "Kiwi" or kind.Shape == "Dragonfruit" then
		-- seeds ring
		local seeds = newPart({
			Shape = Enum.PartType.Cylinder,
			Size = Vector3.new(0.07, r * 1.1, r * 1.1),
			Color = Color3.fromRGB(25, 20, 20),
		})
		seeds.CFrame = face.CFrame
		weldTo(half, seeds)
		local core = newPart({
			Shape = Enum.PartType.Cylinder,
			Size = Vector3.new(0.08, r * 0.8, r * 0.8),
			Color = kind.Flesh,
		})
		core.CFrame = face.CFrame
		weldTo(half, core)
	end
	return half
end

-- Round, blobby particle (the default texture is a star sparkle, which reads as glitter, not juice)
local DROP_TEXTURE = "rbxasset://textures/particles/explosion01_core_main.dds"
local CONFETTI = {
	Color3.fromRGB(255, 80, 120),
	Color3.fromRGB(255, 210, 60),
	Color3.fromRGB(80, 200, 255),
	Color3.fromRGB(140, 230, 100),
	Color3.fromRGB(190, 120, 255),
}

local function burst(position: Vector3, color: Color3, amount: number, speed: number, size: number, texture: string?)
	local holder = newPart({ Transparency = 1, Size = Vector3.one * 0.2 })
	holder.CFrame = CFrame.new(position)
	holder.Parent = folder
	local emitter = Instance.new("ParticleEmitter")
	if texture ~= "" then
		emitter.Texture = texture or DROP_TEXTURE
	end
	emitter.Color = ColorSequence.new(color)
	emitter.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, size),
		NumberSequenceKeypoint.new(1, 0),
	})
	emitter.Lifetime = NumberRange.new(0.35, 0.7)
	emitter.Speed = NumberRange.new(speed * 0.5, speed)
	emitter.SpreadAngle = Vector2.new(180, 180)
	emitter.Acceleration = Vector3.new(0, -45, 0)
	emitter.Drag = 2
	emitter.LightInfluence = 0.6
	emitter.RotSpeed = NumberRange.new(-200, 200)
	emitter.Rate = 0
	emitter.Parent = holder
	emitter:Emit(amount)
	Debris:AddItem(holder, 1)
end

local function flashDisc(position: Vector3, facing: Vector3, color: Color3, size: number)
	local disc = newPart({
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(0.05, size * 0.4, size * 0.4),
		Color = color,
		Material = Enum.Material.Neon,
		Transparency = 0.35,
	})
	disc.CFrame = CFrame.lookAlong(position, facing) * CFrame.Angles(0, math.pi / 2, 0)
	disc.Parent = folder
	TweenService:Create(disc, TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Size = Vector3.new(0.05, size, size),
		Transparency = 1,
	}):Play()
	Debris:AddItem(disc, 0.3)
end

local function slashLine(position: Vector3, swipe: Vector3, facing: Vector3, length: number, color: Color3)
	local line = newPart({
		Size = Vector3.new(length, 0.25, 0.02),
		Color = color,
		Material = Enum.Material.Neon,
	})
	line.CFrame = CFrame.fromMatrix(position, swipe.Unit, facing:Cross(swipe).Unit)
	line.Parent = folder
	TweenService:Create(line, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Size = Vector3.new(length * 1.6, 0.02, 0.02),
		Transparency = 1,
	}):Play()
	Debris:AddItem(line, 0.25)
end

-- Plays the cut locally right away (the server confirms the score separately).
-- Returns the kind that was cut and where, or nil if the object no longer exists.
function FruitView.Slice(
	id: number,
	swipeWorld: Vector3,
	cameraCFrame: CFrame,
	slashColor: Color3?
): (Catalog.ObjectKind?, Vector3?)
	local fruit = fruits[id]
	if not fruit then
		return nil, nil
	end
	fruits[id] = nil
	local age = now() - fruit.t0
	local centre = Config.FruitPosition(fruit.p0, fruit.v0, fruit.g, age)
	local velocity = Config.FruitVelocity(fruit.v0, fruit.g, age)
	fruit.model:Destroy()
	local kind = fruit.kind
	local r = kind.Radius
	local look = (centre - cameraCFrame.Position).Unit

	if kind.IsBomb then
		flashDisc(centre, -look, Color3.fromRGB(255, 220, 150), 14 * r)
		burst(centre, Color3.fromRGB(255, 140, 20), 60, 35 * r, 0.35 * r)
		burst(centre, Color3.fromRGB(40, 40, 40), 30, 18 * r, 0.35 * r)
		return kind, centre
	end

	-- The cut plane contains the swipe and the view direction; halves fly apart along its normal.
	local normal = swipeWorld:Cross(look)
	if normal.Magnitude < 1e-3 then
		normal = Vector3.yAxis
	end
	normal = normal.Unit
	local drift = velocity * 0.35
	local scale = r / 2.3 -- effects were tuned for objects of radius ~2.3
	for _, side in { 1, -1 } do
		local half = makeHalf(kind, centre, normal * side, swipeWorld)
		half.Parent = folder
		half.AssemblyLinearVelocity = drift
			+ (normal * side * rng:NextNumber(9, 13) + swipeWorld.Unit * 7) * scale * 1.6
		half.AssemblyAngularVelocity = (swipeWorld:Cross(normal * side)).Unit * rng:NextNumber(6, 11)
		local trail = Instance.new("ParticleEmitter")
		if kind.Burst == "Fluff" then
			-- cotton puffs drifting out of the seam
			trail.Texture = DROP_TEXTURE
			trail.Color = ColorSequence.new(Color3.fromRGB(255, 255, 255))
			trail.Size = NumberSequence.new(r * 0.25, r * 0.05)
			trail.Lifetime = NumberRange.new(0.5, 0.9)
			trail.Rate = 25
			trail.Speed = NumberRange.new(1, 3)
			trail.Acceleration = Vector3.new(0, -6, 0)
		elseif kind.Burst == "Sparkle" then
			trail.Color = ColorSequence.new(kind.Skin:Lerp(Color3.new(1, 1, 1), 0.4))
			trail.Size = NumberSequence.new(r * 0.12, 0)
			trail.Lifetime = NumberRange.new(0.3, 0.5)
			trail.Rate = 30
			trail.Speed = NumberRange.new(1, 3)
			trail.LightEmission = 0.6
		else
			-- juice dripping from the cut face while the half tumbles away
			trail.Texture = DROP_TEXTURE
			trail.Color = ColorSequence.new(kind.Flesh)
			trail.Size = NumberSequence.new(r * 0.22, 0)
			trail.Lifetime = NumberRange.new(0.3, 0.5)
			trail.Rate = 40
			trail.Speed = NumberRange.new(1, 3)
			trail.Acceleration = Vector3.new(0, -40, 0)
			trail.EmissionDirection = Enum.NormalId.Bottom
		end
		trail.LightInfluence = 0.6
		trail.Parent = half
		Debris:AddItem(half, 2.5)
	end

	if kind.Burst == "Fluff" then
		burst(centre, Color3.fromRGB(255, 255, 255), 24, 16 * scale, 0.5 * r)
		for _, color in CONFETTI do
			burst(centre, color, 8, 30 * scale, 0.14 * r)
		end
	elseif kind.Burst == "Sparkle" then
		burst(centre, kind.Skin, 18, 24 * scale, 0.22 * r)
		burst(centre, Color3.fromRGB(255, 255, 255), 16, 28 * scale, 0.2 * r, "")
	else
		burst(centre, kind.Flesh, 28, 26 * scale, 0.16 * r)
	end
	flashDisc(centre, -look, kind.Flesh, r * 2.8)
	slashLine(centre, swipeWorld, -look, r * 5, slashColor or Color3.new(1, 1, 1))
	return kind, centre
end

function FruitView.Clear()
	for id, fruit in fruits do
		fruit.model:Destroy()
		fruits[id] = nil
	end
end

-- Missed objects keep falling out of view; stop tracking them for hits.
-- Returns where the object is now (for the miss marker).
function FruitView.Remove(id: number): Vector3?
	local fruit = fruits[id]
	if fruit then
		fruits[id] = nil
		Debris:AddItem(fruit.model, 1.5)
		local model = fruit.model
		local p0, v0, g, t0 = fruit.p0, fruit.v0, fruit.g, fruit.t0
		task.spawn(function()
			while model.Parent do
				local age = now() - t0
				model:PivotTo(CFrame.new(Config.FruitPosition(p0, v0, g, age)))
				task.wait()
			end
		end)
		return Config.FruitPosition(p0, v0, g, now() - t0)
	end
	return nil
end

return FruitView
