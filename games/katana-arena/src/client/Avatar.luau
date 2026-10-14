--!strict
-- StarterPlayerScripts/Client/Avatar (ModuleScript)
-- Third-person sword arm: the avatar's right arm (with the sword welded to the hand by
-- the server) points at the finger / mouse, so swipes swing the sword across the screen.
-- While slicing, fast blade movement leaves a glowing swoosh in the sword's trail colours.
-- Only the local client moves the arm, which is purely cosmetic.

local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Catalog = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Catalog"))

local AIM_SHARPNESS = 26 -- higher = the arm follows the pointer more tightly
local AIM_PLANE = 2.5 -- studs in front of the shoulder where the pointer ray is intersected
local REST_DIR = Vector3.new(0.85, -0.45, -0.25).Unit -- avatar space: sword held out to the right, visible beside the body
local SWOOSH_SPEED = 30 -- studs/s of the blade tip before a swoosh is drawn
local SWOOSH_STEP = 0.5 -- studs between swoosh slabs at the tip
local SWOOSH_FADE = 0.16
local SWOOSH_WIDTH = 0.7

local Avatar = {}

-- The shoulder joint, whichever rig the avatar uses: classic Motor6D (offset = C0) or
-- the newer AnimationConstraint rig (offset = Attachment0.CFrame). Both place the arm at
-- part0 * offset * Transform. The Animator writes Transform every frame, so the aim is
-- applied as Transform in PreSimulation (after animation, before rendering) — the
-- documented way to override animation procedurally. Changing C0 / attachments is
-- ignored by the constraint rig.
type Joint = {
	instance: Motor6D | AnimationConstraint,
	part0: BasePart,
	offset: CFrame,
}

local player = Players.LocalPlayer
local character: Model? = nil
local joint: Joint? = nil
local transform: CFrame? = nil -- latest arm rotation, applied every PreSimulation
local aim = Vector3.new(0, -1, 0)
local hitStopLeft = 0
local lastBase: Vector3? = nil
local lastTip: Vector3? = nil
local defaultTrail = { Color3.fromRGB(170, 60, 255), Color3.fromRGB(255, 35, 70) }
local shimmerModel: Model? = nil
local shimmerEdges: { BasePart } = {}

local straightJoints: { Motor6D | AnimationConstraint } = {} -- elbow and wrist, kept straight

local function findJoint(model: Model, names: { string }): Joint?
	for _, name in names do
		local found = model:FindFirstChild(name, true)
		if found and found:IsA("Motor6D") and found.Part0 then
			return { instance = found, part0 = found.Part0 :: BasePart, offset = found.C0 }
		elseif found and found:IsA("AnimationConstraint") then
			local attachment = found.Attachment0
			local part0 = attachment and attachment.Parent
			if attachment and part0 and part0:IsA("BasePart") then
				return { instance = found, part0 = part0, offset = attachment.CFrame }
			end
		end
	end
	return nil
end

local function bind(newCharacter: Model?)
	character = newCharacter
	joint = nil
	transform = nil
	lastTip = nil
	table.clear(straightJoints)
	if newCharacter then
		joint = findJoint(newCharacter, { "RightShoulder", "Right Shoulder" })
		-- A straight arm makes arm and blade one line towards the pointer (R6 has no elbow).
		for _, name in { "RightElbow", "RightWrist" } do
			local found = findJoint(newCharacter, { name })
			if found then
				table.insert(straightJoints, found.instance)
			end
		end
	end
end

RunService.PreSimulation:Connect(function()
	local current = joint
	if current and transform then
		(current.instance :: any).Transform = transform
		for _, straight in straightJoints do
			(straight :: any).Transform = CFrame.new()
		end
	end
end)

-- Shortest rotation that turns unit vector `from` onto unit vector `to`.
local function rotationBetween(from: Vector3, to: Vector3): CFrame
	local axis = from:Cross(to)
	local dot = math.clamp(from:Dot(to), -1, 1)
	if axis.Magnitude < 1e-5 then
		return if dot > 0 then CFrame.new() else CFrame.fromAxisAngle(Vector3.xAxis, math.pi)
	end
	return CFrame.fromAxisAngle(axis.Unit, math.acos(dot))
end

local function sword(): Model?
	local found = character and character:FindFirstChild("Sword")
	return if found and found:IsA("Model") then found else nil
end

-- Trail colours of the equipped sword (for the swoosh and the on-screen streak).
function Avatar.TrailColors(): { Color3 }
	local model = sword()
	local item = model and Catalog.Find("Swords", model:GetAttribute("SwordId"))
	return if item and item.Style then item.Style.Trail else defaultTrail
end

function Avatar.HitStop(seconds: number)
	hitStopLeft = math.max(hitStopLeft, seconds)
end

-- Glowing slabs along the outer blade between the last and the current blade position.
local function drawSwoosh(base0: Vector3, tip0: Vector3, base1: Vector3, tip1: Vector3, cameraPos: Vector3)
	local colors = Avatar.TrailColors()
	local steps = math.clamp(math.ceil((tip1 - tip0).Magnitude / SWOOSH_STEP), 1, 16)
	for i = 1, steps do
		local a = i / steps
		local base = base0:Lerp(base1, a)
		local tip = tip0:Lerp(tip1, a)
		local inner = base:Lerp(tip, 0.35)
		local along = tip - inner
		local length = along.Magnitude
		if length > 0.05 then
			local mid = (inner + tip) / 2
			local z = along.Unit
			local x = (cameraPos - mid):Cross(z)
			if x.Magnitude > 1e-3 then
				x = x.Unit
				local slab = Instance.new("Part")
				slab.Anchored = true
				slab.CanCollide = false
				slab.CanQuery = false
				slab.CanTouch = false
				slab.CastShadow = false
				slab.Material = Enum.Material.Neon
				slab.Color = colors[(i - 1) % #colors + 1]
				slab.Transparency = 0.35
				slab.Size = Vector3.new(SWOOSH_WIDTH, 0.03, length)
				slab.CFrame = CFrame.fromMatrix(mid, x, z:Cross(x))
				slab.Parent = workspace.CurrentCamera
				TweenService
					:Create(slab, TweenInfo.new(SWOOSH_FADE, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
						Transparency = 1,
						Size = Vector3.new(0.05, 0.03, length),
					})
					:Play()
				Debris:AddItem(slab, SWOOSH_FADE + 0.05)
			end
		end
	end
end

-- cursor: viewport pixels; active: a round is running (otherwise the arm rests);
-- slicing: pointer held and moving fast. Call every frame after the camera moved.
function Avatar.Update(dt: number, camera: Camera, cursor: Vector2, active: boolean, slicing: boolean)
	-- rebind on respawn, and keep looking while the rig is still loading its parts
	local liveCharacter = player.Character
	if
		liveCharacter ~= character
		or not joint
		or not joint.instance:IsDescendantOf(liveCharacter)
		or (#straightJoints < 2 and liveCharacter:FindFirstChild("RightLowerArm") ~= nil)
	then
		bind(player.Character)
	end
	local current = joint
	local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not current or not root then
		return
	end
	local part0 = current.part0
	local offset = current.offset
	if hitStopLeft > 0 then
		hitStopLeft -= dt
		return
	end

	local shoulder = (part0.CFrame * offset).Position
	local desired: Vector3
	if active then
		-- Aim at the pointer ray where it crosses a plane just in front of the avatar, so
		-- the arm sweeps across the screen instead of pointing into it.
		local look = root.CFrame.LookVector
		local ray = camera:ViewportPointToRay(cursor.X, cursor.Y)
		local denom = ray.Direction:Dot(look)
		local planePoint = shoulder + look * AIM_PLANE
		local t = if math.abs(denom) > 1e-3 then (planePoint - ray.Origin):Dot(look) / denom else 20
		local toTarget = ray.Origin + ray.Direction * t - shoulder
		desired = if toTarget.Magnitude > 0.1 then toTarget.Unit else aim
	else
		desired = root.CFrame:VectorToWorldSpace(REST_DIR)
	end
	aim = aim:Lerp(desired, 1 - math.exp(-AIM_SHARPNESS * dt))
	if aim.Magnitude < 1e-3 then
		aim = desired
	end
	aim = aim.Unit

	-- Rotate the arm (which hangs along -Y of the torso) onto the aim direction.
	local local0 = part0.CFrame:VectorToObjectSpace(aim)
	local rotation = rotationBetween(Vector3.new(0, -1, 0), local0)
	-- same rotation expressed after the joint offset: part0 * offset * T == part0 * rotation * offset
	transform = offset.Rotation:Inverse() * rotation * offset.Rotation

	local model = sword()
	local handle = model and model.PrimaryPart
	if not model or not handle then
		lastTip = nil
		return
	end
	-- Mythic blades: the glowing edge cycles through the colours of a galaxy
	if model:GetAttribute("Shimmer") then
		if shimmerModel ~= model then
			shimmerModel = model
			table.clear(shimmerEdges)
			for _, part in model:GetDescendants() do
				if part:IsA("BasePart") and part.Name == "Edge" then
					table.insert(shimmerEdges, part)
				end
			end
		end
		local t = os.clock()
		for i, edge in shimmerEdges do
			edge.Color = Color3.fromHSV((0.55 + 0.3 * math.sin(t * 1.5 + i * 0.45)) % 1, 0.65, 1)
		end
	end

	-- Roll the blade around the arm so its flat side faces the camera (a katana seen
	-- edge-on from behind the avatar is just a thin dark line).
	local grip = handle:FindFirstChild("SwordGrip")
	if grip and grip:IsA("Weld") and grip.Part0 then
		local hand = grip.Part0
		local base = CFrame.new(grip.C0.Position) * CFrame.Angles(math.pi, 0, 0)
		local toCamera = hand.CFrame:VectorToObjectSpace(camera.CFrame.Position - hand.Position)
		local inBase = base:VectorToObjectSpace(toCamera)
		grip.C0 = base * CFrame.Angles(0, math.atan2(-inBase.Z, inBase.X), 0)
	end

	local tipOffset = (model:GetAttribute("TipOffset") :: Vector3?) or Vector3.new(0, 5, 0)
	local baseOffset = (model:GetAttribute("BladeBase") :: Vector3?) or Vector3.new(0, 1, 0)
	local tip = handle.CFrame * tipOffset
	local base = handle.CFrame * baseOffset
	if slicing and lastTip and lastBase and (tip - lastTip).Magnitude / math.max(dt, 1e-3) > SWOOSH_SPEED then
		drawSwoosh(lastBase, lastTip, base, tip, camera.CFrame.Position)
	end
	lastTip = tip
	lastBase = base
end

return Avatar
