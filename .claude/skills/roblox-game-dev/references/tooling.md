# Code-first Roblox Tooling

## Toolchain manager
Use **Rokit** (successor of Aftman/Foreman) to pin tool versions per project:

```bash
rokit init
rokit add rojo-rbx/rojo
rokit add UpliftGames/wally
rokit add Kampfkarren/selene
rokit add JohnnyMorganz/StyLua
rokit add lune-org/lune
```

This writes `rokit.toml`. Collaborators run `rokit install`.

## Rojo (file sync between disk and Studio)
- `rojo init` or copy `templates/rojo-starter/`.
- `rojo serve` + Rojo Studio plugin → live sync. `rojo build -o game.rbxlx` → place file.
- File naming:
  - `Name.server.luau` → `Script`, `Name.client.luau` → `LocalScript`, `Name.luau` → `ModuleScript`.
  - `init.server.luau` / `init.luau` inside a folder → the folder *becomes* that script and children are its children.
  - `*.model.json` / `*.meta.json` for instances and properties (e.g. RemoteEvents).
- `default.project.json` maps folders to services (see template).

## Wally (packages)
`wally.toml` → `wally install` → `Packages/` folder mapped into `ReplicatedStorage.Packages`.
Popular packages: `sleitnick/knit` (framework, now maintenance-only), `evaera/promise`, `sleitnick/signal`, `sleitnick/trove` (cleanup), `lukadev-0/...`, `1foreverhd/...`. Data: **ProfileStore** (loleris, distributed as a single ModuleScript). Networking: `red-blox/red`, `ffrostflame/bytenet`, `zap` (codegen). UI: `jsdotlua/react` + `react-roblox` or `fusion` (Elttob). State: `charm`, `reflex`. Verify the current package name/version on wally.run before adding.

## Linting & formatting
- `selene.toml`: `std = "roblox"`; run `selene src`.
- `stylua.toml`: e.g. `indent_type = "Tabs"`, `column_width = 120`; run `stylua src`.
- **luau-lsp** (VS Code extension "Luau Language Server") gives types + autocomplete; generate `sourcemap.json` via `rojo sourcemap --watch default.project.json -o sourcemap.json`.

## Running Luau outside Studio
- **Lune**: `lune run script.luau` — pure Luau runtime with filesystem/net/process; can read/write `.rbxl` files (`@lune/roblox`). Good for unit-testing pure logic modules (formulas, inventories, state machines) and build scripts.
- **Testing in Roblox**: Jest Lua (`jsdotlua/jest`) or TestEZ; run headless via `run-in-roblox` locally, or via **Open Cloud Luau Execution API** in CI.

## Open Cloud (HTTP APIs)
With an API key from create.roblox.com → Credentials:
- Publish places (`Place Publishing` API) from CI.
- Read/write DataStores (support tooling, GDPR deletion, migrations).
- MessagingService broadcast to live servers (announcements).
- Execute Luau in a place (tests).

## Git workflow
Ignore build outputs and packages:

```
/Packages
/ServerPackages
/DevPackages
*.rbxl
*.rbxlx
*.rbxl.lock
*.rbxlx.lock
sourcemap.json
```

Keep maps/models built in Studio as `.rbxm` files or in the place file; keep all **code** in Git.

## Roblox Studio + AI
Roblox Studio has a built-in Assistant and an MCP server integration, which lets external AI tools read and edit an open Studio session. When the user has it set up locally, prefer it for scene inspection; in this cloud environment, deliver files and step-by-step Studio instructions instead.

Note: the starter template has no `Packages` mapping. After the first `wally install`, add `"Packages": { "$path": "Packages" }` under `ReplicatedStorage` in `default.project.json`.
