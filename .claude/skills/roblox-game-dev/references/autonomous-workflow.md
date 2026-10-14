# Autonomous Workflow — taking over the whole build

Goal: the user gives (or co-writes) the plan; Claude does design detailing, building, scripting, testing and publishing prep. The user decides, plays and gives feedback.

## 1. Pick the working mode (check which tools exist in this session)

| Mode | When | What Claude can do | What the user must do |
|---|---|---|---|
| **A. Local + Studio MCP** (best) | Claude Code / Claude Desktop runs on the user's PC with Studio open and "Enable Studio as MCP server" on | Read/edit the live place, write scripts, build with parts, insert/generate assets, run Luau, start/stop playtests, read the console, take screenshots, simulate keyboard/mouse/character movement | Keep Studio open, approve tool calls, play and give feedback |
| **B. Cloud + Rojo + GitHub** (this cloud session) | No Studio access | Write all code and data files (Rojo project), generate maps procedurally in code, run static checks (StyLua, Selene, luau-lsp), push, open PRs, watch CI | Pull the repo, `rojo serve` (or copy scripts), press Test, report results/errors |
| **C. CI publishing** (add-on to B) | User created an Open Cloud API key and stored it as a GitHub secret | GitHub Action builds the place with `rojo build` and publishes it to a **test place** via the Place Publishing API. Luau Execution API can run tests in the real engine | Create the API key + test place once; never paste keys in chat |

Detect mode A by looking for Studio MCP tools (names like `search_game_tree`, `execute_luau`, `start_stop_play`, `screen_capture`; load via ToolSearch with query "roblox studio"). If absent, use mode B and tell the user once how to enable A (see §6).

Network note: this cloud environment's proxy blocks `*.roblox.com`. Open Cloud calls must run in GitHub Actions (or the user allows `apis.roblox.com` in the environment's network settings).

## 2. Project lifecycle (always follow)

1. **Plan** → fill `docs/SPIELPLAN-VORLAGE.md` together with the user (one copy per game: `games/<name>/SPIELPLAN.md`). Ask only what's missing; propose defaults for the rest. Get an explicit "go".
2. **Milestones** → split into milestones that are each playable:
   - **M1** core loop (graybox)
   - **M2** progression + saving
   - **M3** UI + onboarding
   - **M4** content + art pass
   - **M5** monetization
   - **M6** polish, performance, mobile
   - **M7** launch prep

   Each milestone has a short acceptance list ("Definition of Done").
3. **Build** a milestone end to end. Reuse `references/patterns.md`. Keep the Rojo layout from `templates/rojo-starter`.
4. **Verify** (§4) before reporting done. Never claim it works without evidence.
5. **Report** in German: what was built, how to try it (exact clicks), what was verified and how, and what's open. Then ask for feedback or the go for the next milestone.
6. **Retro:** add every correction made during the milestone to `references/lessons-learned.md` as a general rule.
7. **Commit** per milestone on a feature branch; PR with checklist.

## 3. Building in mode A (Studio MCP)

- Start with `list_roblox_studios`, then `search_game_tree` to understand the place. Never overwrite existing user work without asking; build new things in clearly named Folders.
- **Scripts:** `multi_edit` with dot paths (`game.ServerScriptService.Server`). Keep the same module structure as the Rojo template, so mode A and B stay interchangeable.
- **Geometry:**
  - Prefer **code-driven building** via `execute_luau` in the Edit datamodel. It is deterministic and repeatable, for example the CourseBuilder pattern.
  - Use `generate_procedural_model` / `generate_mesh` for props.
  - Use `search_asset` + `insert_asset` only for trusted creators, and scan inserted models for scripts (backdoor rule, studio-basics §12).
- Anchor everything static, name things meaningfully, tag interactive parts (`KillBrick`, `Checkpoint`, …).
- Ask before large irreversible edits (deleting user content, replacing the map).

## 4. Verification checklist (mode A — do it, don't assume)

1. `get_console_output` after load: no red errors.
2. `start_stop_play`, then `get_studio_state` to confirm play mode.
3. Drive the core loop:
   - move with `character_navigation`, inputs with `user_keyboard_input` / `user_mouse_input`
   - check state with `execute_luau` in the Server datamodel (e.g. read leaderstats, data tables)
4. `screen_capture` key moments (spawn, UI, first obstacle) and look at them: UI readable? Overlapping the top bar? Mobile layout?
5. Edge cases: death/respawn, rejoin (data), spamming remotes (server rejects), two players where relevant.
6. Stop play; console clean again.

Mode B verification: run `scripts/check-luau.sh` (StyLua, Selene, luau-lsp type check against Roblox definitions). Write pure-logic modules so they can be unit-tested with Lune. State clearly which behavior still needs a Studio playtest.

## 5. Decisions the user owns (always ask, never assume)

- Game idea, genre, target audience, art style, game name.
- Anything that costs money or Robux (ads, paid assets, prices of passes/products).
- Publishing publicly, audience setting, content maturity answers.
- Deleting or replacing their existing work.

Everything else (code architecture, file layout, numbers balancing within the plan, technical fixes): decide yourself with sensible defaults and mention it in the report.

## 6. Enabling mode A (instructions to give the user, German)

1. Install **Claude Code** locally (or Claude Desktop). Requires a Claude plan (Pro or higher; see claude.com/pricing).
2. Clone this GitHub repo locally and start Claude Code inside it, so it loads this skill and CLAUDE.md.
3. Update Roblox Studio. Open the place → **Assistant** → **…** → **Manage MCP Servers** → turn on **Enable Studio as MCP server** → **Quick connect** → enable **Claude Code**. Manual fallback:
   - Windows (in the classic Command Prompt `cmd`, not PowerShell): `claude mcp add Roblox_Studio -- cmd.exe /c %LOCALAPPDATA%\Roblox\mcp.bat`
   - macOS: `claude mcp add Roblox_Studio -- /Applications/RobloxStudio.app/Contents/MacOS/StudioMCP`
4. Restart Studio and Claude Code; the green indicator in Manage MCP Servers shows the connection.
5. Security: only connect trusted clients; the MCP server can modify open places.

## 7. Enabling mode C (CI publish to a test place)

1. In Studio, publish a **separate test game** (never the live game).
2. Creator Dashboard → Open Cloud → API Keys → create a key:
   - Access permission **universe-places** → **Write** for the test game.
   - Optional for automated tests: **luau-execution-sessions** write.
   - Restrict to GitHub's IPs only if practical. Set an expiry.
3. GitHub repo → Settings → Secrets and variables → Actions: `ROBLOX_API_KEY` (secret), `ROBLOX_UNIVERSE_ID`, `ROBLOX_PLACE_ID` (variables).
4. Workflow: `rojo build -o place.rbxl` → `POST https://apis.roblox.com/universes/v1/{universeId}/places/{placeId}/versions?versionType=Published` with header `x-api-key` and `Content-Type: application/octet-stream`.
5. Luau Execution API limits are tight (reports of ~30 task creations per hour per account): batch all tests into one task.
