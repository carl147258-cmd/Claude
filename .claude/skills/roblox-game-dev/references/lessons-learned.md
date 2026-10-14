# Lessons Learned

Mistakes found during real work, turned into rules. **Read the sections matching the task before starting**; **append a new entry every time something had to be corrected** (format below). Prefer a general rule over a one-off note; merge duplicates.

Entry format:
```
- **<Rule in one line>** — <what went wrong, how it was found> (<YYYY-MM-DD>)
```

---

## Process & verification

- **Look at every generated image/render before showing it; iterate until a self-review finds nothing.** First drafts always had visible defects: muddy gradients, cut-off subjects, clipped glow, mirrored text. (2026-10-13)
- **Render 3D models from at least three views (front ¾, side, rear ¾) per iteration.** Single-view checks missed a broken rear window and floating door seams. (2026-10-13)
- **Attribute visual artifacts with a per-pixel part-ID buffer instead of guessing.** It took one query to learn that "antennas" were misplaced door seams and a "grey triangle" was the hood itself. (2026-10-13)
- **Ask about brands, logos and personal data (licence plates, faces) before working with real-world photos/objects.** Remove logos and real plates by default; mention design-trademark risk (e.g. a recognisable grille) for public games. (2026-10-13)
- **Decide the fidelity strategy first:** primitive parts give a blocky "Roblox" look; "as close to the original as possible" needs meshes (Blender → 3D Importer). Switching late wastes iterations. (2026-10-13)
- **State what could not be verified** (no Studio access, can't hear audio) and give the user a concrete check. (2026-10-13)

- **Never call a result "faithful/originalgetreu" unless a side-by-side with the reference supports it.** The user judged the procedural HD coupe "not at all faithful" although I had presented it as such. Describe it honestly ("inspired by", "proportions match") and let the user judge. (2026-10-13)
- **Real-world replicas (cars, buildings) need proper references before modelling:** 3–4 photos of the whole object (front ¾, side, rear ¾, front; doors closed, nothing cut off) or blueprints. A single cropped photo with an open door cannot produce a faithful model — ask for references first. (2026-10-13)

## Environment & tooling

- **`*.roblox.com` is blocked in the cloud sandbox; GitHub (raw, releases, git) works.** Read docs from `github.com/Roblox/creator-docs` (sparse clone of `content/en-us/...`); run Selene (needs the Roblox API dump) only in CI. (2026-10-13)
- **The sandbox proxy blocks uploads to Higgsfield (`upload.higgsfield.ai`).** Have the user upload images via `media_upload_widget`, or ask them to allow the host in the environment's network settings. (2026-10-13)
- **Photo → 3D options (Oct 2026):** Tripo H3.1 multiview (2–4 views, detailed, textured) ≈ 18 Higgsfield credits; Meshy 7 single image textured+PBR ≈ 38 credits; Roblox Studio Assistant `/generate_mesh` with a reference image is free (rate-limited, ~10k triangles). Always preflight with `get_cost:true`. Strip logos and real plates from the input image first. (2026-10-13)
- **Windows PowerShell 5.1 scripts:** use `Invoke-WebRequest -UseBasicParsing`; quote `'--'` when passing it to native programs; call `claude` via `Get-Command -CommandType Application` (an npm `claude.ps1` can be blocked by the execution policy); set `$ErrorActionPreference = "Continue"` around native tools that write to stderr (git). Test with a PowerShell parser (`pwsh` tarball from GitHub releases) and a mocked `HOME`/`LOCALAPPDATA` run. (2026-10-13)
- **Claude Code's native Windows installer puts `claude.exe` in `%USERPROFILE%\.local\bin` and may not add it to PATH.** Scripts must fall back to that path and add it to the user PATH; tell the user to open a new terminal afterwards. Also: run setup only after Claude Code is installed, or re-run it. (2026-10-13)
- **"Ich bin in Roblox" can mean the Roblox Player (games app), not Roblox Studio.** The user had only the Player open; `%LOCALAPPDATA%\Roblox\mcp.bat` was missing. Ask explicitly for **Roblox Studio** (download via create.roblox.com) and check for `RobloxStudioBeta.exe` under `%LOCALAPPDATA%\Roblox\Versions`. (2026-10-13)
- **The user's Studio is German; give German labels too.** Assistant = icon top right (no text label); settings window "Assistenteneinstellungen" → **MCP-Server** → toggle **„Studio als MCP-Server aktivieren“** (status „Keine Clients verbunden“ until Claude reconnects; then `/mcp` → Roblox_Studio → Reconnect). `mcp.bat` exists even while the toggle is off, so it does not prove MCP is enabled. No API key is needed for Claude Code. (2026-10-13)
- **Symptom of the toggle being off: Studio MCP is "connected" with zero tools.** `StudioMCP.exe` runs and the `Roblox_Studio` server sends instructions, but `list_roblox_studios`/`screen_capture` are missing (ToolSearch finds nothing). Fix as in the entry above (toggle on + Reconnect); confirmed working afterwards. (2026-10-13)
- **The user's PC has no global git identity, and pushing needs an interactive GitHub login.** Commit with `git -c user.name=Claude -c user.email=noreply@anthropic.com commit` (matches the repo history, no config change); for the first push, ask the user to run `! git push` so Git Credential Manager can open its sign-in window; afterwards the login is stored and Claude can push itself (confirmed). (2026-10-13)
- **`scripts/check-luau.sh` must run on Windows too (Git Bash):** it originally fetched only Linux binaries ("Exec format error"), and Git's `autocrlf` checked `.luau` files out as CRLF, so StyLua flagged every file. Fixed with per-platform binaries in `.tools/<os>/` and `.gitattributes` (`*.luau eol=lf`). (2026-10-13)
- **`set -e` does not apply inside `( … ) || status=1`.** StyLua/Selene failures in the check script were silently ignored (exit 0, also in CI); every tool call there needs an explicit `|| exit 1`. Verify a checker by feeding it a known failure. (2026-10-13)
- **Copy repo scripts into Studio with `execute_luau` + `[==[ … ]==]` long strings, then compare `#Source` with the repo file's byte count minus CRs.** All 8 obby scripts matched byte for byte; this catches transcription slips without reading everything back. (2026-10-13)
- **Better for larger projects: `rojo build` a bundle `.rbxm` (Folder with Shared/Server/Client), copy it into `%LOCALAPPDATA%\Roblox\Versions\<studio-version>\content\` and load it in the Edit datamodel with `game:GetObjects("rbxasset://<name>.rbxm")[1]`, then move the children into their services.** Byte-exact, no tokens spent on pasting, not cached between reloads. `InsertService:LoadLocalAsset` is refused ("lacking capability RobloxScript"). Studio must be stopped (Edit mode) before swapping scripts. (2026-10-13)
- **Verify short-lived VFX (≤ 0.2 s) with a test copy:** in the Client datamodel clone the ModuleScript, change the fade constant in `.Source` (e.g. 0.16 → 3 s), `require` the clone and step its `Update` manually, then `screen_capture`. A capture right after a real swipe usually misses the effect or catches a random frame. (2026-10-13)
- **`user_mouse_input` moves along a path from the previous cursor position; points near the top-left hit CoreGui and log errors.** Start swipes away from the top bar and corners; check with a temporary `UserInputService` logger that the game really receives the input. (2026-10-13)
- **`screen_capture` with a far-away `camera_position` (≈300 studs) hung > 120 s; ~200 studs worked.** Keep the camera within ~200 studs of the target. (2026-10-13)
- **Windows PowerShell 5.1 breaks commit messages that contain double quotes** (they turn into pathspecs). Write the message to a file in the scratchpad and use `git commit -F <file>` from Bash. (2026-10-13)
- **Playtesting jump courses via MCP: drive the real character from the Client datamodel** (`Humanoid:MoveTo` + `Humanoid.Jump` when a ray 1 stud ahead finds no ground), not by teleporting. First walk to the launch point of the current part closest to the target, then run and jump; jumping as soon as the edge is near failed on 2-stud beams. Measure gaps against reach first: default reach ≈ 8.7 studs (JumpHeight 7.2, WalkSpeed 16). (2026-10-13)
- **Pin tool versions identically locally and in CI** (`scripts/check-luau.sh`); a StyLua version change can reformat code. (2026-10-13)
- **Studio UI labels changed (2025/26):** **Test** (F5) not "Play", **Server & Clients** (F7), **File → Experience Settings**, transform tools on keys **2/3/4**, Device **Simulator**. Verify labels against creator-docs before writing click-paths. (2026-10-13)

## Gameplay feel

- **Spawns and checkpoints must face the course: a character placed with `PivotTo(part.CFrame)` (and a SpawnLocation) looks along the part's LookVector (−Z).** In the obby players spawned facing away from the course. Build spawn/checkpoint CFrames with `CFrame.lookAt(pos, pos + courseDirection)` and verify the facing in the first playtest screenshot. (2026-10-13)

## Rojo / model files

- **Rojo `.model.json` needs explicit types for CFrame and UDim2:** `{"CFrame": {"CFrame": {"position": [...], "orientation": [[R00,R01,R02],[R10,...],[R20,...]]}}}` (rows), `{"UDim2": [[1,0],[1,0]]}`. Enums/Vector3/Color3/bool work implicitly. Verify by `rojo build -o x.rbxmx` and checking R02 etc. (2026-10-13)
- **In built XML, BasePart size/shape appear as lowercase `size`/`shape`; shape token 2 = Cylinder** — grep accordingly when verifying. (2026-10-13)

## 3D geometry with Roblox primitives

- **WedgePart: slope rises from −Z (low) to +Z (high); the slope plane passes through the part's centre.** Any outward-normal test must use the vertex centroid, not the part position. Keep a single flag to flip wedges if Studio disagrees. (2026-10-13)
- **Cylinder axis is X; rotate with `ry=90` for an axis along Z (exhausts).** (2026-10-13)
- **Mirroring a part to the other side: `R' = M·R·M` with `M = diag(-1,1,1)`** keeps a proper rotation. (2026-10-13)
- **Text on a part's Front face (−Z) reads mirrored unless local +X maps to the viewer's left.** (2026-10-13)
- **Cars from boxes look like 1970s sedans unless:** low sloping nose, narrower greenhouse with tumblehome (shoulder slopes inward), A/C pillars as strips along the glass edges, wheel arches hugging the tyres (gap ≲ 10 % of tyre diameter), corner wedges in the arch openings. (2026-10-13)
- **Mount details on the actual surface at that height** (body width changes above the beltline; door seams start at the A-pillar, not behind the front wheel). Floating/protruding details were the most common defect. (2026-10-13)
- **Glossy black paint: Roblox `Reflectance` ≈ 0.15**; higher makes black look grey. (2026-10-13)

## High-fidelity models (Blender `bpy` → GLB → Studio 3D Importer)

- **For "as close to the original as possible", build in Blender via `bpy` (pip wheel `bpy` matches the Python version; Cycles CPU renders headless).** `import bpy` must come before `import bmesh`/`mathutils`. (2026-10-13)
- **Model car bodies as lofted cross-sections + Subdivision (level 2), cut wheel arches with EXACT booleans; keep arch radius ≤ tyre radius + ~0.2 so the cut doesn't reach the shoulder line** (a 1.42 radius notched the hood edge). (2026-10-13)
- **Get proportions from real data and check the cowl position:** the windshield base was 0.95 studs too far back, which made the car read as a long GT. Compare a render from the reference photo's angle side by side with the photo every iteration. (2026-10-13)
- **Put details on the body with ray-cast "patches" whose outlines are triangulated exactly** (densify outline → triangulate → refine → ray-cast vertices). Grid-cell inclusion gives stair-stepped edges. (2026-10-13)
- **Windows: project separate glass + frame patches onto the cabin instead of assigning materials per face** (per-face assignment gives jagged window edges). (2026-10-13)
- **Ray-cast normals on open surfaces may point inward: flip the hit normal to face the ray before offsetting; reject grazing hits (`n·d > -0.3`)** — otherwise patches end up inside the body or on the roof. (2026-10-13)
- **Black car materials: glass must differ from paint (slightly lighter, metallic ~0.6, roughness ~0) or windows vanish.** Frames in matte black, kidney frames gloss black like the original. (2026-10-13)
- **Roblox mesh budget: ≤ 20k triangles per MeshPart.** Join by material (and per wheel), split big groups (body vs cabin), keep patch resolution coarse (0.08–0.14 studs; plates 0.12); decimate only as a last resort. Check the GLB: front at −Z, size in studs, bottom at y = 0. (2026-10-13)
- **The importer's colour handling is uncertain → ship a Command-Bar script that sets Color/Material/Reflectance by MeshPart name** (`ApplyCarLook.luau`). (2026-10-13)
- **Review renders on a neutral grey contact sheet** (transparent backgrounds show as black in previews and hide dark parts). (2026-10-13)

## Images & compositing

- **Background removal: crop to the subject first, then use BiRefNet (rembg `birefnet-general`)**; ISNet on the full photo kept poles, bikes and signs. (2026-10-13)
- **Remove badges with OpenCV inpainting (Telea)**, not flat colour fills (median fill left a visible grey blob). (2026-10-13)
- **Glow/blur layers need a margin larger than the blur radius**, otherwise glows get clipped into hard edges. (2026-10-13)
- **Car shots: 30–35° FOV from a ¾ front view like the reference photo; keep the whole front in frame.** Wide-angle close-ups made the car look stretched. (2026-10-13)
- **Putting a daylight photo into a night/neon scene: darken base colour and recolour highlights by luminance into the scene's neon palette.** Untouched tree reflections broke the illusion. (2026-10-13)
- **Every object composited onto a background needs a contact shadow**, otherwise it looks like it floats (HD car icon). (2026-10-13)
- **Long renders (minutes): run them in the background, commit work in between, and review on a contact sheet next to the reference.** (2026-10-13)
- **Avoid compositing blurred colour glows over gradients in RGB** — produced muddy brown bands; draw explicit gradient bands instead. (2026-10-13)

## Luau / Roblox API

- **`DataStoreService:GetDataStore()` itself throws in unpublished places ("You must publish this place to the web to access DataStore") — wrap it in `pcall` at module load, not only `GetAsync`/`UpdateAsync`.** The obby's PlayerData module crashed on require, so the whole server script never ran, although the README promised it would play without saving. Found by the first real Studio playtest. (2026-10-13)

- **Client code that grabs character joints/parts must retry until they exist; never bind once on the first frame.** The third-person sword arm never moved: on the first RenderStep the R15 rig was still loading, `RightShoulder` was missing, and the code never looked again (no error, arm just hung down). Re-bind while the joint is nil or no longer a descendant of the character. (2026-10-14)
- **Multi-part tools that get welded to a character: join their parts with `Weld` (fixed C0), never `WeldConstraint`, and scale while building instead of `Model:ScaleTo`.** A WeldConstraint re-captures its offset when a part is moved, so attaching the handle to the hand left the whole blade at the build position (sword "invisible", extents 104 studs). Found by measuring `GetExtentsSize()` after the weld. (2026-10-14)
- **Procedural poses on avatars: set `Transform` of the joint in `RunService.PreSimulation`; support both `Motor6D` and `AnimationConstraint` rigs.** New avatars use AnimationConstraints; changing C0 or the rig attachments had no effect, and the idle animation bent the elbow so the blade pointed into the screen. Straighten elbow/wrist the same way. (2026-10-14)
- **A blade viewed from behind the avatar reads only if it is big (≈1.25×) and its flat side is rolled towards the camera** (client adjusts the grip Weld's C0 each frame). (2026-10-14)
- **`user_mouse_input` x/y are GUI coordinates (`AbsolutePosition`, top bar excluded), not screenshot pixels.** Clicks computed from the screenshot missed; read the button's `AbsolutePosition + AbsoluteSize/2` in the Client datamodel first. `instance_path` fails when siblings share a name (several "Frame"s) — give buttons unique names. (2026-10-14)
- **A studio-only test hook saves hours when testing shops:** the server listens for a player attribute (`StudioGrantCoins`) only when `RunService:IsStudio()`; set it from the Server datamodel. Clients cannot set server attributes, live servers ignore it. (2026-10-14)
- **Emoji (e.g. 🪙) do not render in `FredokaOne` labels; draw icons from Frames (UICorner circle + UIStroke) instead.** The coin counter showed only the number. (2026-10-14)
- **Execute_luau in the Client datamodel cannot set Motor6D.C0 ("read only") and `get_console_output` showed no client errors; read client errors with `LogService:GetLogHistory()` in the Client datamodel.** (2026-10-14)

## Look & feel (VFX, lighting, first person)

- **Far neon set pieces (moon, sun) vanish in Atmosphere haze beyond ~600 studs at Density 0.35.** The blood moon at 1100 studs was on screen but invisible; keep hero props closer than the fog distance and verify with `WorldToViewportPoint` plus a screenshot. (2026-10-14)
- **Biggest cheap visual upgrades for part-built scenes: client-local Terrain (water with waves, sand/grass hills via `FillBlock`/`FillBall`/`FillCylinder`, cleared with `Terrain:Clear()` on scene change), the `Clouds` object, `SunRaysEffect`, a mild `DepthOfFieldEffect` focused on the play field, and `Highlight` outlines on gameplay objects.** Flat parts as water/clouds looked like a toy; terrain water + real clouds changed the beach completely. (2026-10-14)
- **Bright materials (light wood, sand) under strong sun + Bloom glow white; keep deck colours mid-tone (≈ RGB 170/130/90) in day scenes.** (2026-10-14)
- **A wide, light `Trail` on a flying object washes over the object itself (it looked translucent); keep trails narrow (≈0.2 r each side) and in the object's own colour.** (2026-10-14)
- **`Lighting.Technology` cannot be read or set from the MCP/Assistant context (lacks RobloxScript capability); set it in Rojo (`Lighting.$properties.Technology`) and tell the user to set it once in Studio's Properties.** (2026-10-14)
- **Third-person camera behind the avatar: add a local fill light between camera and avatar.** Night scenes lit only the avatar's front, so the player saw a black silhouette. (2026-10-14)

- **A Roblox `Trail` on a fast first-person viewmodel turns into big flat quads** (the blade jumps 20–30° per frame). Draw the swoosh yourself: for every frame, sub-step the swing angle (≈3°) and spawn thin neon slabs along the outer blade that fade in ~0.15 s. (2026-10-13)
- **Sunset `ClockTime` (≈19) tints metal and light materials orange** — the silver hamon looked copper, and switching material/colour did not help. Check props under the scene's real lighting; night (`ClockTime` 21.5) with brighter `Ambient` fixed it. (2026-10-13)
- **First-person swings must cross the screen, not point into it:** a horizontal sweep around the body foreshortens the blade to a stub. A "wiper" motion (hand low at the bottom, blade rotating in a plane roughly parallel to the screen, rolled to the swipe direction, mirrored for leftward swipes) reads as a real slash. Review swing poses as ghost frames in one capture. (2026-10-13)
- **Far scenery (> streaming radius, e.g. a moon at 1100 studs) pops in late with `StreamingEnabled`.** Set `ModelStreamingMode = Persistent` on the scenery model. (2026-10-13)
- **Canned swing animations on click felt "steif" (user feedback); drive the first-person weapon directly from the pointer instead.** The blade tip sits on the cursor (solve `|t·d − hand| = bladeLength` on the cursor ray), the edge turns into the motion direction projected onto the screen plane (otherwise the thin edge faces the camera), and cuts are tested every frame along the pointer path while the button is held and the pointer is fast. (2026-10-13)
- **Fruit-Ninja-style targets must hang in reach:** fruits flying in from 70 studs were only briefly cuttable and felt unfair. Toss them up from below in front of the player so they peak at eye height (`vy = √(2gh)`, apex time `vy/g`); raise gravity over time for difficulty. A blind bot sweep went from 0–2 to 5–7 hits. (2026-10-13)
- **The default `ParticleEmitter` texture is a star sparkle — juice looked like glitter.** For droplets use `rbxasset://textures/particles/explosion01_core_main.dds` (ships with the client); compare candidate textures side by side in one capture. (2026-10-13)
- **Sound effects: take Creator Store audio from licensed libraries (ProSoundEffects, RBLXEssentials) and skip uploads ripped from other games (Silksong, Castle Crashers, Zelda).** Verify in a playtest that every `Sound` reaches `IsLoaded` with `TimeLength > 0`, randomise `PlaybackSpeed` per play, and tell the user that Claude cannot hear them. Client-shipped sounds live in `content/sounds` (e.g. `impact_explosion_03.mp3`, `impact_water.mp3`). (2026-10-13)
