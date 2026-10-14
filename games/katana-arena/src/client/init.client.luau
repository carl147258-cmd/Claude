-- StarterPlayer/StarterPlayerScripts/Client (LocalScript)
-- Fruit-Ninja-style slicing in third person: the camera sits behind the avatar, objects
-- fly across the screen and the player swipes over them (finger or held mouse button).
-- The avatar's sword arm follows the pointer. The client predicts cuts for instant
-- feedback; the server owns score, lives, coins and the shop.

local GuiService = game:GetService("GuiService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")
local UserInputService = game:GetService("UserInputService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Avatar = require(script:WaitForChild("Avatar"))
local FruitView = require(script:WaitForChild("FruitView"))
local Hud = require(script:WaitForChild("Hud"))
local Scenery = require(script:WaitForChild("Scenery"))
local Sfx = require(script:WaitForChild("Sfx"))
local Shop = require(script:WaitForChild("Shop"))

local remote = ReplicatedStorage:WaitForChild(Config.RemoteName) :: RemoteEvent
local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

local CUT_SPEED = 420 -- pointer speed (px/s) needed to cut
local SWISH_COOLDOWN = 0.16
local BASE_FOV = 70

local running = false
local shake = 0
local fovKick = 0

pcall(function()
	StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)
	StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Health, false)
end)

Sfx.Init()
Hud.Init(function()
	Shop.Close()
	remote:FireServer("Start")
end, function()
	Shop.Open()
end)
Hud.SetLives(Config.Lives)
FruitView.Init()
Shop.Init(remote)
Scenery.Apply("blutmond")

---------------------------------------------------------------- pointer

local pointerDown = false
local touchInput: InputObject? = nil
local cursor = camera.ViewportSize / 2
local lastCursor: Vector2? = nil
local wasCutting = false
local lastSwish = 0

local function toViewport(input: InputObject): Vector2
	return Vector2.new(input.Position.X, input.Position.Y) + GuiService:GetGuiInset()
end

UserInputService.InputBegan:Connect(function(input, processed)
	if processed then
		return
	end
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		pointerDown = true
	elseif input.UserInputType == Enum.UserInputType.Touch and not touchInput then
		touchInput = input
		pointerDown = true
		cursor = toViewport(input)
		lastCursor = cursor -- no cut from the previous finger position
	end
end)

UserInputService.InputChanged:Connect(function(input)
	if input == touchInput then
		cursor = toViewport(input)
	end
end)

UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input == touchInput then
		pointerDown = false
		touchInput = nil
	end
end)

---------------------------------------------------------------- camera

-- The camera looks at the avatar's back, which the scene lights rarely reach: a soft
-- local fill light between camera and avatar keeps it readable in every scene.
local fillLight: BasePart? = nil

local function updateCamera(dt: number)
	local eye = player:GetAttribute("Eye")
	if typeof(eye) ~= "CFrame" then
		return
	end
	camera.CameraType = Enum.CameraType.Scriptable
	if not fillLight then
		local part = Instance.new("Part")
		part.Name = "FillLight"
		part.Anchored = true
		part.CanCollide = false
		part.CanQuery = false
		part.CanTouch = false
		part.Transparency = 1
		part.Size = Vector3.one * 0.2
		part.CFrame = eye * CFrame.new(-1, -1, -5)
		local light = Instance.new("PointLight")
		light.Range = 16
		light.Brightness = 1.6
		light.Color = Color3.fromRGB(255, 240, 230)
		light.Parent = part
		part.Parent = workspace
		fillLight = part
	end
	-- slight parallax towards the pointer makes the static view feel alive
	local size = camera.ViewportSize
	local nx = math.clamp(cursor.X / math.max(size.X, 1) - 0.5, -0.5, 0.5)
	local ny = math.clamp(cursor.Y / math.max(size.Y, 1) - 0.5, -0.5, 0.5)
	local parallax = CFrame.Angles(-ny * math.rad(2), -nx * math.rad(3), 0)

	shake = math.max(shake - dt * 3.5, 0)
	local s = shake * shake
	local jitter = CFrame.new(math.noise(os.clock() * 28, 0) * 0.5 * s, math.noise(0, os.clock() * 28) * 0.5 * s, 0)
		* CFrame.Angles(0, 0, math.noise(os.clock() * 20, 7) * 0.05 * s)

	fovKick = fovKick * math.exp(-dt * 10)
	camera.FieldOfView = BASE_FOV - fovKick
	camera.CFrame = eye * parallax * jitter
end

---------------------------------------------------------------- cutting

local function cut(a: Vector2, b: Vector2)
	local hits = FruitView.FindHits(camera, a, b)
	if #hits == 0 then
		return
	end
	local dir = b - a
	local cf = camera.CFrame
	local swipeWorld = (cf.RightVector * dir.X - cf.UpVector * dir.Y).Unit
	local colors = Avatar.TrailColors()
	local cutObjects = 0
	local hitBomb = false
	for _, id in hits do
		local kind, position = FruitView.Slice(id, swipeWorld, cf, colors[#colors])
		if kind and position then
			local screen = camera:WorldToViewportPoint(position)
			local screenPos = Vector2.new(screen.X, screen.Y)
			if kind.IsBomb then
				hitBomb = true
			else
				cutObjects += 1
				Hud.Popup(`+{kind.Points}`, screenPos, Color3.fromRGB(255, 240, 160), 40)
				if kind.Burst == nil then
					Hud.Splat(screenPos, kind.Flesh, 1)
				end
			end
		end
	end
	-- Juice: freeze the arm for a few frames, kick the camera, layered cut sounds.
	Avatar.HitStop(0.04 + 0.015 * math.min(#hits, 4))
	shake = math.max(shake, 0.5 + 0.15 * #hits)
	fovKick = math.max(fovKick, 2 + #hits)
	if cutObjects > 0 then
		Sfx.Play("Slash")
		Sfx.Play("Splat")
	end
	if hitBomb then
		shake = 1.6
		fovKick = 10
		Hud.Flash(Color3.fromRGB(255, 240, 220), 0.9)
		Sfx.Play("Bomb")
	end
	if running then
		remote:FireServer("Slice", hits)
	end
end

RunService:BindToRenderStep("FruitCamera", Enum.RenderPriority.Camera.Value + 1, function(dt)
	if not touchInput then
		cursor = UserInputService:GetMouseLocation()
	end

	updateCamera(dt)
	FruitView.Update(camera.CFrame)

	local cutting = false
	if pointerDown and lastCursor and running then
		local segment = cursor - lastCursor
		cutting = segment.Magnitude / math.max(dt, 1e-3) >= CUT_SPEED
		if cutting then
			if not wasCutting and os.clock() - lastSwish > SWISH_COOLDOWN then
				lastSwish = os.clock()
				Sfx.Play("Swish")
			end
			Hud.Streak(lastCursor, cursor, Avatar.TrailColors())
			cut(lastCursor, cursor)
		end
	end
	wasCutting = cutting
	lastCursor = cursor
	Avatar.Update(dt, camera, cursor, running, cutting)
end)

---------------------------------------------------------------- server events

remote.OnClientEvent:Connect(function(action: string, ...)
	if action == "Spawn" then
		FruitView.Add(...)
	elseif action == "Sliced" then
		local _ids, _gained, score, combo = ...
		Hud.SetScore(score)
		if combo > 0 then
			local size = camera.ViewportSize
			Hud.Popup(`{combo}er-KOMBO! +{combo}`, Vector2.new(size.X / 2, size.Y * 0.3), Config.GlowColor, 64)
			Sfx.Play("Combo", 1 + (combo - Config.ComboMin) * 0.12)
			shake = math.max(shake, 1)
			fovKick = math.max(fovKick, 7)
		end
	elseif action == "Missed" then
		local id, lives = ...
		local position = FruitView.Remove(id)
		Hud.SetLives(lives)
		Hud.Flash(Color3.fromRGB(255, 0, 40), 0.3)
		Sfx.Play("Miss")
		if position then
			local screen = camera:WorldToViewportPoint(position)
			local size = camera.ViewportSize
			local x = math.clamp(screen.X, 40, size.X - 40)
			Hud.Popup("✕", Vector2.new(x, size.Y - 70), Color3.fromRGB(255, 40, 60), 70)
		end
	elseif action == "Bomb" then
		local lives = ...
		Hud.SetLives(lives)
		Hud.Flash(Color3.fromRGB(255, 60, 0), 0.6)
	elseif action == "State" then
		local isRunning, score, lives, _best = ...
		running = isRunning
		Hud.SetScore(score)
		Hud.SetLives(lives)
		if isRunning then
			Hud.HideMenu()
		end
	elseif action == "GameOver" then
		local score, best, newRecord, coins = ...
		running = false
		FruitView.Clear()
		Hud.ShowMenu(
			if newRecord then "NEUER REKORD!" else "RUNDE VORBEI",
			`Punkte: {score}   Rekord: {best}\n+{coins} Münzen`,
			"NOCHMAL"
		)
	elseif action == "Profile" then
		local coins, owned, equipped, doubleCoins = ...
		Hud.SetCoins(coins)
		Shop.SetProfile(coins, owned, equipped, doubleCoins)
		Scenery.Apply(equipped.Scenes)
	elseif action == "Daily" then
		local reward, day = ...
		Hud.Toast(`Tägliche Belohnung (Tag {day}/7): +{reward} Münzen`, Config.CoinColor)
		Sfx.Play("Combo")
	elseif action == "ShopResult" then
		local ok, message = ...
		Hud.Toast(message, if ok then Config.CoinColor else Color3.fromRGB(255, 120, 120))
		if ok then
			Sfx.Play("Combo")
		end
	end
end)

remote:FireServer("GetProfile")
