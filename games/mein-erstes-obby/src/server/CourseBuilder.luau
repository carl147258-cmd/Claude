--!strict
-- ServerScriptService/Server/CourseBuilder (ModuleScript)
-- Generates a playable course if Workspace has no "Course" folder.
-- To build your own course in Studio instead: create Workspace/Course/Checkpoints
-- with parts named "1", "2", ... and this module will leave it alone.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

local CourseBuilder = {}

local START = Vector3.new(0, 50, 40) -- high above the baseplate, so falling hits the lava
local STAGE_LENGTH = 48
local JUMPS_PER_STAGE = 3

local function makePart(props: { [string]: any }): Part
	local part = Instance.new("Part")
	part.Anchored = true
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	for key, value in props do
		(part :: any)[key] = value
	end
	return part
end

function CourseBuilder.BuildIfMissing(): Folder
	local existing = workspace:FindFirstChild("Course")
	if existing then
		return existing :: Folder
	end

	local course = Instance.new("Folder")
	course.Name = "Course"
	local checkpoints = Instance.new("Folder")
	checkpoints.Name = "Checkpoints"
	checkpoints.Parent = course
	local obstacles = Instance.new("Folder")
	obstacles.Name = "Obstacles"
	obstacles.Parent = course

	local stageCount = Config.StageCount
	for stage = 1, stageCount do
		local z = START.Z + (stage - 1) * STAGE_LENGTH
		local isLast = stage == stageCount

		local checkpoint = makePart({
			Name = tostring(stage),
			Size = Vector3.new(12, 1, 12),
			Position = Vector3.new(START.X, START.Y, z),
			Color = if isLast then Color3.fromRGB(255, 200, 0) else Color3.fromRGB(70, 200, 90),
			Material = Enum.Material.SmoothPlastic,
		})
		checkpoint:SetAttribute("Stage", stage)
		checkpoint.Parent = checkpoints

		if isLast then
			break
		end

		-- Difficulty rises: platforms shrink and zig-zag more.
		local progress = (stage - 1) / math.max(stageCount - 2, 1)
		local size = 6 - 2.5 * progress
		local sway = 1 + 4 * progress
		local kind = stage % 3 -- 1 = normal, 2 = disappearing, 0 = thin beams

		for jump = 1, JUMPS_PER_STAGE do
			local offsetX = if jump % 2 == 0 then sway else -sway
			local position = Vector3.new(START.X + offsetX, START.Y, z + jump * (STAGE_LENGTH / (JUMPS_PER_STAGE + 1)))
			local platform = makePart({
				Name = `Stage{stage}_Jump{jump}`,
				Size = if kind == 0 then Vector3.new(2, 1, size + 2) else Vector3.new(size, 1, size),
				Position = position,
				Color = if kind == 2 then Color3.fromRGB(120, 170, 255) else Color3.fromRGB(200, 200, 200),
				Material = Enum.Material.SmoothPlastic,
			})
			if kind == 2 then
				platform:AddTag("Disappearing")
			end
			platform.Parent = obstacles
		end
	end

	local length = stageCount * STAGE_LENGTH + 100
	local lava = makePart({
		Name = "Lava",
		Size = Vector3.new(200, 1, length),
		Position = Vector3.new(START.X, START.Y - 15, START.Z + length / 2 - 50),
		Color = Color3.fromRGB(255, 80, 0),
		Material = Enum.Material.Neon,
	})
	lava:AddTag("KillBrick")
	lava.Parent = course

	course.Parent = workspace
	return course
end

return CourseBuilder
