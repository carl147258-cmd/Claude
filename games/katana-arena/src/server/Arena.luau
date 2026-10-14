--!strict
-- ServerScriptService/Server/Arena (ModuleScript)
-- Builds the world at runtime: one floating platform per player slot and the hemisphere
-- template used for cut objects. Scenery and lighting are built per player on the client.

local GeometryService = game:GetService("GeometryService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

local Arena = {}

local folder: Folder

local function block(props: { [string]: any }, className: string?): BasePart
	local p = Instance.new((className or "Part") :: any) :: BasePart
	p.Anchored = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	for key, value in props do
		(p :: any)[key] = value
	end
	return p
end

-- The avatar stands in the middle of its platform, facing -Z (where the objects fly).
function Arena.SpawnCFrame(slot: number): CFrame
	return Config.SlotOrigin(slot) * CFrame.new(0, 3, 0)
end

local function buildSlot(slot: number)
	local origin = Config.SlotOrigin(slot)
	local model = Instance.new("Model")
	model.Name = `Platform{slot}`

	-- Stone pillar top with a wooden deck
	block({
		Name = "Rock",
		Size = Vector3.new(14, 30, 14),
		CFrame = origin * CFrame.new(0, -15.6, 0) * CFrame.Angles(0, math.rad(12), 0),
		Color = Color3.fromRGB(70, 62, 66),
		Material = Enum.Material.Slate,
	}).Parent =
		model
	for i = -3, 3 do
		block({
			Name = "Plank",
			Size = Vector3.new(1.6, 0.6, 11),
			CFrame = origin * CFrame.new(i * 1.62, -0.3, 0),
			Color = if i % 2 == 0 then Color3.fromRGB(120, 72, 42) else Color3.fromRGB(105, 62, 36),
			Material = Enum.Material.WoodPlanks,
		}).Parent =
			model
	end

	-- Red railing behind and at the sides, plus two lanterns at the front corners
	local railColor = Color3.fromRGB(170, 25, 30)
	for _, x in { -5.4, 5.4 } do
		block({
			Name = "Post",
			Size = Vector3.new(0.6, 3, 0.6),
			CFrame = origin * CFrame.new(x, 1.5, 5.2),
			Color = railColor,
			Material = Enum.Material.Wood,
		}).Parent =
			model
		block({
			Name = "Post",
			Size = Vector3.new(0.6, 2.2, 0.6),
			CFrame = origin * CFrame.new(x, 1.1, -5.2),
			Color = railColor,
			Material = Enum.Material.Wood,
		}).Parent =
			model
		local lantern = block({
			Name = "Lantern",
			Size = Vector3.new(0.9, 1.1, 0.9),
			CFrame = origin * CFrame.new(x, 2.75, -5.2),
			Color = Color3.fromRGB(255, 170, 80),
			Material = Enum.Material.Neon,
		})
		local light = Instance.new("PointLight")
		light.Color = Color3.fromRGB(255, 150, 70)
		light.Range = 14
		light.Brightness = 1.5
		light.Parent = lantern
		lantern.Parent = model
	end
	block({
		Name = "BackRail",
		Size = Vector3.new(11.4, 0.4, 0.4),
		CFrame = origin * CFrame.new(0, 2.6, 5.2),
		Color = railColor,
		Material = Enum.Material.Wood,
	}).Parent =
		model

	-- Invisible walls keep the player on the deck
	for _, wall in { { 6, 0, 0 }, { -6, 0, 0 }, { 0, 0, 6 }, { 0, 0, -6 } } do
		block({
			Name = "Barrier",
			Size = if wall[1] ~= 0 then Vector3.new(1, 12, 13) else Vector3.new(13, 12, 1),
			CFrame = origin * CFrame.new(wall[1], 6, wall[3]),
			Transparency = 1,
			CanQuery = false,
		}).Parent =
			model
	end

	model.Parent = folder
end

-- A hemisphere (Size 2x1x2, flat face at local -Y) the client clones for cut halves.
local function makeHemisphere()
	if ReplicatedStorage:FindFirstChild("Hemisphere") then
		return
	end
	local ball = block({ Shape = Enum.PartType.Ball, Size = Vector3.new(2, 2, 2), CFrame = CFrame.new() })
	local cutter = block({ Size = Vector3.new(4, 4, 4), CFrame = CFrame.new(0, -2, 0) })
	local ok, result = pcall(function()
		return GeometryService:SubtractAsync(ball, { cutter }, {
			CollisionFidelity = Enum.CollisionFidelity.Box,
			RenderFidelity = Enum.RenderFidelity.Precise,
			SplitApart = false,
		})
	end)
	ball:Destroy()
	cutter:Destroy()
	if ok and result[1] then
		local hemi = result[1] :: BasePart
		hemi.Name = "Hemisphere"
		hemi.Anchored = false
		hemi.CanCollide = false
		hemi.CanQuery = false
		hemi.CanTouch = false
		hemi.Parent = ReplicatedStorage
	else
		warn(`Hemisphere CSG failed, client falls back to spheres: {result}`)
	end
end

function Arena.Build()
	folder = Instance.new("Folder")
	folder.Name = "Arena"
	folder.Parent = workspace
	for slot = 1, Config.MaxSlots do
		buildSlot(slot)
	end
	makeHemisphere()
end

return Arena
