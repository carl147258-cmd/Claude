--!strict
-- ReplicatedStorage/Shared/SwordBuilder (ModuleScript)
-- Builds a sword model from primitive parts according to a Catalog sword style.
-- Local space: the grip is the Handle, the blade points along the Handle's +Y and the
-- cutting edge faces +Z. Used by the server (sword in the avatar's hand) and by the
-- client (shop previews).
-- Parts are joined with Welds (fixed C0), not WeldConstraints: a WeldConstraint
-- re-captures its offset when a part is moved, so welding the handle to a hand left
-- the blade behind at the build position. The scale is applied while building for the
-- same reason (no Model:ScaleTo afterwards).

local Catalog = require(script.Parent.Catalog)

local SEGMENT_LENGTH = 0.55
local BLADE_START = 1.0 -- y of the blade base above the handle centre
local BLADE_THICKNESS = 0.07

local SwordBuilder = {}

local buildScale = 1 -- scale of the sword currently being built (Build does not yield)

local function part(
	model: Model,
	handle: BasePart,
	props: { [string]: any },
	cframe: CFrame,
	className: string?
): BasePart
	local p = Instance.new((className or "Part") :: any) :: BasePart
	p.CanCollide = false
	p.CanTouch = false
	p.CanQuery = false
	p.Massless = true
	p.CastShadow = false
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	for key, value in props do
		(p :: any)[key] = value
	end
	p.Size *= buildScale
	local offset = CFrame.new(cframe.Position * buildScale) * cframe.Rotation
	p.CFrame = handle.CFrame * offset
	local weld = Instance.new("Weld")
	weld.Part0 = handle
	weld.Part1 = p
	weld.C0 = offset
	weld.Parent = p
	p.Parent = model
	return p
end

local function cycle(colors: { Color3 }, i: number): Color3
	return colors[(i - 1) % #colors + 1]
end

-- Returns the sword model; its PrimaryPart "Handle" is anchored at the origin.
-- Attributes: TipOffset / BladeBase (handle space, already scaled) for swoosh effects.
function SwordBuilder.Build(style: Catalog.SwordStyle, scale: number?): Model
	buildScale = scale or 1
	local model = Instance.new("Model")
	model.Name = "Sword"

	local handle = Instance.new("Part")
	handle.Name = "Handle"
	handle.Size = Vector3.new(0.26, 1.5, 0.32) * buildScale
	handle.Color = Color3.fromRGB(20, 18, 22)
	handle.Material = Enum.Material.Fabric
	handle.Anchored = true
	handle.CanCollide = false
	handle.CanTouch = false
	handle.CanQuery = false
	handle.Massless = true
	handle.CastShadow = false
	handle.CFrame = CFrame.new()
	handle.Parent = model
	model.PrimaryPart = handle

	-- Wrap: diamonds along both flat sides
	for i = 0, 5 do
		part(model, handle, {
			Name = "Wrap",
			Size = Vector3.new(0.28, 0.15, 0.15),
			Color = style.Wrap,
			Material = Enum.Material.Fabric,
		}, CFrame.new(0, -0.6 + i * 0.24, 0) * CFrame.Angles(math.rad(45), 0, 0))
	end

	part(model, handle, {
		Name = "Pommel",
		Size = Vector3.new(0.3, 0.12, 0.36),
		Color = style.Guard,
		Material = Enum.Material.Metal,
		Reflectance = 0.2,
	}, CFrame.new(0, -0.8, 0))

	-- Guard: rim, dark disc, glowing ring
	local up = CFrame.Angles(0, 0, math.rad(90)) -- cylinder axis X -> Y
	part(model, handle, {
		Name = "GuardRim",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(0.08, 0.82 + style.Width, 0.82 + style.Width),
		Color = style.Guard,
		Material = Enum.Material.Metal,
		Reflectance = 0.25,
	}, CFrame.new(0, 0.8, 0) * up)
	part(model, handle, {
		Name = "Guard",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(0.11, 0.7 + style.Width, 0.7 + style.Width),
		Color = Color3.fromRGB(15, 15, 18),
		Material = Enum.Material.Metal,
	}, CFrame.new(0, 0.8, 0) * up)
	part(model, handle, {
		Name = "GuardGlow",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(0.12, 0.5, 0.5),
		Color = style.Glow,
		Material = Enum.Material.Neon,
	}, CFrame.new(0, 0.8, 0) * up)
	part(model, handle, {
		Name = "Collar",
		Size = Vector3.new(0.12, 0.2, 0.34),
		Color = style.Guard,
		Material = Enum.Material.Metal,
		Reflectance = 0.3,
	}, CFrame.new(0, 0.95, 0))

	-- Blade: chain of segments curving towards the spine (-Z)
	local curve = math.rad(style.Curve)
	local cf = CFrame.new(0, BLADE_START, 0)
	local edgeParts = {}
	for i = 1, style.Segments do
		cf = cf * CFrame.Angles(-curve, 0, 0)
		local centre = cf * CFrame.new(0, SEGMENT_LENGTH / 2, 0)
		local segWidth = style.Width - (i - 1) * 0.012
		part(model, handle, {
			Name = "Blade",
			Size = Vector3.new(BLADE_THICKNESS, SEGMENT_LENGTH + 0.04, segWidth),
			Color = cycle(style.Blade, i),
			Material = style.BladeMaterial,
			Reflectance = if style.BladeMaterial == Enum.Material.Metal then 0.1 else 0,
		}, centre)
		if not style.BladeNeon then
			-- polished band near the edge
			part(model, handle, {
				Name = "Hamon",
				Size = Vector3.new(BLADE_THICKNESS + 0.01, SEGMENT_LENGTH + 0.04, 0.09),
				Color = Color3.fromRGB(230, 235, 245),
				Material = Enum.Material.Glass,
			}, centre * CFrame.new(0, 0, segWidth / 2 - 0.08))
		end
		table.insert(
			edgeParts,
			part(model, handle, {
				Name = "Edge",
				Size = Vector3.new(0.1, SEGMENT_LENGTH + 0.04, 0.1),
				Color = cycle(style.Edge, i),
				Material = Enum.Material.Neon,
			}, centre * CFrame.new(0, 0, segWidth / 2))
		)
		cf = cf * CFrame.new(0, SEGMENT_LENGTH, 0)
	end

	-- Tip: wedge with a straight spine and a sweeping glowing edge
	local tipWidth = style.Width - style.Segments * 0.012
	local tipHeight = 0.55
	part(model, handle, {
		Name = "Tip",
		Size = Vector3.new(BLADE_THICKNESS, tipHeight, tipWidth),
		Color = cycle(style.Blade, style.Segments + 1),
		Material = style.BladeMaterial,
	}, cf * CFrame.new(0, tipHeight / 2, 0) * CFrame.Angles(0, math.pi, 0), "WedgePart")
	local hyp = math.sqrt(tipHeight ^ 2 + tipWidth ^ 2)
	table.insert(
		edgeParts,
		part(model, handle, {
			Name = "Edge",
			Size = Vector3.new(0.1, hyp, 0.1),
			Color = cycle(style.Edge, style.Segments + 1),
			Material = Enum.Material.Neon,
		}, cf * CFrame.new(0, tipHeight / 2, 0) * CFrame.Angles(math.atan2(-tipWidth, tipHeight), 0, 0))
	)
	model:SetAttribute("TipOffset", (cf * CFrame.new(0, tipHeight, 0)).Position * buildScale)
	model:SetAttribute("BladeBase", Vector3.new(0, BLADE_START, 0) * buildScale)

	local light = Instance.new("PointLight")
	light.Color = style.Glow
	light.Brightness = 0.6
	light.Range = 7
	light.Parent = edgeParts[#edgeParts]

	-- Faint embers drifting off the blade
	local midBlade = Instance.new("Attachment")
	midBlade.Name = "Embers"
	midBlade.Position = Vector3.new(0, BLADE_START + style.Segments * SEGMENT_LENGTH / 2, 0) * buildScale
	midBlade.Parent = handle
	local embers = Instance.new("ParticleEmitter")
	embers.Name = "Embers"
	embers.Color = ColorSequence.new(style.Glow, style.Trail[1])
	embers.LightEmission = 1
	embers.Size = NumberSequence.new(0.09, 0)
	embers.Lifetime = NumberRange.new(0.5, 0.9)
	embers.Rate = 8
	embers.Speed = NumberRange.new(0.3, 1)
	embers.SpreadAngle = Vector2.new(180, 180)
	embers.Acceleration = Vector3.new(0, 2, 0)
	embers.Parent = midBlade

	if style.Sparkles then
		-- an invisible box around the blade emits twinkling stars along its whole length
		-- (the default particle texture is a star sparkle, ideal here)
		local bladeLength = style.Segments * SEGMENT_LENGTH
		local zone = part(model, handle, {
			Name = "SparkleZone",
			Size = Vector3.new(0.3, bladeLength, style.Width + 0.2),
			Transparency = 1,
		}, CFrame.new(0, BLADE_START + bladeLength / 2, 0))
		local stars = Instance.new("ParticleEmitter")
		stars.Name = "Stars"
		stars.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
			ColorSequenceKeypoint.new(0.5, style.Trail[1]),
			ColorSequenceKeypoint.new(1, style.Trail[#style.Trail]),
		})
		stars.LightEmission = 1
		stars.Size = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0),
			NumberSequenceKeypoint.new(0.3, 0.28 * buildScale),
			NumberSequenceKeypoint.new(1, 0),
		})
		stars.Lifetime = NumberRange.new(0.6, 1.1)
		stars.Rate = 30
		stars.Speed = NumberRange.new(0.2, 0.8)
		stars.SpreadAngle = Vector2.new(180, 180)
		stars.RotSpeed = NumberRange.new(-120, 120)
		stars.Parent = zone
	end
	if style.Shimmer then
		model:SetAttribute("Shimmer", true)
	end

	return model
end

return SwordBuilder
