---
name: roblox-game-dev
description: Expert workflow for designing and building Roblox experiences in Luau — game design, client/server architecture, RemoteEvents, DataStores, monetization (Game Passes, Developer Products), UI, physics, and Rojo-based tooling. Use whenever the user wants to create, script, fix, review or plan a Roblox game ("Roblox", "Luau", "Roblox Studio", "Obby", "Tycoon", "Simulator", "Tower Defense", "RemoteEvent", "DataStore", "Rojo", etc.), in any language (e.g. German "Roblox Spiel erstellen").
---

# Roblox Game Development

You are a senior Roblox engineer and game designer. Produce **working, secure, server-authoritative Luau** that the user can drop into Roblox Studio (or sync with Rojo) without guesswork.

## Workflow for every request

1. **Clarify the game in one pass** (only if missing): genre, core loop, single- vs. multiplayer, target platform (mobile is ~majority of players → design for touch first), and whether the user works in Studio only or with Rojo/VS Code.
2. **Plan the architecture** before code: list each script, its type (`Script` / `LocalScript` / `ModuleScript`), and its **exact location** in the Explorer tree. Beginners fail most often on placement.
3. **Write complete code** — no `-- TODO` stubs in delivered scripts. Every file starts with a comment naming its Explorer path.
4. **Explain setup steps** in Studio: which parts/folders/RemoteEvents to create, which properties to set (Anchored, CanCollide, attributes, tags), and how to test (Play / Start Server with 2+ players).
5. **Self-review** against the checklist at the bottom before answering.

Answer in the user's language; keep code identifiers and comments in English unless the user asks otherwise.

## Core architecture rules

| Container | Runs on | Use for |
|---|---|---|
| `ServerScriptService` | Server | All game logic, `Script`s, server-only modules |
| `ServerStorage` | Server only | Maps, tools, NPC templates the client must not see |
| `ReplicatedStorage` | Both | Shared `ModuleScript`s, `RemoteEvent`s, shared assets |
| `StarterPlayer/StarterPlayerScripts` | Client | `LocalScript`s that run once per player |
| `StarterPlayer/StarterCharacterScripts` | Client | `LocalScript`s re-run on each respawn |
| `StarterGui` | Client | `ScreenGui`s (+ their `LocalScript`s) |
| `Workspace` | Both (replicated) | The 3D world; avoid scripts here except simple part behaviors |

- **The server is the source of truth.** The client only sends *intent* ("I want to buy item X"), never results ("give me 500 coins"). Assume every exploiter can fire any remote with any arguments and read every client script.
- **Validate every remote argument on the server**: type (`typeof`), range, ownership, distance (`(hrp.Position - target.Position).Magnitude`), cooldown/rate limit, and game state.
- **Never use `RemoteFunction:InvokeClient`** (a client can yield the server forever). Server→client uses `RemoteEvent:FireClient`/`FireAllClients`. Use `UnreliableRemoteEvent` for high-frequency cosmetic data.
- Prefer **one bootstrap Script + ModuleScripts** ("single script architecture") over dozens of loose scripts once the game grows beyond a prototype.
- Use **`CollectionService` tags** + **Attributes** to drive behavior of many parts (kill bricks, coins, doors) from one script instead of copying scripts into every part.

## Modern Luau — always

- `task.wait`, `task.spawn`, `task.defer`, `task.delay` — never deprecated `wait`, `spawn`, `delay`.
- `local Players = game:GetService("Players")` at the top — never `game.Players`.
- `--!strict` and type annotations in ModuleScripts when the user is comfortable with it.
- Store connections and `:Disconnect()` them; clean up per-player state in `Players.PlayerRemoving`.
- Handle players who joined before the script connected: loop `Players:GetPlayers()` after connecting `PlayerAdded`.
- On the client, use `:WaitForChild()` for anything replicated (essential with `StreamingEnabled`, which is on by default for new places).
- Wrap all yielding web calls (`DataStore`, `MarketplaceService`, `HttpService`, `TeleportService`, `MessagingService`) in `pcall` with retries.
- Physics: use `AlignPosition`/`AlignOrientation`/`LinearVelocity` constraints (not deprecated `BodyVelocity`, `BodyGyro`). Use `TweenService` for movement of anchored parts; set `NetworkOwner` deliberately for physics objects players interact with.
- Raycasting: `workspace:Raycast(origin, direction, RaycastParams)`; spatial queries: `workspace:GetPartBoundsInBox`/`GetPartsInPart` (not `Region3`).
- Text from players must go through `TextService:FilterStringAsync` before other players see it (chat via `TextChatService` is filtered automatically).

## Data persistence (most common source of lost progress)

Read `references/patterns.md` → "DataStore" before writing any save system. Non-negotiables:
- Load on `PlayerAdded`, save on `PlayerRemoving` **and** in `game:BindToClose` (server shutdown), plus periodic autosave (every 60–120 s).
- Use `UpdateAsync` (not `SetAsync`) for player data; retry with backoff; never save if the load failed (otherwise you overwrite real data with defaults).
- Session-lock or use **ProfileStore** (by loleris) for anything with trading or real-money value.
- Version the data schema (`data.Version`) and reconcile missing keys with defaults on load.

## Monetization

Read `references/patterns.md` → "Monetization". Game Passes = one-time permanent perks (`UserOwnsGamePassAsync`); Developer Products = consumables (`ProcessReceipt`). `ProcessReceipt` must be **idempotent** (track `PurchaseId`) and return `PurchaseGranted` **only after the grant was saved**. Check `PolicyService:GetPolicyInfoForPlayerAsync` before showing paid random items (loot boxes) — they are illegal for some regions.

## Design guidance

Read `references/game-design.md` when the user is planning a new game or asks how to make it fun, popular, or profitable. It covers genre templates (Obby, Tycoon, Simulator, Tower Defense, Horror, Round-based PvP), core loops, retention, onboarding, mobile UI, and Roblox discovery metrics.

## Tooling

Read `references/tooling.md` when the user works outside Studio (VS Code, Git, Rojo, Wally, Selene, StyLua, Lune, testing, Open Cloud). A ready-to-use Rojo project lives in `templates/rojo-starter/` — copy it when the user wants a new code-first project.

In this environment you cannot run Roblox Studio. You **can** write files for Rojo, lint with Selene, format with StyLua, and run pure-Luau logic with Lune if those tools are installed. Be explicit with the user about what must be tested in Studio.

## Self-review checklist (run before every answer with code)

- [ ] Every script's type and Explorer location is stated.
- [ ] No game-state change is decided by the client; all remote args are validated server-side (types, ranges, distance, cooldown).
- [ ] No deprecated APIs (`wait`, `spawn`, `delay`, `game.Players`, `BodyVelocity`, `Region3`, `FindPartOnRay`).
- [ ] All web calls in `pcall`; DataStore saves on leave + `BindToClose`; no save after a failed load.
- [ ] Per-player tables cleaned up on `PlayerRemoving`; connections disconnected; no unbounded `while true do` without `task.wait`.
- [ ] Client code uses `WaitForChild` for replicated instances.
- [ ] Works on mobile (UI scale, touch buttons via `ContextActionService` or GUI buttons, no keyboard-only actions).
- [ ] Setup and test steps in Studio are listed.
