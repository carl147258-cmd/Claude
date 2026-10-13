# Roblox Studio Basics — click paths, shortcuts, beginner teaching

Verified against Roblox's official creator-docs repo (github.com/Roblox/creator-docs, Oct 2026). Studio's UI is in **English**; always give the user the exact English labels (optionally with a German explanation). Studio changes often — if the user says a button is elsewhere, trust them and adapt.

## Table of contents
1. Screen layout (current "flexible" UI)
2. Windows you always need
3. Camera controls
4. Selecting & transforming parts
5. Part properties every beginner must know
6. Explorer: hierarchy, insertion, search
7. Properties: tags & attributes
8. Scripts: types, where they go, the Script Editor
9. Testing (playtest modes)
10. Saving & publishing
11. Settings beginners need
12. Toolbox safety
13. Common beginner mistakes → fixes
14. How to teach a beginner (lesson plan)

---

## 1. Screen layout

- **Top: toolbar + "mezzanine".**
  - **Left side of the mezzanine: testing controls.** A dropdown (Test / Test Here / Run / Server & Clients / Team Test) and the play button.
  - **Center: tool tabs** **Home**, **Model**, **Avatar**, **UI**, **Script**, **Plugins**. Custom tabs can be added with **+**.
  - **Right side:** collaboration, share, **Assistant** (built-in AI), notifications, account.
  - Right-click the empty toolbar for **Manage tabs**, **Compact toolbar** (good on laptops) and **Show labels**.
- **Center: 3D viewport** = the Workspace. Top-right of the viewport has **Visualization options**, e.g. "Anchored parts" outlines and the camera speed.
- **Menus:** **File** (Publish to Roblox, **Experience Settings**, Beta Features, Advanced → Customize Shortcuts), **Edit**, **Window** (open any window: Explorer, Properties, Output, Toolbox, Asset Manager, Command Bar…).
- **Docking:** drag a window by its header bar onto the position selector. Drop it on the center icon to make it a tab.

What the tabs hold:

| Tab | Contents |
|---|---|
| **Home** | Move/Scale/Rotate, **Part** inserter, Color, Material, **Group**, **Lock**, **Anchor**, Terrain Editor; also buttons for Explorer/Properties/Toolbox/Asset Manager |
| **Model** | Transform tools, Pivot & Align tools, effects/constraints inserters, solid modeling (Union/Negate/Intersect) |
| **Avatar** | Rigs, avatar setup, animation editor, accessory fitting |
| **UI** | Insert UI objects, Style Editor |
| **Script** | Script tools, debugger, **Output**, **Command Bar** |
| **Plugins** | Installed plugins |

## 2. Windows you always need

Open them via the **Window** menu (or buttons in the **Home** tab):
- **Explorer**: tree of everything in the place (the "data model").
- **Properties**: settings of the selected object, plus **Tags** and **Attributes** at the bottom.
- **Output**: errors (red), warnings (orange), `print` output. It is also on the **Script** tab. In a playtest, message labels are **blue = client**, **green = server**.
- **Toolbox**: free models, images, audio, plugins (see §12 safety).
- **Command Bar**: run one-off Luau in edit mode. Shortcut **Ctrl+9**.

## 3. Camera controls (viewport)

| Input | Action |
|---|---|
| **Right mouse button + drag** | Look around |
| **W A S D** | Fly forward/left/back/right |
| **Q / E** | Down / up |
| **Shift** + move key | Change speed |
| **Mouse wheel** | Zoom |
| **Middle mouse + drag** | Pan |
| **F** | Focus the selected object (most useful key when lost!) |
| **, / .** | Rotate camera (around the focused object) |

## 4. Selecting & transforming parts

- Click selects. **Shift/Ctrl+click** multi-selects. **Alt+click** selects the object *behind* (selection cycling).
- Tools: **Select 1**, **Move 2**, **Scale 3**, **Rotate 4**. These are the current defaults without Ctrl; older Studio used Ctrl+1–4, and shortcuts are customizable under **File → Advanced → Customize Shortcuts**.
- **Snapping:** move/scale increments are in **studs**, rotate in **degrees**, set in the toolbar. Hold **Shift** while dragging to toggle snapping temporarily.
- **Ctrl+L** switches between world and local axes.
- Drag a part directly with the mouse. While dragging, **R** rotates it 90° around the surface normal and **T** tilts it 90°.
- **Ctrl+R / Ctrl+T** rotate the selection 90° around Y / X.
- **Ctrl+D** duplicate (same parent). **Ctrl+C / Ctrl+V** copy/paste. **Ctrl+Shift+V** paste *into* the selected object. **Delete** removes. **Ctrl+Z / Ctrl+Y** undo/redo.
- **Ctrl+G** group into a Model. **Alt+Ctrl+G** group as Folder. **Ctrl+U** ungroup.
- **Alt+A** toggle **Anchor**. **Alt+L** toggle **Lock** (locked parts can't be clicked in the viewport; Edit → Unlock All).
- Part shapes: Home/Model → **Part** button → small arrow → Block, Sphere, Wedge, Corner Wedge, Cylinder. TrussPart (climbable ladder) only via Explorer insert.

## 5. Part properties every beginner must know

| Property | Meaning | Typical beginner value |
|---|---|---|
| **Anchored** | Physics can't move it (gravity, pushes) | **true** for almost every building part; otherwise things fall/scatter when the game starts |
| **CanCollide** | Solid or walk-through | true for floors/walls; false for decorations, trigger zones |
| **CanTouch** | Fires `.Touched` events | must be true for kill bricks/checkpoints |
| **Transparency** | 0 visible … 1 invisible | invisible trigger zones: 1 + CanCollide false |
| **Size / Position / Orientation** | Studs and degrees | type exact numbers for precise jumps |
| **Color / Material** | Look | Neon glows, SmoothPlastic is clean |
| **Name** | Used by scripts | Scripts find objects by exact name, and names are case-sensitive |

Units: 1 stud ≈ 28 cm. A default character is ~5 studs tall, walks 16 studs/s, and jumps ~7 studs high. Comfortable gaps for jumps are ≤ 10 studs.

## 6. Explorer

- **Insert:** hover the parent → click **⊕**, or **Ctrl+I**, then type the class name (Script, LocalScript, ModuleScript, Folder, RemoteEvent, ScreenGui…).
- **Reparent:** drag and drop onto the new parent. Arrow keys → / ← expand and collapse. **Shift+click** the arrow expands everything.
- **Search** (**Ctrl+Shift+X**):
  - plain name
  - `tag:KillBrick` (by tag)
  - property filters like `Anchored = false` (find accidentally unanchored parts!)
  - ancestry `Course.**` (all descendants)
- Key services:
  - **Workspace**: the 3D world.
  - **ServerScriptService**: server Scripts.
  - **ServerStorage**: server-only assets.
  - **ReplicatedStorage**: shared modules, RemoteEvents.
  - **StarterPlayer → StarterPlayerScripts / StarterCharacterScripts**: LocalScripts.
  - **StarterGui**: UI.
  - **StarterPack**: tools given to every player.
  - **Lighting**: sky, time of day, atmosphere.
  - **Players**: filled at runtime.
  - **Teams**: team setup.

## 7. Properties: tags & attributes

- **Tags** (bottom of Properties → **+**): string labels used by `CollectionService`. Ideal for "this part is a KillBrick" without copying scripts.
- **Attributes** (bottom of Properties → **+** → Name, Type → Save): custom values like `Damage = 25`, readable with `:GetAttribute("Damage")`. They let non-coders tune values.

## 8. Scripts

| Type | Runs | Put it in |
|---|---|---|
| **Script** (RunContext Legacy) | Server | ServerScriptService (or inside a Workspace part for simple behaviors) |
| **LocalScript** | Client | StarterPlayerScripts, StarterCharacterScripts, StarterGui, StarterPack tools |
| **ModuleScript** | Wherever it's `require`d | ReplicatedStorage (shared) or ServerScriptService/ServerStorage (server-only) |

- A LocalScript in ServerScriptService or Workspace **does nothing**. A Script in StarterGui runs on the server, which is usually wrong. Wrong placement is the #1 beginner bug.
- **Script Editor:** double-click a script to open it.
  - autocomplete; red/orange underlines = errors/warnings (hover to read)
  - **Ctrl+F** find, **Ctrl+Shift+F** find in all scripts
  - **F9** breakpoint (Script tab → debugger)
- Debug habit: add `print("reached X", value)` and read the **Output**. In-game Developer Console: **F9** while playing (also on live servers).

## 9. Testing (left side of the mezzanine)

| Mode | Shortcut | What it does |
|---|---|---|
| **Test** | **F5** | Play with your avatar at a SpawnLocation |
| **Test Here** | – | Spawn in front of the camera (great for testing stage 37 directly) |
| **Run** | **F8** | Simulate without an avatar (watch NPCs/physics) |
| **Server & Clients** | **F7** | Opens separate windows: 1 server + N clients (1–8). Required for multiplayer bugs and data saving |
| **Team Test** | – | Test together with collaborators |
| **Stop** | **Shift+F5** | Ends the test. **Everything changed during a test is reverted**: build in edit mode, not while testing |

- During a solo test, the **Client/Server** toggle switches views:
  - **blue border = client** (what the player sees, with your controls)
  - **green border = server** (free camera, inspect server objects; the Explorer shows server-only things)
- **Device Simulator:** toolbar above the viewport (currently beta: File → Beta Features → "New Device Simulator"). Pick Phone → Flagship / Mid-range / Entry level to check UI and touch.
- **Network Simulator** adds lag and packet loss to playtests.

## 10. Saving & publishing

- **File → Save to File** (`.rbxl`, local backup) vs **File → Publish to Roblox** (cloud; links the place to your account/group).
- New games are **private** by default. Making one public needs the 2026 publishing requirements (see game-design.md).
- Saving to Roblox regularly also keeps **version history** (restore old versions from the Creator Dashboard).
- **DataStores in Studio:** **File → Experience Settings → Security → "Enable Studio Access to API Services"** → Save. The place must be published. **Don't enable it on a live game**: Studio then writes the real player data. Use a separate test copy.
- Monetization (Game Passes, Developer Products), audience, thumbnails: Creator Dashboard (create.roblox.com) → your experience.

## 11. Settings beginners need

- **File → Experience Settings**: Basic Info, Permissions, Monetization, **Security** (API services, HTTP requests), Places, Avatar (e.g. R15/R6), World (e.g. gravity, jump, walk speed). Exact tab names can shift between Studio versions.
- **File → Beta Features**: opt-in features (e.g. new Device Simulator).
- **File → Advanced → Customize Shortcuts**: rebind keys.
- Studio has auto-recovery for crashes, but don't rely on it: publish or **Save to File** often.

## 12. Toolbox safety (backdoors)

Free models can contain hidden scripts that give strangers admin rights or insert inappropriate content. Rules:
1. Prefer assets by Roblox or verified creators. Check ratings and comments.
2. After inserting a model, search the Explorer for scripts inside it (`Model.**` plus class filters, or look for Script/LocalScript/ModuleScript icons). Also check for `require(` with a number inside any script.
3. Delete every script you don't understand. Meshes, parts and decals are safe.
4. Never install plugins from unknown creators. Plugins can modify everything.

## 13. Common beginner mistakes → fixes

| Symptom | Cause | Fix |
|---|---|---|
| Building falls apart / parts fly away on Test | Parts not **Anchored** | Select all → Alt+A. Explorer search `Anchored = false` |
| Script does nothing | Wrong script type/location, or script **Disabled** | Check §8 table; Properties → Enabled |
| `X is not a valid member of Y` | Name typo, wrong parent, or object not loaded yet | Check exact name/case. Use `WaitForChild` on the client |
| `Infinite yield possible on WaitForChild` | Object never appears under that name/parent | Fix the name/path |
| Changes vanished | Edited during a playtest | Stop first, then edit |
| Data not saving in Studio | API access off / unpublished place | §10 |
| Touched fires many times | No debounce | Add a cooldown per player |
| UI looks fine on PC, broken on phone | Offset sizes, no constraints | Use Scale, UIAspectRatioConstraint, Device Simulator |
| Can't select a part | It's **Locked** | Alt+L or Edit → Unlock All |
| Lost in the viewport | – | Select something in Explorer → **F** |

## 14. How to teach a beginner

When the user is new, teach in **small lessons**. Each lesson has a goal, numbered click-steps with exact English labels, a mini exercise, and a "check" the user can confirm. Never more than ~10 steps per lesson; wait for feedback before continuing. Suggested order:

1. **Orientation:** open Studio → Baseplate. Find Explorer/Properties/Output via Window. Practice camera (right mouse, WASD, F).
2. **Parts:** insert a Block, move/scale/rotate (2/3/4), change Color/Material, **Anchor** it. Exercise: build a 5-step staircase with exact sizes.
3. **Testing:** Test (F5), Stop (Shift+F5), Test Here. Learn that test-time changes revert.
4. **First script:** Script inside a part → kill brick with `Touched`. Read the Output and break it on purpose to see an error.
5. **Explorer organization:** Folders, Models (Ctrl+G), naming, tags. Convert the kill brick to a tag-based KillBrick (Hazards module).
6. **Client vs server:** LocalScript prints vs Script prints (blue/green labels), the Client/Server toggle.
7. **UI:** ScreenGui in StarterGui, TextLabel, Scale sizing, Device Simulator.
8. **Publishing:** Publish to Roblox (private), Experience Settings → Security, test saving with Server & Clients.
9. **Project:** set up `games/mein-erstes-obby` (its README is written for this order).
