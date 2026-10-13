# Art, Animation & Audio — what Claude can produce and how

Verified against Roblox creator-docs (Oct 2026). Pick the cheapest route that reaches the quality the plan asks for; show the user results early (screenshots, files) because taste is theirs to judge.

## 0. Honest capability map

| Area | Claude does it well | Needs user / external help |
|---|---|---|
| Level geometry, obstacles, buildings from parts | ✅ code-driven (CourseBuilder pattern), Studio MCP | — |
| Lighting, atmosphere, post-effects, materials | ✅ code / MCP | final look check by user |
| Particles, beams, trails, tweens, UI animation | ✅ code | — |
| Props & 3D models | ✅ via AI generators (Studio `generate_mesh` / `generate_procedural_model`, Higgsfield `generate_3d`) + Creator Store | high-end hero assets → artist/Blender |
| Character animations (walk, attack, emotes) | ✅ procedural/code; catalog IDs; keyframes via code (limited) | cinematic/hand-polished → Animation Editor or Animation Capture from a video the user records |
| UI icons, game icon, thumbnails | ✅ drawn in code (Pillow/SVG) or AI images (Higgsfield `generate_image`); best: in-game screenshots via MCP `screen_capture` | user picks favorites |
| Sound effects | ✅ synthesized in code (`scripts/make_sfx.py`), Creator Store | Claude **cannot hear**: verifies only technically (duration, peak, waveform); user must listen |
| Music | ✅ choose from Creator Store's licensed library (>100k tracks incl. professional partners) | Claude can't compose good music; no music model is available |
| Voice lines | ✅ in-engine `AudioTextToSpeech`; Higgsfield TTS (costs credits) | — |

## 1. Visual style first

Before building art, fix a **style sheet** in the game's SPIELPLAN:
- palette (5–7 colors)
- material set (e.g. SmoothPlastic + Neon only = clean cartoon)
- lighting mood
- UI font and corner radius
- 2–3 reference games/images from the user

Reuse it everywhere; consistency beats detail.

## 2. Lighting & atmosphere (biggest quality-per-effort win)

Set via code (server, at startup) or MCP `execute_luau` in Edit mode:
- `Lighting.Technology = Enum.Technology.Future` (best shadows/lights; check mobile perf) or `ShadowMap`.
- `Lighting.ClockTime`, `Brightness`, `Ambient`/`OutdoorAmbient`, `EnvironmentDiffuseScale`/`EnvironmentSpecularScale`.
- Children of Lighting:
  - `Atmosphere` (Density, Haze, Color, Decay)
  - `Sky`
  - `BloomEffect` (subtle: Intensity ~0.5, Threshold ~1.5)
  - `ColorCorrectionEffect` (Saturation +0.1–0.2 for cartoon)
  - `SunRaysEffect`
  - `DepthOfFieldEffect` (sparingly)
- Per-world themes: keep a table of lighting presets and tween between them when the player enters a zone (client-side).

## 3. Geometry & 3D assets

- **Parts from code:** deterministic, tweakable, cheap to render if anchored. Use Union/solid modeling sparingly (cost).
- **Terrain from code:**
  - `workspace.Terrain:FillBlock(cframe, size, Enum.Material.Grass)`
  - `FillBall`, `FillCylinder`, `FillWedge`
  - water via `Enum.Material.Water`
- **AI meshes in Studio** (mode A or Studio Assistant):
  - `generate_mesh` (text or image prompt): default 10,000 triangles, a Part can act as the bounding box.
  - `generate_procedural_model`: parametric, up to 50 per rolling 24 h.
  - `generate_material`: custom MaterialVariant.
  - Segmentation splits a model into ≤8 named parts.
- **Higgsfield `generate_3d`** (image → GLB; optional texturing, PBR, rigging and animation clips): import the GLB with Studio's **3D Importer** (File → Import 3D) or upload it as a Model via Open Cloud. Each mesh must stay **≤ 20,000 triangles**. It **costs credits**: run `get_cost:true` first and ask the user.
- **Blender via Python (`bpy`) in the sandbox:** for realistic models (cars, buildings, props) build parametric meshes with real dimensions, render previews with Cycles CPU, and export a GLB for the 3D Importer (Scale Unit: Studs). Reference implementation: `models/coupe-hd/build_car.py`; read the "High-fidelity models" lessons first.
- **Creator Store** (`search_asset`/`insert_asset` or Toolbox): prefer Roblox/verified creators; strip unknown scripts (backdoor rule).
- Performance:
  - Reuse the same MeshId (instancing).
  - `RenderFidelity = Automatic`, `CollisionFidelity = Box/Hull` for decorations, `CanCollide=false` + `CanTouch=false` + `CanQuery=false` on pure decoration.
  - Keep StreamingEnabled on.

## 4. Visual effects

- `ParticleEmitter` (confetti on checkpoint, lava embers): keep `Rate` low and use `:Emit(n)` for bursts.
- `Beam` (guide arrows, lasers), `Trail` (VIP trail = good Game Pass), `Highlight` (outline the next goal; max ~31 active).
- `TweenService` for spinning coins, bobbing pickups, UI pop-ins. Run purely visual tweens on the **client**.
- Camera shake/FOV punch: client `Camera.CFrame` offsets on `RenderStepped`, short and optional (accessibility).

## 5. Animation

Options, cheapest first:
1. **Procedural (no asset upload):**
   - TweenService on CFrame for objects.
   - `Motor6D.Transform` manipulation in `RunService.Stepped` for simple limb motion.
   - Spring/bob math for idle motion.
   - Works immediately in any place.
2. **Catalog animations** (Roblox-made, usable by everyone):
   - Swap default run/walk/jump/idle through the character's `Animate` script values (pattern in docs: `animateScript.run.RunAnim.AnimationId = "rbxassetid://656118852"` = Ninja Run).
   - Also emotes/animation bundles from the Marketplace.
3. **Keyframe animations:**
   - Build a `KeyframeSequence` (Keyframes → Poses per joint) via MCP `execute_luau`, or as `.rbxm` with Lune.
   - Publish it: the Animation Editor's **Export** (user clicks once; Avatar tab → Clip Editor), or Open Cloud asset upload (type Animation, `.rbxm/.rbxmx`). Roblox warns files edited outside Studio might not upload, so prefer Studio export.
   - Name the last keyframe `End` when replacing default animations.
4. **Animation Capture** (Avatar tab → Clip Editor):
   - Body: upload an .mp4/.mov of a person moving to generate R15 keyframes.
   - Face: webcam puppeteering.
   - The user records; Claude cleans up and integrates.
5. **Rigged AI models:** Higgsfield `generate_3d` with rigging + `animation_actions` clips for custom creatures/NPCs (credits).

Playback: `Animator:LoadAnimation(animation)` on the Humanoid's or AnimationController's `Animator`. Load once and cache tracks. Play player animations from the **client** (they replicate). Use `AnimationTrack:GetMarkerReachedSignal` for footsteps/hit frames.

Ownership: published animations must be owned by (or shared with) the experience owner (user or group) or Roblox. Publish them under the same account/group as the game, otherwise they won't play.

## 6. Audio

- **Music:**
  - Search the Creator Store (Toolbox → Creator Store → Audio, or MCP `search_asset` with type Audio) by mood/genre/duration.
  - Pick 2–3 options for the user to choose.
  - Loop per zone; crossfade with tweens on `Volume`.
- **Sound effects:**
  - `scripts/make_sfx.py` synthesizes royalty-free SFX (checkpoint, death, finish, click, whoosh). Extend its `SOUNDS` table for new ones.
  - Otherwise use the Creator Store.
  - Verify technically (ffprobe duration, no clipping) and ask the user to listen.
- **Voice/narration:**
  - In-engine: `AudioTextToSpeech`, part of the newer audio API with `AudioPlayer`, `AudioEmitter`, `AudioListener`, `AudioDeviceOutput` and `Wire`s.
  - Or Higgsfield TTS (credits).
- **Engine objects:**
  - Classic `Sound` is still fine for simple games.
  - 2D/UI sounds: `SoundService:PlayLocalSound(sound)` on the client.
  - 3D sounds: parent the Sound to a part and set `RollOffMaxDistance`.
  - Mixing: `SoundGroup`s (Music/SFX/UI) with a settings slider.
  - Effects: `AudioEqualizer`, `AudioReverb`, `AudioCompressor`.
- **Uploading** (Studio: Window → Asset Manager → Import; or Creator Dashboard; or Open Cloud):
  - .mp3/.ogg/.wav/.flac, ≤ 7 minutes.
  - Monthly limits: Studio/Dashboard 2,000 per 30 days ID-verified, 100 unverified. Open Cloud 100/month ID-verified, 10 unverified.
  - Uploads go through moderation and copyright checks.
  - Never upload music the user doesn't own.

## 7. Images (UI, decals, icon, thumbnails)

- Game icon **512×512**, thumbnails **1920×1080** (several; A/B-testable in the Creator Dashboard).
  - Strongest thumbnails show real gameplay. In mode A use MCP `screen_capture` with a staged camera, then add text/branding with Pillow.
  - Starter art: `scripts/make_obby_art.py`.
- UI images:
  - Draw with Pillow/SVG (crisp, free) or `generate_image` (credits).
  - Upload as Image/Decal (PNG/JPEG/BMP/TGA, < 8000×8000 px).
  - Use 9-slice (`ScaleType.Slice`) for scalable panels.
- Don't use other games' characters, brands, or Roblox's logo in a misleading way; thumbnails are moderated.
- Always **look at** generated images (Read the PNG) and self-critique composition, clipping, contrast and readability at small size before showing the user.

## 8. Cost control for generators

- Higgsfield runs on the user's credits (check `balance`; free plan = few credits). Always preflight with `get_cost:true`, state the cost, and get a yes before generating. Batch variants in one request.
- Studio AI generation (`generate_mesh`, procedural models) is free but rate-limited.
- Code-generated art and audio cost nothing; prefer it for placeholders and simple styles.
