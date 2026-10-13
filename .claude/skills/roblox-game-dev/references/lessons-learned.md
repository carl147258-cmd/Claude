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
- **Pin tool versions identically locally and in CI** (`scripts/check-luau.sh`); a StyLua version change can reformat code. (2026-10-13)
- **Studio UI labels changed (2025/26):** **Test** (F5) not "Play", **Server & Clients** (F7), **File → Experience Settings**, transform tools on keys **2/3/4**, Device **Simulator**. Verify labels against creator-docs before writing click-paths. (2026-10-13)

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
