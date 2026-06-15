@tool
extends RefCounted

static func get_manual_text() -> String:
	return """[center][font_size=22][b][color=#46a0f5]ULTIMATE ASSET PLACER[/color][/b][/font_size]
[font_size=13][color=#7e8299]Complete Guide & Full Feature Documentation  —  v1.5.0  |  Godot 4.5.1  |  Made by Choco Ted [/color][/font_size][/center]

[color=#8899aa]🔗 Plugin page:[/color] [color=#46a0f5][url=https://choco-ted.itch.io/ultimate-asset-placer-godot-45-gd-script]https://choco-ted.itch.io/ultimate-asset-placer-godot-45-gd-script[/url][/color]
[color=#f2c94c]⭐ Enjoying the plugin? Please leave a rating:[/color] [color=#46a0f5][url=https://choco-ted.itch.io/ultimate-asset-placer-godot-45-gd-script/rate?source=game]Rate on itch.io[/url][/color]

[color=#3a3d50]━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━[/color]

[color=#45e055][b]🚀  QUICK START — HOW TO PLACE YOUR FIRST ASSET[/b][/color]

[b]1.[/b] Open a 3D scene (scene root must be a Node3D or any 3D node).
[b]2.[/b] In the [b]Asset Browser[/b] at the top, set the [b]Folder[/b] field to a folder that contains your 3D assets and click [b]Refresh[/b].
[b]3.[/b] [b]Left-Click[/b] any thumbnail card in the browser. A glowing blue ghost preview appears in the 3D viewport following your cursor.
[b]4.[/b] Move your mouse over the viewport and [b]Left-Click[/b] to place the asset. It appears with a small springy animation.
[b]5.[/b] [b]Right-Click[/b] or press [b]ESC[/b] to stop placing.

[color=#f0b834]💡 Every placement is fully undoable with Ctrl+Z.[/color]

[color=#3a3d50]━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━[/color]

[font_size=16][b][color=#e0e8ff]📦  THE ASSET BROWSER[/color][/b][/font_size]

The browser is the large panel showing thumbnail cards of all your 3D assets. It scans your chosen folder automatically on startup.

[color=#46a0f5][b]Folder Controls[/b][/color]
[b]Folder field[/b]  — Shows the folder being scanned. Type a path and press Enter to change it.
[b]... (Browse)[/b]  — Opens a folder picker dialog to choose a folder visually.
[b]Refresh[/b]  — Re-scans the current folder to pick up any new files you have added.
[b]Clear[/b]  — Empties the browser and frees memory. Does not delete any files.

[color=#46a0f5][b]Search & Thumbnails[/b][/color]
[b]Search box[/b]  — Type any part of a filename to filter cards in real-time (case-insensitive).
[b]88px label[/b]  — Shows the current thumbnail size. [b]Ctrl + Scroll Wheel[/b] over the browser to resize thumbnails between 54 px and 200 px.

[color=#46a0f5][b]Sliders & Number Fields[/b][/color]
Every slider in the plugin has a number field on its right. You can drag the slider for quick adjustments, [i]or[/i] click the number field and type any value — including values [b]beyond[/b] the slider's minimum and maximum range. For example, a Scale slider that goes 0.01–20 can be overridden by typing 50 directly in the number box. The slider thumb clamps to its visual range but the actual value is applied exactly as typed.

[color=#46a0f5][b]Multi-Selection[/b][/color]
You can select more than one asset at a time. When multiple assets are selected, UAP randomly picks one of them on each placement — great for forests and rubble piles.

[b]Ctrl + Left Click[/b]  — Toggle-select an individual card (adds or removes it from the selection).
[b]Shift + Left Click[/b]  — Range-selects all cards between the last clicked card and this one.
[b]Add All (multi-select bar)[/b]  — Adds all currently selected assets to the chosen group.
[b]X (multi-select bar)[/b]  — Clears the multi-selection.

[color=#f0b834]💡 When multiple assets are Ctrl-selected and you paint, UAP automatically picks randomly between them — no extra setup needed![/color]

[color=#46a0f5][b]Drag & Drop[/b][/color]
Drag 3D asset files directly from Godot's FileSystem panel onto the browser area. UAP adds them even if they are outside your current scan folder. If a group filter is currently active, dragged assets are automatically added to that group as well.

[color=#f0b834]💡 Drop onto the browser area at any time — you don't need to have a group active. Assets are always added to the global list first, and optionally to the active group.[/color]

[color=#46a0f5][b]Status Bar & Stop Button[/b][/color]
[b]Status bar[/b]  — Shows what UAP is doing: scanning, building, placing, or idle.
[b]Stop[/b]  — Immediately cancels the current placement session. Same as pressing Escape or right-clicking.

[color=#3a3d50]━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━[/color]

[font_size=16][b][color=#e0e8ff]🎯  PLACEMENT MODES[/color][/b][/font_size]

At the top of the Settings panel are [b]four[/b] mode buttons: [b]Free, Grid, Surface, Vertex[/b]. These control [i]where[/i] and [i]how[/i] your asset snaps into the world. The active mode is highlighted with a coloured border. You can switch modes at any time, even mid-placement.

[color=#f0b834]💡 Spline is no longer a mode button. It has its own dedicated [b]Spline Tab[/b] with full controls. Use the Spline tab to create or activate a spline — this automatically suspends normal placement so viewport clicks edit the curve instead of placing assets.[/color]

[color=#888899][b]── FREE MODE ──[/b][/color]

The simplest mode. Your asset floats on an invisible horizontal plane at the current Grid Y height. No snapping — the asset goes exactly where your mouse is.

[b]Best for:[/b] Placing single objects manually at a precise XZ position, or floating objects at a specific height.

[color=#f0b834]💡 Use Height Offset (Place tab) to raise or lower where objects land on the Y plane.[/color]

[color=#46a0f5][b]── GRID MODE ──[/b][/color]

Snaps your asset to a visible XZ grid. Set the cell size (e.g. 1 m, 0.5 m) and every placement snaps to the nearest grid intersection. A blue grid appears in the viewport to guide you.

[b]Best for:[/b] Modular buildings, tile-based layouts, any grid-aligned level design.

[b]Grid Size[/b]  — Cell size in metres (0.0625 m to 200 m). Click [b]1m[/b] to quickly reset to 1 metre.
[b]Grid Y[/b]  — The height of the grid plane. Use the [b]v[/b] and [b]^[/b] buttons to step it by one grid unit.
[b]Show Grid toggle[/b]  — Hides or shows the blue grid lines (snap still works when hidden).
[b]Snap to Grid toggle[/b]  — Disabling this makes Grid mode behave like Free mode (no XZ snap).
[b]Layer Up / Layer Down keys[/b]  — Default [b]Home[/b] / [b]End[/b]. Moves the grid plane up or down by exactly one grid unit — great for multi-floor buildings.

[color=#45e055][b]── SURFACE MODE ──[/b][/color]

Fires a physics raycast from your cursor into the scene. Your asset snaps to whatever physics surface is hit — terrain, a floor, a rock face, anything with a collider.

[b]Best for:[/b] Placing props on uneven terrain, populating landscapes, decorating organic surfaces.

[b]Align to Normal (Place tab)[/b]  — When ON, the asset tilts to match the slope of the surface it lands on (like a tree growing on a hillside). When OFF, the asset always stays upright.

[color=#e85858]⚠ Surface mode requires your terrain to have a StaticBody3D + CollisionShape3D. Without collision, UAP falls back to placing at Y = 0.[/color]

[color=#f0b834][b]── VERTEX MODE ──[/b][/color]

Moves freely like Free mode, but magnetically snaps to mesh corners (vertices) when the ghost gets close enough. A precise alignment tool.

[b]Best for:[/b] Snapping furniture to wall corners, aligning modular pieces, placing objects exactly on mesh boundaries.

[b]Magnet px[/b]  — How close in screen pixels the ghost must be before snapping triggers. Default: 42. Higher = stronger magnet.
[b]Mesh Vertex Snap toggle[/b]  — ON: tests actual mesh geometry vertices (more accurate, slower). OFF: tests bounding-box corners (faster).

[color=#3a3d50]━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━[/color]

[font_size=16][b][color=#e0e8ff]🖱️  SCROLL WHEEL CONTROL[/color][/b][/font_size]

The six buttons below the mode bar let you re-assign your mouse scroll wheel while placing.

[b]Off[/b]  — Scroll wheel is free (default). Use keyboard shortcuts for rotation and scale.
[b]Scale[/b]  — Scroll up = bigger. Scroll down = smaller. Each step changes scale by 0.1.
[b]Rot Y[/b]  — Scroll to spin the ghost around its vertical axis.
[b]Rot X[/b]  — Scroll to pitch the ghost forward or backward.
[b]Rot Z[/b]  — Scroll to roll the ghost left or right.
[b]Height[/b]  — Scroll to raise or lower the Height Offset.

[color=#f0b834]💡 Alt + Scroll Wheel always adjusts Height Offset, regardless of the Scroll Mode setting.[/color]

[color=#3a3d50]━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━[/color]

[font_size=16][b][color=#e0e8ff]⚙️  SETTINGS — PLACE TAB[/color][/b][/font_size]

[color=#46a0f5][b]Parent Node[/b][/color]
By default, placed assets become children of the scene root. You can override this to keep your scene tree organised.

[b]Pick[/b]  — Select a Node3D in the scene tree first, then click Pick. All future placements become children of that node.
[b]X[/b]  — Clears the parent override. Assets go back to the scene root.

[color=#f0b834]💡 Example: select a node called "Trees" before clicking Pick, and all tree assets automatically go inside it.[/color]

[color=#46a0f5][b]Scene Settings[/b][/color]
[b]Unpack Scenes[/b]  — When OFF (default): placed .tscn files stay as packed instances (a single node). When ON: UAP unpacks the scene so every internal node is individually visible and editable in the tree.
[color=#e85858]⚠ Unpacked scenes are no longer linked to the original .tscn file. Future changes to the file won't update your placed copy.[/color]

[color=#46a0f5][b]Grid & Snapping[/b][/color]
[b]Show Grid[/b]  — Toggles the visual grid lines in the viewport.
[b]Snap to Grid[/b]  — Enables or disables XZ position snapping.
[b]Grid Size[/b]  — Grid cell size in metres. Range: 0.0625 m to 200 m.
[b]Grid Y[/b]  — Height of the grid plane. Step buttons nudge it by one grid unit.
[b]1m button[/b]  — Instantly resets Grid Size to 1.0 metre.

[color=#46a0f5][b]Height Offset[/b][/color]
Adds a fixed vertical offset to every placed asset. Use positive values to float objects above a surface, negative to push them into it (e.g. flowers sinking into grass).

[b]Offset Y[/b]  — Range: -500 m to +500 m.
[b]Snap Height[/b]  — When ON, the offset snaps to multiples of Grid Size.
[b]Height Up / Down keys[/b]  — Default [b]Page Up[/b] / [b]Page Down[/b]. Nudges offset by 0.1 m (or one Grid Size if Snap Height is ON).

[color=#46a0f5][b]Surface & Vertex Options[/b][/color]
[b]Align to Normal[/b]  — (Surface mode) Tilts placed assets to match the surface slope.
[b]Mesh Vertex Snap[/b]  — (Vertex mode) Tests actual geometry vertices instead of bounding-box corners.
[b]Magnet px[/b]  — (Vertex mode) Snap trigger distance in screen pixels. Default: 42.

[color=#46a0f5][b]Format Filter[/b][/color]
Buttons for each supported format: [b]GLB, GLTF, FBX, OBJ, DAE, BLEND, TSCN, SCN, RES, MESH[/b]. Lit = included in scan. Changing any filter triggers a re-scan automatically.

[b]All On[/b]  — Enables every format.
[b]All Off[/b]  — Disables every format (useful to quickly clear before enabling only what you need).

[color=#46a0f5][b]Asset Zoo[/b][/color]
Places every loaded asset in a neat grid inside an [b]AssetZoo[/b] node — a visual 3D catalogue you can walk around.

[b]Create Asset Zoo[/b]  — Spawns all loaded assets, auto-spaced by their bounding boxes.
[b]Spacing[/b]  — Gap between assets in metres (default 2.0).
[b]Show Labels[/b]  — Adds a floating Label3D with the filename above each zoo asset.
[color=#e85858]⚠ Delete the AssetZoo node when done — do not leave it in your final scene.[/color]

[color=#3a3d50]━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━[/color]

[font_size=16][b][color=#e0e8ff]🔄  SETTINGS — TRANSFORM TAB[/color][/b][/font_size]

[color=#46a0f5][b]Rotation Snap[/b][/color]
Controls how many degrees each keyboard rotation press moves the ghost.

[b]Free[/b]  — No snapping, 1-degree precision.
[b]90 deg[/b]  — Snaps to 0°, 90°, 180°, 270°. Perfect for grid buildings.
[b]45 deg[/b]  — Every 45° — useful for diagonal placements.
[b]15 deg[/b]  — Good middle-ground snapping.
[b]Custom[/b]  — Reveals a slider to set any snap angle from 0.5° to 180°.

[color=#46a0f5][b]Current Rotation[/b][/color]
Three sliders showing the ghost's live rotation. Type a value directly or drag the slider.

[b]Rot X[/b]  — Pitch (forward/backward tilt). Range: -360° to 360°.
[b]Rot Y[/b]  — Yaw (vertical spin). Most commonly used.
[b]Rot Z[/b]  — Roll (left/right lean).
[b]Reset X Y Z[/b]  — Sets all three axes back to 0° instantly.

[color=#f0b834]💡 The sliders update live as you use keyboard shortcuts, and vice versa.[/color]

[color=#46a0f5][b]Quick Orient Presets[/b][/color]
One-click buttons to jump to common orientations.

[b]Normal[/b]  → 0, 0, 0  — standard upright.
[b]Upside Down[/b]  → Rx 180° — for ceiling attachments.
[b]Lay Fwd[/b]  → Rx 90° — asset flat, facing forward.
[b]Lay Back[/b]  → Rx -90° — asset flat, facing backward.
[b]Tilt L[/b]  → Rz -90° — leaning left.
[b]Tilt R[/b]  → Rz 90° — leaning right.
[b]Turn 90[/b]  → Ry 90° — facing left.
[b]Turn 180[/b]  → Ry 180° — facing backward.

[color=#46a0f5][b]Random Rotation[/b][/color]
Every placed asset gets a random Y rotation chosen from a range instead of the current Rot Y value.

[b]Enable[/b]  — Toggle random Y rotation on/off.
[b]Min deg[/b]  — Minimum Y rotation. Default: 0°.
[b]Max deg[/b]  — Maximum Y rotation. Default: 360° (fully random).

[color=#46a0f5][b]Random Tilt[/b][/color]
Randomly tilts each asset on both X and Z axes symmetrically — great for imperfect gravestones, leaning poles, scattered rocks.

[b]Enable[/b]  — Toggle random tilt on/off.
[b]+/- Max deg[/b]  — Maximum tilt per axis (symmetric). E.g. 10° = tilts between -10° and +10° on both X and Z.

[color=#46a0f5][b]Scale Presets[/b][/color]
Quick buttons at the top of the Scale section: [b]x0.25  x0.5  x1  x1.5  x2  x3  x5[/b]. Clicking one instantly applies that multiplier to all axes.

[color=#46a0f5][b]Scale Controls[/b][/color]
[b]Uniform toggle[/b]  — ON (default): one slider controls all axes together. OFF: separate X, Y, Z sliders.
[b]Scale slider[/b]  — (Uniform ON) Single multiplier. Default: 1.0. Range: 0.01 to 20.
[b]X / Y / Z sliders[/b]  — (Uniform OFF) Individual axis scale.
[b]Flip X key (G)[/b]  — Mirrors the ghost on X by making the X scale negative.
[b]Flip Z key (B)[/b]  — Mirrors the ghost on Z.
[b]Scale Up / Down keys (] / [)[/b]  — Nudge scale ±0.1 per press. Hold Shift for fine ±0.025 steps.

[color=#46a0f5][b]Random Scale[/b][/color]
Multiplies each placed asset's scale by a random value in the Min–Max range.

[b]Enable[/b]  — Toggle random scale on/off.
[b]Min[/b]  — Minimum multiplier. Default: 0.8.
[b]Max[/b]  — Maximum multiplier. Default: 1.2.

[color=#f0b834]💡 Random scale stacks on top of your base scale. Base 2.0 + range 0.8–1.2 = final scale 1.6–2.4.[/color]

[color=#3a3d50]━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━[/color]

[font_size=16][b][color=#e0e8ff]🖌️  SETTINGS — PAINT TAB[/color][/b][/font_size]

[color=#46a0f5][b]Paint Mode[/b][/color]
When enabled, hold Left Mouse Button and drag to continuously stamp assets as you move — like painting with a brush across the viewport.

[b]Enable Paint[/b]  — Turns paint mode on/off.
[b]Spacing[/b]  — How far apart each stamp must be (as a multiple of Grid Size) before the next one fires. 0.5 = half a grid cell. Lower = denser painting.
[b]Scatter[/b]  — Adds a random XZ offset to each stamp so they don't fall in a perfectly straight line.
[b]Scatter R[/b]  — Radius in metres of the scatter randomness. Larger = more chaotic spread.

[color=#f0b834]💡 Best combo for natural environments: Paint Mode + Random Rotation + Random Scale + Scatter.[/color]

[color=#46a0f5][b]Volumetric Brush[/b][/color]
Replaces drag-line painting with a large circular area brush. A glowing purple torus ring follows your cursor. Hold left-click to spray assets randomly inside the ring.

[b]Use Brush[/b]  — Switches from line-painting to the circular brush. Requires Paint Mode to also be ON.
[b]Radius m[/b]  — The brush circle radius in metres (0.1 to 50). Default: 2.0.
[b]Density[/b]  — How many assets to try placing per brush stroke. Higher = more packed. Range: 0.05 to 10.
[b]Falloff[/b]  — 0.0 = uniform density across the whole circle. 1.0 = dense in the centre, sparse at the edge.
[b]Mask Texture — Pick[/b]  — Load a greyscale image (PNG/JPG/WebP). White = full density, Black = no assets. Paint with any custom shape.
[b]Mask Texture — X[/b]  — Clears the mask and returns to a plain circle brush.

[color=#f0b834]💡 The brush works best in Surface mode — it raycasts down individually for each asset placed inside the circle, so everything lands on the terrain.[/color]

[color=#46a0f5][b]Random Group Placer[/b][/color]
Makes UAP randomly pick from an entire active group (or your multi-selection) on every placement instead of always using the same asset.

[b]Enable[/b]  — Toggle random group picking on/off.

Priority order for random picking:
[b]1.[/b] Multiple Ctrl-selected assets in the browser → picks from those first.
[b]2.[/b] Random Group Placer ON + active group → picks from the group.
[b]3.[/b] Otherwise → uses the single selected asset.

Example workflow:
• Create a group called "Forest Trees". Add oak.glb, pine.glb, birch.glb to it.
• Click the "Forest Trees" filter button. Enable Random Group Placer + Paint Mode.
• Start painting — every stamp is randomly one of your three tree types.

[color=#46a0f5][b]MultiMesh Painter[/b][/color]
Instead of placing hundreds of individual nodes, MultiMesh Mode batches all painted assets into a single [b]MultiMeshInstance3D[/b]. Godot renders thousands of MultiMesh instances far more efficiently than separate nodes.

[b]MultiMesh Mode[/b]  — ON: painted assets go into a MultiMeshInstance3D. OFF: normal individual nodes.
[b]Add Collision[/b]  — Also generates collision shapes for MultiMesh instances when painting.
[b]Clear All MultiMesh Instances[/b]  — Removes all painted MultiMesh instances. Use carefully — difficult to undo.
[b]Generate Instance Collision[/b]  — After painting, click to generate collision shapes for all existing MultiMesh instances.
[b]Commit MultiMesh[/b]  — Finalises the MultiMesh data (for compatibility).

[color=#e85858]⚠ MultiMesh mode only uses the first mesh found in an asset. Complex multi-mesh scenes only render their first mesh in MultiMesh mode.[/color]
[color=#f0b834]💡 Undo works per paint stroke (one press+release of left-click = one undo step).[/color]

[color=#3a3d50]━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━[/color]

[font_size=16][b][color=#e0e8ff]〰️  SETTINGS — SPLINE TAB (ADVANCED)[/color][/b][/font_size]

The Advanced Spline system builds on Godot's Path3D node. You can scatter props evenly along a curve, or deform a mesh to follow the curve (roads, rivers, fences, walls). The workflow has four numbered steps.

[color=#46a0f5][b]Spline Mode Status Banner[/b][/color]

At the top of the Spline tab, a live status banner shows whether Spline Mode is currently active.

[b]● SPLINE MODE ACTIVE — [name][/b]  — Spline mode is on. Viewport left-clicks edit the curve, not place assets. The name of the active spline is shown.
[b]○ No spline active[/b]  — No spline is selected. Create or select one below.

[color=#f0b834]💡 When spline mode is active, normal placement is suspended. Your scroll-wheel modes and mode buttons are ignored until you exit spline mode.[/color]

[b]✕ Exit Spline Mode[/b]  — Deactivates spline mode and restores the previous placement mode (Free, Grid, Surface, or Vertex). The spline node is [i]not[/i] deleted — it stays in the scene for later use. Click this when you are done shaping the curve and want to resume placing regular assets.

[color=#46a0f5][b]Step 1 — Spline Node Setup[/b][/color]

[b]+ Create New Spline[/b]  — Creates a uniquely named AdvancedSpline node (Path3D + uap_path.gd script) in your scene. The first spline is named [b]AdvancedSpline[/b]; subsequent ones are named [b]AdvancedSpline_2[/b], [b]AdvancedSpline_3[/b], etc. — never @NodeXXX. Spline mode activates automatically. Use Godot's built-in Path3D editing tool (select the node in the scene tree, then use the toolbar at the top of the 3D viewport) to draw control points.
[b]Use Selected Spline[/b]  — Select an existing AdvancedSpline node in the scene tree, then click this to make it the active spline. Spline mode activates automatically.
[b]Smooth[/b]  — Smooths all control point tangents — creates flowing S-curve shapes.
[b]Sharpen[/b]  — Resets all tangents to zero — creates sharp corner-to-corner straight segments.
[b]Delete Active Spline[/b]  — Removes the active spline node from the scene entirely and exits spline mode.

[color=#46a0f5][b]Step 2 — Terrain Snapping[/b][/color]
After drawing a spline in the air, snap it onto your terrain automatically.

[b]Drop to Ground (Keep Shape)[/b]  — Finds the lowest control point, measures how far above the ground it is, and shifts the entire spline down by that amount. The shape is fully preserved.
[b]Wrap Points to Terrain[/b]  — Raycasts downward from each control point and moves each one individually onto the terrain surface.
[b]Subdivide & Wrap (Exact Shape)[/b]  — Adds new points every 1 metre along the spline first, then wraps all of them to the terrain. Best quality. Follows hills and cliffs precisely.

[color=#e85858]⚠ Terrain snapping requires physics collision on your terrain (StaticBody3D + CollisionShape3D).[/color]

[color=#46a0f5][b]Step 3 — Layer Manager[/b][/color]
Each spline supports multiple layers. Each layer either scatters props or deforms a mesh. Mix as many as you want on one spline.

[b]+ Scatter (Props)[/b]  — Adds a Scatter layer using the currently browser-selected asset. Props are spaced evenly along the curve.
[b]+ Deform (Roads)[/b]  — Adds a Deform layer using the selected asset's mesh, stretched along the full curve length. Ideal for roads, rivers, tunnels.

[b]Scatter layer options:[/b]
  [b]Meshes field[/b]  — Asset path(s) to scatter. Separate multiple paths with commas for random variety. Click [b]+ Add Selected[/b] to append the browser-selected asset.
  [b]Spacing[/b]  — Slider with number field. Distance in metres between instances. You can type any value beyond the slider range — just type it in the number box. Smaller = denser.
  [b]Align to Curve[/b]  — ON: each instance rotates to face along the curve. OFF: all use their default rotation.
  [b]Use MultiMesh[/b]  — ON: render as MultiMesh (very fast, many instances). OFF: individual nodes (deletable before baking).
  [b]Rnd Yaw deg[/b]  — Slider with number field. Random Y rotation applied to each instance within +/- this many degrees.

[b]Deform layer options:[/b]
  [b]Invert Faces[/b]  — Flips mesh faces. Use this if your road or tunnel is inside-out.
  [b]UV Tile X | Y[/b]  — Sliders with number fields. How many times the texture repeats along (X) and across (Y) the deformed mesh. Increase X to fix stretched textures on long roads.

[b]Common options (both layer types):[/b]
  [b]Scale X | Y | Z[/b]  — Sliders with number fields. Non-uniform scale for the layer. Type beyond the slider range for extreme values.
  [b]Offset X | Y | Z[/b]  — Sliders with number fields. Positional offset relative to the curve. Use Offset Y to raise props above the curve surface.
  [b]Add Collision on Bake[/b]  — When checked, collision shapes are generated automatically when you click Bake.
  [b]Remove Layer[/b]  — Deletes this layer from the spline.

[color=#46a0f5][b]Step 4 — Bake to Scene[/b][/color]
Procedural spline objects regenerate whenever the curve changes — you cannot delete individual instances until the spline is baked. Baking converts everything into permanent, editable scene nodes.

[b]BAKE TO NODES (Finalize)[/b]  — Converts all layer instances into regular Godot nodes (one [b]MeshInstance3D[/b] per spline instance). Best when you need to select, move, or delete individual pieces after baking. Spline mode is exited automatically, the Path3D is removed, and if "Add Collision on Bake" was checked, collision bodies are generated.

[b]BAKE TO MULTIMESH (Performance)[/b]  — Bakes scatter layers as [b]MultiMeshInstance3D[/b] nodes instead of individual MeshInstance3D nodes. All instances of the same mesh are packed into one MultiMesh, giving the same GPU draw-call savings as the live procedural mode. Deform layers are still baked as a regular MeshInstance3D (they are already a single merged mesh, so MultiMesh would give no benefit). Use this when you are happy with the final result and want maximum runtime performance — grass paths, fence lines, rock scatters, etc.

[color=#f0b834]💡 Use [b]BAKE TO NODES[/b] when you still need to edit or delete individual pieces. Use [b]BAKE TO MULTIMESH[/b] when the layout is final and performance matters most.[/color]

[color=#e85858]⚠ Baking is permanent — there is no undo. Make sure you are satisfied with the result before baking.[/color]

[color=#3a3d50]━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━[/color]

[font_size=16][b][color=#e0e8ff]🎨  SETTINGS — MATERIAL TAB[/color][/b][/font_size]

Automatically apply a material to every asset you place — useful for colour coding props during layout, applying a tint, or layering a snow/wetness effect.

[b]Enable Override[/b]  — ON: every placed asset gets the selected material applied automatically.

[b]Apply Mode — Replace[/b]  — Replaces all surface materials on the asset with your override material. The original material is completely gone.
[b]Apply Mode — Next Pass[/b]  — Adds your override material as a [b]next_pass[/b] on top of the original material. This layers effects (snow, rain, glow) without destroying the original look. Each placed instance gets its own independent material copy — toggling the override on or off for a new placement does [i]not[/i] affect previously placed instances.

[b]Material — Pick[/b]  — Opens a file picker to select a .tres or .res material file.
[b]Material — X[/b]  — Clears the material override.

[color=#f0b834]💡 Next Pass mode duplicates the base surface material per instance, so turning off the override later won't retroactively change already-placed objects.[/color]

[color=#3a3d50]━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━[/color]

[font_size=16][b][color=#e0e8ff]📁  SETTINGS — GROUPS TAB[/color][/b][/font_size]

Groups let you organise assets into named collections. The [b]Favorites[/b] group is built-in. Create as many custom groups as you need.

[b]New group name field + Add[/b]  — Type a name and click Add to create a new group.
[b]X (per group)[/b]  — Deletes the group. Assets inside it are NOT deleted — they just lose group membership.

[color=#46a0f5][b]Four ways to add assets to a group:[/b][/color]
[b]1.[/b] Single-click an asset in the browser → choose a group from the [b]Add to group[/b] dropdown → click [b]Add[/b].
[b]2.[/b] Ctrl-click multiple assets → choose a group in the multi-select bar → click [b]Add All[/b].
[b]3.[/b] Click [b]Browse...[/b] in the "Import Folder to Group" section → choose a folder → all 3D assets found recursively in that folder are added to the group in bulk.
[b]4.[/b] [b]Drag & Drop[/b] — Drag asset files directly from Godot's FileSystem panel onto the browser area. If a group is currently active (you clicked its filter button), the dropped assets are added to that group automatically as well as to the global asset list.

[color=#46a0f5][b]Removing assets from a group:[/b][/color]
[b]Remove from Group[/b] button (Groups tab) — Select one or more assets in the browser first, then click [b]Remove from Group[/b]. No dropdown needed — the plugin detects automatically which group(s) the asset belongs to:
  • Viewing a [b]specific group[/b] → removes from that group only.
  • Viewing [b]Favorites[/b] → removes from Favorites only.
  • Viewing [b]All[/b] or search results → removes from every group the asset is in.

[b]Multi-remove:[/b] Ctrl+Click or Shift+Click to select multiple assets in the browser, then click [b]Remove[/b] in the multi-select bar that appears. All selected assets are removed at once.

[color=#f0b834]💡 Removing from a group does not delete the asset file. It only removes the group membership.[/color]

[color=#46a0f5][b]Using groups:[/b][/color]
• Click a group button in the browser filter bar to show only assets in that group.
• Enable [b]Random Group Placer[/b] in the Paint tab to randomly pick from the active group on every placement.

[color=#3a3d50]━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━[/color]

[font_size=16][b][color=#e0e8ff]⌨️  SETTINGS — KEYS TAB[/color][/b][/font_size]

Customise every keyboard shortcut used during placement. Click any shortcut button to enter recording mode, then press the key you want to assign.

[b]Rotate Y  (Shift = CCW)[/b]  → default [b]R[/b]
Spins the ghost around the Y axis. Shift reverses direction.

[b]Pitch X  (Shift = rev)[/b]  → default [b]E[/b]
Tilts the ghost forward or backward.

[b]Roll Z  (Shift = rev)[/b]  → default [b]Q[/b]
Rolls the ghost left or right.

[b]Scale Up[/b]  → default [b]][/b]
Makes the ghost bigger by 0.1. Hold Shift for fine steps of 0.025.

[b]Scale Down[/b]  → default [b][[/b]
Makes the ghost smaller. Hold Shift for fine 0.025 steps.

[b]Height Up[/b]  → default [b]Page Up[/b]
Raises the Height Offset by the step size.

[b]Height Down[/b]  → default [b]Page Down[/b]
Lowers the Height Offset.

[b]Layer Up[/b]  → default [b]Home[/b]
Moves the Grid Y plane up by one grid unit.

[b]Layer Down[/b]  → default [b]End[/b]
Moves the Grid Y plane down by one grid unit.

[b]Flip X[/b]  → default [b]G[/b]
Mirrors the ghost on the X axis (negative X scale).

[b]Flip Z[/b]  → default [b]B[/b]
Mirrors the ghost on the Z axis.

[b]Reset Transform[/b]  → default [b]T[/b]
Resets rotation to 0,0,0 and clears both flips.

[b]Reset All to Defaults[/b]  — Restores every shortcut to its factory default key.

[color=#f0b834]💡 Escape and Right Mouse Button always cancel placement — these cannot be rebound.[/color]
[color=#f0b834]💡 Keys repeat when held. There is a short initial delay, then they accelerate for faster input.[/color]

[color=#3a3d50]━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━[/color]

[font_size=16][b][color=#e0e8ff]💥  SETTINGS — COLLISION TAB[/color][/b][/font_size]

Automatically generate collision shapes for every asset placed — no need to manually add StaticBody3D and CollisionShape3D nodes after placing.

[color=#46a0f5][b]Enable on Place[/b][/color]  — When ON, UAP adds a physics body and collision shape to every asset the moment it is placed.

[color=#46a0f5][b]Body Type[/b][/color]
[b]StaticBody3D[/b]  — Default. The object cannot move. Use for floors, walls, terrain, props.
[b]RigidBody3D[/b]  — Physics-simulated. The placed object falls, bounces, and reacts to forces. The mesh becomes a child of the RigidBody.
[b]CharacterBody3D[/b]  — For character controller bodies.
[b]Area3D[/b]  — Creates a trigger zone or pickup area.

[color=#46a0f5][b]Shape Type[/b][/color]
[b]Trimesh[/b]  — Exact mesh collision. Most accurate, slowest at runtime. [b]Only valid for StaticBody3D and Area3D.[/b]
[b]Convex Hull[/b]  — Simplified convex wrapper. Works with all body types. Good balance of accuracy and speed.
[b]Box[/b]  — Simple bounding box. Very fast. Good for furniture, crates, buildings.
[b]Sphere[/b]  — Bounding sphere. Very fast. Good for round objects like rocks and barrels.
[b]Capsule[/b]  — Capsule shape. Good for pillars, poles, bottles.

[color=#e85858]⚠ Trimesh collision is NOT valid for RigidBody3D or CharacterBody3D. UAP will warn you and upgrade to Convex Hull automatically.[/color]

[color=#46a0f5][b]Auto-Unpack (FBX / GLTF Options)[/b][/color]
When ON (default), placed FBX/GLTF scenes are unpacked before collision is added, so shapes attach directly to each MeshInstance3D rather than as a sibling of the packed scene root.

[color=#3a3d50]━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━[/color]

[font_size=16][b][color=#e0e8ff]⌨️  FULL KEYBOARD SHORTCUT REFERENCE[/color][/b][/font_size]

All shortcuts are active while placing (after clicking an asset card). All are rebindable in the Keys tab.

[b]R[/b]  → Rotate Y clockwise  |  [b]Shift+R[/b] → counter-clockwise
[b]E[/b]  → Pitch forward  |  [b]Shift+E[/b] → backward
[b]Q[/b]  → Roll right  |  [b]Shift+Q[/b] → left
[b]][/b]  → Scale Up +0.1  |  [b]Shift+][/b] → fine +0.025
[b][[/b]  → Scale Down -0.1  |  [b]Shift+[[/b] → fine -0.025
[b]Page Up[/b]  → Height Up
[b]Page Down[/b]  → Height Down
[b]Home[/b]  → Layer (Grid Y) Up
[b]End[/b]  → Layer (Grid Y) Down
[b]G[/b]  → Flip X (mirror on X axis)
[b]B[/b]  → Flip Z (mirror on Z axis)
[b]T[/b]  → Reset Transform (rotation + flips to zero)
[b]Escape[/b]  → Cancel placement (always works)
[b]Right Mouse Button[/b]  → Cancel placement (always works)
[b]Alt + Scroll Up[/b]  → Height Offset up (any scroll mode)
[b]Alt + Scroll Down[/b]  → Height Offset down (any scroll mode)
[b]Ctrl + Scroll (browser)[/b]  → Resize thumbnail cards (54 px – 200 px)
[b]Ctrl + Left Click (browser)[/b]  → Toggle multi-select an asset
[b]Shift + Left Click (browser)[/b]  → Range-select assets

[color=#3a3d50]━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━[/color]

[font_size=16][b][color=#e0e8ff]📋  WORKFLOW EXAMPLES[/color][/b][/font_size]

[color=#46a0f5][b]Workflow A — Placing a Grid-Aligned Building[/b][/color]
[b]1.[/b] Place tab → Grid Size = 1.0, Snap to Grid = ON.
[b]2.[/b] Mode bar → click [b]Grid[/b].
[b]3.[/b] Collision tab → Enable on Place = ON, Body = StaticBody3D, Shape = Box.
[b]4.[/b] Click the building asset in the browser.
[b]5.[/b] Move mouse to the desired grid cell. Press [b]R[/b] to rotate 90° if needed.
[b]6.[/b] Left-click to place. Press Escape when done.

[color=#46a0f5][b]Workflow B — Painting a Natural Forest[/b][/color]
[b]1.[/b] Create a group called "Trees". Add 3–5 different tree GLB files to it.
[b]2.[/b] Click the Trees group button in the filter bar.
[b]3.[/b] Mode bar → [b]Surface[/b]. Transform tab → Enable Random Rotation (0–360°), Enable Random Scale (0.8–1.3).
[b]4.[/b] Paint tab → Enable Paint Mode. Set Spacing to 0.3. Enable Scatter, Radius 0.5. Enable Random Group Placer.
[b]5.[/b] Click any tree in the browser, then hold and drag over terrain. Trees appear randomly.

[color=#46a0f5][b]Workflow C — Creating a Road with the Advanced Spline[/b][/color]
[b]1.[/b] Make sure terrain has StaticBody3D collision.
[b]2.[/b] Select your road mesh asset in the browser.
[b]3.[/b] Spline tab → click [b]+ Create New Spline[/b]. The green [b]● SPLINE MODE ACTIVE[/b] banner confirms spline mode is on.
[b]4.[/b] Select the AdvancedSpline in the scene tree. Use the Path3D toolbar in the 3D viewport to draw control points.
[b]5.[/b] Spline tab → click [b]Subdivide & Wrap (Exact Shape)[/b] to conform to terrain.
[b]6.[/b] Click [b]+ Deform (Roads)[/b]. Adjust UV Tile X (try 4–8) to fix texture stretching.
[b]7.[/b] Optionally add a [b]+ Scatter (Props)[/b] layer with lamp posts or barriers. For barrier layers with many repeated instances, enable [b]Use MultiMesh[/b] on that layer.
[b]8.[/b] Click [b]BAKE TO NODES (Finalize)[/b] if you need to edit individual pieces, or [b]BAKE TO MULTIMESH (Performance)[/b] if the layout is final and you want maximum runtime performance.
[b]9.[/b] Click [b]✕ Exit Spline Mode[/b] at any time if you want to resume normal asset placement before baking.

[color=#46a0f5][b]Workflow D — Performance Grass with MultiMesh[/b][/color]
[b]1.[/b] Paint tab → Enable [b]MultiMesh Mode[/b]. Enable [b]Volumetric Brush[/b] (Radius 5.0, Density 3.0, Falloff 0.3).
[b]2.[/b] Mode bar → [b]Surface[/b]. Transform tab → Enable Random Scale (0.7–1.3) + Random Rotation.
[b]3.[/b] Click your grass mesh in the browser.
[b]4.[/b] Hold left-click and drag over terrain. Thousands of instances, high performance.
[b]5.[/b] Click [b]Generate Instance Collision[/b] if physics interaction is needed.

[color=#46a0f5][b]Workflow E — High-Performance Spline Scatter with MultiMesh Bake[/b][/color]
[b]1.[/b] Spline tab → click [b]+ Create New Spline[/b].
[b]2.[/b] Draw a path — a forest edge, a fence line, a river bank.
[b]3.[/b] Click [b]+ Scatter (Props)[/b] with your chosen asset. Leave [b]Use MultiMesh[/b] ON (it is on by default).
[b]4.[/b] Adjust Spacing, Rnd Yaw, Scale, and Offset until the preview looks right.
[b]5.[/b] When satisfied, click [b]BAKE TO MULTIMESH (Performance)[/b].
[b]6.[/b] The Path3D is removed and a [b]*_MMBaked[/b] node group appears in the scene tree containing one [b]MultiMeshInstance3D[/b] per scatter mesh type. Godot renders all instances in a single draw call — ideal for forests, rocks, flowers, or any dense scatter.

[color=#3a3d50]━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━[/color]

[font_size=16][b][color=#e0e8ff]💡  TIPS & PERFORMANCE NOTES[/color][/b][/font_size]

• All settings (grid size, mode, scale, shortcuts, groups) save automatically to [b]user://ultimate_asset_placer.cfg[/b] and restore on next launch.
• Assets land best when their pivot point is at the bottom centre of the mesh. If an asset floats or sinks oddly in Surface mode, the original file may have a poorly placed pivot.
• The ghost preview is purely visual and never saved to the scene. Only left-clicking places a real node.
• Use [b]MultiMesh Mode[/b] for any object you will paint more than ~50 copies of (grass, rocks, leaves, small decorations).
• Set thumbnail size smaller (Ctrl+Scroll down in the browser) if you have hundreds of assets — larger thumbnails use more memory.
• Use the [b]Format Filter[/b] to exclude formats you don't use — this speeds up scanning.
• For long spline roads, set UV Tile X = (road length in metres / mesh length in metres) to prevent texture stretching.
• You can switch placement modes while actively placing — the ghost updates instantly.
• [b]Thumbnail cache[/b] is stored in [b]user://uap_thumbnails/[/b]. Delete this folder to force all thumbnails to regenerate. This is useful if you replace an asset file with a different mesh but the old thumbnail is still showing.
• [b]HiDPI / 4K monitors[/b]: the plugin respects Godot's editor scale setting. If the panel looks too small or large, adjust [b]Editor → Editor Settings → Interface → Display → Editor Scale[/b] and restart.

[color=#3a3d50]━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━[/color]

[font_size=16][b][color=#e0e8ff]🔧  TROUBLESHOOTING FAQ[/color][/b][/font_size]

[color=#f0b834][b]Q: The UAP panel is not showing after enabling the plugin.[/b][/color]
A: Restart the Godot editor. Check that the addon folder is named exactly [b]ultimate_placer[/b] inside [b]res://addons/[/b]. Check the Output panel for errors from plugin.gd.

[color=#f0b834][b]Q: Assets are not appearing in the browser.[/b][/color]
A: Check the Folder field points to a directory containing 3D files. Confirm the correct extensions are enabled in Format Filter. Click Refresh. If you just added files, let Godot's importer finish before scanning.

[color=#f0b834][b]Q: The ghost appears but clicking does nothing.[/b][/color]
A: Make sure your scene root is a Node3D (or any 3D node). UAP cannot place assets if the scene has a 2D root.

[color=#f0b834][b]Q: In Surface mode, the asset isn't sticking to my terrain.[/b][/color]
A: Add a [b]StaticBody3D[/b] with a [b]CollisionShape3D[/b] to your terrain mesh. Without collision, UAP falls back to Y = 0.

[color=#f0b834][b]Q: I can't add points to my spline / clicking places assets instead of editing the curve.[/b][/color]
A: You need to be in Spline Mode. Create a spline with [b]+ Create New Spline[/b] or select an existing one with [b]Use Selected Spline[/b] — both activate Spline Mode automatically. The green [b]● SPLINE MODE ACTIVE[/b] banner at the top of the Spline tab confirms it is on. Then select the AdvancedSpline node in the Scene Tree and use the Path3D point-editing toolbar at the top of the 3D viewport.

[color=#f0b834][b]Q: "Use Selected Spline" says no valid node found.[/b][/color]
A: Select the AdvancedSpline [b]Path3D[/b] node itself in the scene tree (not a child). It must have the uap_path.gd script attached — only nodes created by "+ Create New Spline" have this automatically.

[color=#f0b834][b]Q: My spline nodes are named @Node123 in the scene tree.[/b][/color]
A: This was a bug in earlier versions. v1.4 assigns unique names [b]before[/b] adding nodes to the tree, so Godot never generates @NodeXXX names. Splines are named AdvancedSpline, AdvancedSpline_2, etc. Placed assets use their filename. If you see old @NodeXXX names, they are from a previous session — you can rename them manually in the Scene Tree.

[color=#f0b834][b]Q: I pressed Ctrl+Z to undo a placed asset but the collision shape stayed in the scene.[/b][/color]
A: This was a bug in v1.4 when using [b]RigidBody3D[/b] auto-collision. v1.5 fixes undo for all body types: undoing now correctly removes the RigidBody3D wrapper (along with the mesh and collision shapes inside it) as well as any sibling collision bodies for StaticBody3D / Area3D modes. If you have leftover collision nodes from a previous session, delete them manually — they will be named [YourAsset]_RB or [YourAsset]_Collision in the scene tree.

[color=#f0b834][b]Q: Scene thumbnails are not showing / showing the wrong scene.[/b][/color]
A: UAP generates scene thumbnails automatically when you switch away from or close a scene. [b]Open each scene at least once[/b], look at it in the 3D viewport, then switch to another scene. UAP captures a screenshot of the viewport at that moment and saves it permanently. If old wrong thumbnails are cached, delete the folder [b]user://uap_thumbnails/[/b] (found via Project → Open User Data Folder) and reopen your scenes.

[color=#f0b834][b]Q: I get a Trimesh warning in the Collision tab.[/b][/color]
A: Trimesh cannot be used with RigidBody3D or CharacterBody3D. Switch the Shape Type to Convex Hull, Box, Sphere, or Capsule.

[color=#f0b834][b]Q: A .tscn card shows an orange warning border.[/b][/color]
A: That scene is currently open in the editor. You cannot place a scene inside itself. Open a different scene to use this asset.

[color=#f0b834][b]Q: Random scale / rotation is not working.[/b][/color]
A: Check the [b]Enable[/b] toggle inside the Random Scale or Random Rotation section is ON (checked). Also make sure Min and Max are different values.

[color=#f0b834][b]Q: Ctrl+Z does not undo a MultiMesh paint stroke.[/b][/color]
A: MultiMesh undo works per stroke (one press+release of left-click = one undo step). A long continuous drag counts as one step. Use regular placement mode for per-instance undo.

[color=#f0b834][b]Q: The plugin panel is too small / too large on my monitor.[/b][/color]
A: UAP scales with Godot's editor scale. Go to [b]Editor → Editor Settings → Interface → Display → Editor Scale[/b], set it to match your monitor DPI (e.g. 150% for 4K), and restart the editor. All UAP text and controls will scale identically to the rest of Godot's UI.

[center][color=#3a3d50]━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━[/color][/center]
[color=#f0b834][b]Q: What is the difference between BAKE TO NODES and BAKE TO MULTIMESH?[/b][/color]
A: [b]BAKE TO NODES[/b] unpacks every spline instance into an individual MeshInstance3D — best when you need to select, move, or delete specific pieces after baking. [b]BAKE TO MULTIMESH[/b] packs all instances of each mesh into a MultiMeshInstance3D, giving a single GPU draw call regardless of instance count. Use BAKE TO MULTIMESH for dense scatter layers (grass, rocks, trees) where you will not need to edit individual pieces at runtime.

[center][color=#3a3d50]━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━[/color][/center]
[center][color=#7e8299]Ultimate Asset Placer  •  v1.5.0  •  by Choco Ted  •  Godot 4.5.1[/color][/center]
"""
