--!strict
-- ServerScriptService/Server/FruitGame (ModuleScript)
-- Server-authoritative rounds: the server decides every object's flight, validates each
-- slice (existence, timing, reach) and owns score, lives, coins and the game-over.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Catalog = require(Shared:WaitForChild("Catalog"))
local Config = require(Shared:WaitForChild("Config"))
local Arena = require(script.Parent.Arena)
local PlayerData = require(script.Parent.PlayerData)

type Fruit = {
	kind: number,
	p0: Vector3,
	v0: Vector3,
	g: number,
	t0: number,
	alive: boolean,
}

type Session = {
	running: boolean,
	round: number, -- increments per round so old timers can tell they are stale
	score: number,
	lives: number,
	nextId: number,
	setId: string, -- object set of the current round
	fruits: { [number]: Fruit },
	startedAt: number,
	lastSlice: number,
}

local remote: RemoteEvent
local sessions: { [Player]: Session } = {}
local slots: { [number]: Player } = {}
local rng = Random.new()

local FruitGame = {}

local function now(): number
	return workspace:GetServerTimeNow()
end

local function lerp(a: number, b: number, t: number): number
	return a + (b - a) * t
end

local function slotOf(player: Player): number?
	for slot, owner in slots do
		if owner == player then
			return slot
		end
	end
	return nil
end

local function sendState(player: Player, session: Session)
	remote:FireClient(player, "State", session.running, session.score, session.lives, PlayerData.GetBest(player))
end

local function endRound(player: Player, session: Session)
	if not session.running then
		return
	end
	session.running = false
	session.round += 1
	table.clear(session.fruits)
	local oldBest = PlayerData.GetBest(player)
	PlayerData.SetScore(player, session.score)
	local coins = session.score * Config.CoinsPerPoint
	PlayerData.AddCoins(player, coins)
	remote:FireClient(player, "GameOver", session.score, PlayerData.GetBest(player), session.score > oldBest, coins)
	task.spawn(PlayerData.Save, player)
end

local function loseLife(player: Player, session: Session)
	session.lives -= 1
	if session.lives <= 0 then
		endRound(player, session)
	end
end

local function spawnFruit(player: Player, session: Session, origin: CFrame, progress: number)
	local elapsed = now() - session.startedAt
	local isBomb = elapsed > Config.BombsAfter and rng:NextNumber() < Config.BombChance
	local set = Catalog.Find("Sets", session.setId)
	local kinds = if set and set.Kinds then #set.Kinds else 1
	local kind = if isBomb then 0 else rng:NextInteger(1, kinds)

	-- Launch from one side below the platform and peak towards the other side, so most
	-- objects fly across the view in front of the avatar.
	local side = if rng:NextNumber() < 0.5 then -1 else 1
	local depth = -Config.FieldForward + rng:NextNumber(-Config.FieldDepth, Config.FieldDepth)
	local p0 = (origin * CFrame.new(side * rng:NextNumber(4, Config.SpawnSide), -Config.SpawnBelow, depth)).Position
	local apex = (origin * CFrame.new(
		-side * rng:NextNumber(-Config.ApexSide * 0.3, Config.ApexSide),
		rng:NextNumber(Config.ApexUp[1], Config.ApexUp[2]),
		depth + rng:NextNumber(-1, 1)
	)).Position
	-- Toss so the object peaks exactly at `apex`: vy = sqrt(2 g h), time to apex T = vy / g.
	local g = lerp(Config.GravityStart, Config.GravityEnd, progress)
	local vy = math.sqrt(2 * g * (apex.Y - p0.Y))
	local timeToApex = vy / g
	local v0 = Vector3.new((apex.X - p0.X) / timeToApex, vy, (apex.Z - p0.Z) / timeToApex)

	session.nextId += 1
	local id = session.nextId
	local fruit: Fruit = { kind = kind, p0 = p0, v0 = v0, g = g, t0 = now(), alive = true }
	session.fruits[id] = fruit
	remote:FireClient(player, "Spawn", id, session.setId, kind, p0, v0, g, fruit.t0)

	local round = session.round
	task.delay(2 * timeToApex + Config.MissMargin, function()
		if session.round ~= round or not fruit.alive then
			return
		end
		fruit.alive = false
		session.fruits[id] = nil
		if kind ~= 0 then
			remote:FireClient(player, "Missed", id, session.lives - 1)
			loseLife(player, session)
		end
	end)
end

local function runRound(player: Player, session: Session)
	local slot = slotOf(player)
	if not slot then
		return
	end
	local origin = Config.SlotOrigin(slot)
	local round = session.round
	task.wait(1.2) -- short breath before the first object
	while session.running and session.round == round and player.Parent do
		local progress = math.clamp((now() - session.startedAt) / Config.RampSeconds, 0, 1)
		local maxWave = 1 + math.floor(progress * (Config.MaxPerWave - 1) + rng:NextNumber())
		for _ = 1, rng:NextInteger(1, maxWave) do
			spawnFruit(player, session, origin, progress)
			task.wait(rng:NextNumber(0.05, 0.25))
		end
		task.wait(lerp(Config.SpawnIntervalStart, Config.SpawnIntervalEnd, progress))
	end
end

local function onStart(player: Player)
	local session = sessions[player]
	if not session or session.running then
		return
	end
	session.running = true
	session.round += 1
	session.score = 0
	session.lives = Config.Lives
	session.startedAt = now()
	session.setId = PlayerData.GetEquipped(player, "Sets")
	table.clear(session.fruits)
	PlayerData.SetScore(player, 0)
	sendState(player, session)
	task.spawn(runRound, player, session)
end

local function onSlice(player: Player, ids: any)
	local session = sessions[player]
	if not session or not session.running or typeof(ids) ~= "table" then
		return
	end
	local t = now()
	if t - session.lastSlice < Config.SliceRateLimit then
		return
	end
	session.lastSlice = t

	local slot = slotOf(player)
	if not slot then
		return
	end
	local eye = Config.CameraCFrame(slot).Position
	local maxDistance = Config.Reach + Config.ReachTolerance

	local cut = {}
	local gained = 0
	local hitBomb = false
	for i, id in ids do
		if i > Config.MaxIdsPerSlice then
			break
		end
		local fruit = if typeof(id) == "number" then session.fruits[id] else nil
		if fruit and fruit.alive then
			local age = t - fruit.t0
			local pos = Config.FruitPosition(fruit.p0, fruit.v0, fruit.g, age)
			if age > 0.2 and (pos - eye).Magnitude <= maxDistance then
				fruit.alive = false
				session.fruits[id] = nil
				table.insert(cut, id)
				if fruit.kind == 0 then
					hitBomb = true
				else
					local kind = Catalog.GetKind(session.setId, fruit.kind)
					gained += if kind then kind.Points else 1
				end
			end
		end
	end
	if #cut == 0 then
		return
	end

	local fruitCount = #cut - (if hitBomb then 1 else 0)
	local combo = if fruitCount >= Config.ComboMin then fruitCount else 0
	gained += combo
	session.score += gained
	PlayerData.SetScore(player, session.score)
	remote:FireClient(player, "Sliced", cut, gained, session.score, combo)

	if hitBomb then
		remote:FireClient(player, "Bomb", session.lives - 1)
		loseLife(player, session)
	end
end

local function placeCharacter(player: Player, character: Model)
	local slot = slotOf(player)
	if not slot then
		return
	end
	local humanoid = character:WaitForChild("Humanoid") :: Humanoid
	local root = character:WaitForChild("HumanoidRootPart") :: BasePart
	humanoid.WalkSpeed = 0
	humanoid.UseJumpPower = false
	humanoid.JumpHeight = 0
	task.defer(function()
		character:PivotTo(Arena.SpawnCFrame(slot))
		root.Anchored = true
	end)
end

local function onPlayerAdded(player: Player)
	local slot
	for i = 1, Config.MaxSlots do
		if not slots[i] then
			slot = i
			break
		end
	end
	if not slot then
		player:Kick("Alle Plattformen sind belegt. Bitte versuche einen anderen Server.")
		return
	end
	slots[slot] = player
	player:SetAttribute("Eye", Config.CameraCFrame(slot))
	sessions[player] = {
		running = false,
		round = 0,
		score = 0,
		lives = Config.Lives,
		nextId = 0,
		setId = Catalog.Defaults.Sets,
		fruits = {},
		startedAt = 0,
		lastSlice = 0,
	}
	player.CharacterAdded:Connect(function(character)
		placeCharacter(player, character)
	end)
	if player.Character then
		placeCharacter(player, player.Character)
	end
end

function FruitGame.Start(): RemoteEvent
	remote = Instance.new("RemoteEvent")
	remote.Name = Config.RemoteName
	remote.Parent = ReplicatedStorage

	remote.OnServerEvent:Connect(function(player, action: any, payload: any)
		if action == "Start" then
			onStart(player)
		elseif action == "Slice" then
			onSlice(player, payload)
		end
	end)

	Players.PlayerAdded:Connect(onPlayerAdded)
	for _, player in Players:GetPlayers() do
		task.spawn(onPlayerAdded, player)
	end
	Players.PlayerRemoving:Connect(function(player)
		local session = sessions[player]
		if session then
			session.running = false
			session.round += 1
		end
		sessions[player] = nil
		local slot = slotOf(player)
		if slot then
			slots[slot] = nil
		end
	end)
	return remote
end

return FruitGame
