# Roblox Game Design Guide

## How Roblox decides who sees your game
Discovery recommends experiences based on engagement, not just clicks. What matters most:
- **Session length / playtime** and **D1 / D7 retention** (do players come back?).
- **Qualified play-through rate**: click-through on the thumbnail *and* players staying past the first minutes.
- Monetization and social signals (playing with friends, inviting) help, too.

Design consequence: the **first 60 seconds** decide everything. Player must understand the goal and feel progress within a minute — no long text tutorials, no empty lobbies.

## Core loop first
Write the loop as one sentence before any code: *"Collect → sell → upgrade → collect faster."* Every feature must feed this loop or a meta-loop around it (rebirth, collection, social status).

Layers:
1. **Core loop** (seconds): the action you repeat (jump, click, fight, place tower).
2. **Progression loop** (minutes): currency → upgrades → new areas.
3. **Meta loop** (days): rebirth/prestige, collections, daily rewards, events, leaderboards.

## Genre templates

| Genre | Core loop | Must-haves | Pitfalls |
|---|---|---|---|
| **Obby** | Jump → checkpoint → next stage | Checkpoints saved to DataStore, stage counter in leaderstats, skip-stage Developer Product, clear visual difficulty curve | Unfair invisible kill bricks, laggy moving parts (animate on client or use TweenService on anchored parts) |
| **Tycoon** | Earn passively → buy droppers/buttons → earn faster | Plot claiming per player, button dependency chain, save/restore builds, rebirth | Hundreds of droppers → part count lag; pool/clean drops |
| **Simulator** | Click/collect → sell → better tool/pet → new zone | Number formatting (1.2K, 3.4M), pets with eggs (check PolicyService!), zones gated by currency, rebirths, boosts | Inflation without sinks, DataStore spam |
| **Tower Defense** | Place towers → waves → upgrade | Server-side enemy pathing (move on server with CFrame, render smoothly on client), wave config tables, lobby → match teleport | Physics-based enemies (expensive), trusting client tower placement |
| **Horror / Story** | Explore → solve → escape | Atmosphere (Lighting, Atmosphere, sounds), scripted events, party lobby, chapters | Too dark on mobile, unskippable cutscenes |
| **Round-based PvP / Minigames** | Lobby → round → reward | Robust round state machine, spectate, AFK handling, matchmaking with min players | Server-authoritative hit detection must be latency-tolerant |
| **Roleplay / Hangout** | Socialize, customize | Houses, vehicles, jobs, emotes, avatar items | Moderation, text filtering |

## Retention toolkit
- Daily login rewards with streaks (store last claim as `os.time()`; compare UTC days).
- Timed/limited events and weekly updates (the algorithm rewards update cadence).
- Group rewards (`player:IsInGroup(groupId)`) and favorites/likes prompts *after* positive moments.
- Social: friend boosts (`player:IsFriendsWith`), party systems, trading (needs anti-dupe session locking).
- Leaderboards (global via OrderedDataStore, server via leaderstats).
- Clear goals on screen at all times ("Next zone: 5,000 coins").

## Monetization that players accept
- **Game Passes** (permanent): VIP, 2x Coins, extra pet slots, auto-collect, faster walk speed in lobby.
- **Developer Products** (repeatable): currency packs, skip stage, revive, boosts (timed).
- **Premium Payouts**: you earn by Premium players' engagement time — another reason to optimize playtime.
- **Subscriptions** and avatar item sales (UGC) are additional options for larger games.
- Avoid pay-to-win in PvP; sell convenience, cosmetics, and time savers.
- Price ladder: cheap entry (25–99 Robux), mid (199–499), whale (999+).
- Paid random items (loot boxes/eggs bought with Robux) require a `PolicyService` check and must be hidden where `ArePaidRandomItemsRestricted` is true.

## Onboarding
- Spawn facing the first objective; use a `Beam` or arrow to guide.
- Teach by doing: one prompt at a time, triggered by context.
- Grant an early win (first upgrade within 30 s).

## Mobile-first
- Most Roblox players are on phones: big buttons, `Scale`-based UI, no hover-only info, test with Studio's Device Emulator.
- Keep part count and unique meshes low; use `StreamingEnabled`; avoid many `Unanchored` parts.
- Use `ContextActionService:BindAction(..., true)` to create on-screen buttons automatically for mobile.

## Performance budget
- Use the MicroProfiler (Ctrl+F6) and Developer Console (F9) → Memory / ScriptProfiler.
- Avoid per-frame server loops over all parts; use events, tags, or `RunService.Heartbeat` with throttling.
- Visual-only effects (spinning coins, particles, tweens) belong on the **client**.
- Pool frequently created objects (projectiles, drops) instead of `Instance.new`/`Destroy` every time.

## Safety & policies
- Follow Roblox Community Standards and Terms; set the experience's content maturity questionnaire correctly.
- Filter all user-generated text with `TextService`. Never collect personal data or link off-platform in ways that violate rules.
- Don't use copyrighted music/IP; use the Creator Store with proper licensing.

## Launch checklist
- [ ] Icon (512×512) and thumbnails (1920×1080) that show gameplay clearly.
- [ ] Description with keywords; correct genre; maturity questionnaire completed.
- [ ] Data saving tested with "Start Server + 2 Players" and real server shutdown.
- [ ] Mobile, tablet, console (gamepad) controls tested.
- [ ] Analytics: `AnalyticsService` custom events for funnel (tutorial steps), economy (sources/sinks), progression.
- [ ] Update plan for the first 4 weeks.
