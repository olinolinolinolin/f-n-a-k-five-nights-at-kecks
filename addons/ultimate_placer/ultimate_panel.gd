@tool
extends Control

# --- THUMBNAIL SETTINGS ---
var MAX_THUMBNAIL_RETRIES: int = 3
# --------------------------

const CONFIG_PATH := "user://ultimate_asset_placer.cfg"
const VERSION     := "1.5.0"

const ALL_FORMATS   := ["glb","gltf","fbx","obj","dae","blend","tscn","scn","res","mesh"]
const FORMAT_LABELS := ["GLB","GLTF","FBX","OBJ","DAE","BLEND","TSCN","SCN","RES","MESH"]

const C_BG        := Color(0.10, 0.11, 0.14)
const C_SURFACE   := Color(0.16, 0.17, 0.22)
const C_BORDER    := Color(0.22, 0.24, 0.32)
const C_ACCENT    := Color(0.28, 0.62, 1.00)
const C_ACCENT2   := Color(0.45, 0.75, 1.00)
const C_OK        := Color(0.40, 0.85, 0.50)
const C_WARN      := Color(1.00, 0.72, 0.18)
const C_ERROR     := Color(0.92, 0.35, 0.35)
const C_DIM       := Color(0.50, 0.52, 0.60)
const C_HEAD      := Color(0.88, 0.93, 1.00)
const C_TEXT      := Color(0.80, 0.83, 0.90)
const C_PLACING   := Color(1.00, 0.84, 0.22)
const C_CARD_BG   := Color(0.155, 0.165, 0.205)
const C_CARD_BD   := Color(0.22, 0.24, 0.32)
const C_SEL_BD    := Color(0.28, 0.62, 1.00)
const C_MULTI     := Color(1.00, 0.72, 0.18)

const MODE_LABELS := ["Free","Grid","Surface","Vertex","Spline"]
const MODE_TIPS   := [
	"Free: place anywhere on the Y plane, no snapping",
	"Grid: snap to grid on XZ, grid visualised in viewport",
	"Surface: place on any physics surface",
	"Vertex: moves freely, snaps when close to a mesh corner",
	"Spline: click to add points and repeat assets along a curve",
]
const MODE_COLORS := [
	Color(0.52,0.54,0.60),Color(0.28,0.62,1.00),Color(0.40,0.85,0.50),
	Color(1.00,0.72,0.18),Color(0.40,1.00,0.72),
]
# Indices visible as buttons in mode bar (Spline=4 removed — it has its own tab)
const MODE_BUTTON_INDICES := [0, 1, 2, 3]
const SCROLL_LABELS := ["Off","Scale","Rot Y","Rot X","Rot Z","Height"]
const KEY_NAMES: Dictionary = {
	"None":KEY_NONE,"Q":KEY_Q,"W":KEY_W,"E":KEY_E,"R":KEY_R,"T":KEY_T,"Y":KEY_Y,
	"U":KEY_U,"I":KEY_I,"O":KEY_O,"P":KEY_P,"F":KEY_F,"G":KEY_G,"H":KEY_H,
	"J":KEY_J,"K":KEY_K,"Z":KEY_Z,"X":KEY_X,"C":KEY_C,"V":KEY_V,"B":KEY_B,
	"N":KEY_N,"M":KEY_M,"[":KEY_BRACKETLEFT,"]":KEY_BRACKETRIGHT,
	"PageUp":KEY_PAGEUP,"PageDown":KEY_PAGEDOWN,"Home":KEY_HOME,"End":KEY_END,
	"Insert":KEY_INSERT,"Delete":KEY_DELETE,
}
const SHORTCUT_LABELS: Dictionary = {
	"rotate_y":"Rotate Y  (Shift=CCW)","rotate_x":"Pitch X   (Shift=rev)",
	"rotate_z":"Roll Z    (Shift=rev)","scale_up":"Scale Up","scale_down":"Scale Down",
	"height_up":"Height Up","height_down":"Height Down","layer_up":"Layer Up",
	"layer_down":"Layer Down","flip_x":"Flip X","flip_z":"Flip Z","reset_rot":"Reset Transform",
}

const BUILD_BATCH      := 15
const THUMB_INTERVAL   := 0.1
const MAX_PENDING      := 6
const MAX_PER_TICK     := 2
const THUMB_CACHE_MAX  := 500
const SCAN_DIRS_FRAME  := 6
const SKIP_DIRS := [".godot", ".import", ".git", ".vs"]
const LIGHT_PREVIEW_EXTS := ["glb","gltf","fbx","obj","dae","res","mesh"]
const HEAVY_PREVIEW_EXTS := ["tscn","scn"]
const ALL_PREVIEW_EXTS := ["glb","gltf","fbx","obj","dae","res","mesh","tscn","scn"]
const MAX_HEAVY_PENDING := 1


# ─── SliderSpin: horizontal slider + editable number field ────────────────────
class SliderSpin extends HBoxContainer:
	signal value_changed(v: float)
	var value: float = 0.0
	var min_value: float = 0.0
	var max_value: float = 1.0
	var step: float = 0.01
	var _slider: HSlider = null
	var _edit: LineEdit = null
	var _updating: bool = false

	func _ready() -> void:
		var es := EditorInterface.get_editor_scale() if Engine.is_editor_hint() else 1.0
		add_theme_constant_override("separation", 4)
		size_flags_horizontal = SIZE_EXPAND_FILL
		_slider = HSlider.new()
		_slider.min_value = min_value; _slider.max_value = max_value
		_slider.step = step; _slider.value = value
		_slider.size_flags_horizontal = SIZE_EXPAND_FILL
		_slider.size_flags_vertical = SIZE_SHRINK_CENTER
		_slider.custom_minimum_size = Vector2(50, 0)
		_slider.value_changed.connect(_on_slider_changed)
		add_child(_slider)
		_edit = LineEdit.new()
		_edit.custom_minimum_size = Vector2(62 * es, 0)
		_edit.size_flags_horizontal = SIZE_SHRINK_END
		_edit.size_flags_vertical = SIZE_SHRINK_CENTER
		_edit.add_theme_constant_override("minimum_character_width", 1)
		_edit.text = _fmt(value)
		_edit.text_submitted.connect(_on_edit_submitted)
		_edit.focus_exited.connect(_on_edit_focus_exit)
		add_child(_edit)

	func _on_slider_changed(v: float) -> void:
		if _updating: return
		_updating = true; value = v
		if is_instance_valid(_edit): _edit.text = _fmt(v)
		_updating = false; value_changed.emit(v)

	func _on_edit_submitted(text: String) -> void:
		_apply_text(text)
		if is_instance_valid(_edit): _edit.release_focus()

	func _on_edit_focus_exit() -> void:
		_apply_text(_edit.text if is_instance_valid(_edit) else "0")

	func _apply_text(text: String) -> void:
		if _updating: return
		_updating = true
		var v := float(text)
		# Allow any typed value — do NOT clamp to min/max.
		# The slider thumb is clamped visually; the actual value can exceed limits.
		value = v
		if is_instance_valid(_slider): _slider.value = clampf(v, min_value, max_value)
		if is_instance_valid(_edit): _edit.text = _fmt(v)
		_updating = false; value_changed.emit(v)

	func _fmt(v: float) -> String:
		if step >= 1.0: return "%d" % int(v)
		elif step >= 0.1: return "%.1f" % v
		elif step >= 0.01: return "%.2f" % v
		else: return "%.4f" % v

	func set_value_no_signal(v: float) -> void:
		_updating = true
		value = v  # No clamping — allow any value
		if is_instance_valid(_slider): _slider.value = clampf(v, min_value, max_value)
		if is_instance_valid(_edit): _edit.text = _fmt(v)
		_updating = false

# ─── CompactSpin (used by spline sub-UI) ─────────────────────────────────────
class CompactSpin extends HBoxContainer:
	signal value_changed(v: float)
	var value:float=0.0; var min_value:float=-1e9; var max_value:float=1e9; var step:float=1.0
	var _edit:LineEdit=null
	func _get_minimum_size()->Vector2: return Vector2.ZERO
	func _ready()->void:
		var es := EditorInterface.get_editor_scale() if Engine.is_editor_hint() else 1.0
		add_theme_constant_override("separation",0)
		size_flags_horizontal=SIZE_EXPAND_FILL; size_flags_vertical=SIZE_SHRINK_CENTER
		custom_minimum_size=Vector2.ZERO
		_edit=LineEdit.new(); _edit.size_flags_horizontal=SIZE_EXPAND_FILL
		_edit.size_flags_vertical=SIZE_SHRINK_CENTER; _edit.custom_minimum_size=Vector2.ZERO
		_edit.add_theme_constant_override("minimum_character_width",1)
		_edit.text=_fmt(value)
		_edit.text_submitted.connect(_on_submitted); _edit.focus_exited.connect(_on_focus_exit)
		add_child(_edit)
		var col:=VBoxContainer.new(); col.size_flags_horizontal=SIZE_SHRINK_END
		col.size_flags_vertical=SIZE_SHRINK_CENTER; col.custom_minimum_size=Vector2(int(16*es),0)
		col.add_theme_constant_override("separation",0); add_child(col)
		for arrow in [["+",_step_up],["-",_step_down]]:
			var btn:=Button.new(); btn.text=arrow[0]; btn.flat=true
			btn.size_flags_vertical=SIZE_SHRINK_CENTER; btn.custom_minimum_size=Vector2(int(16*es),int(10*es))
			btn.pressed.connect(arrow[1] as Callable); col.add_child(btn)
	func _gui_input(event:InputEvent)->void:
		if event is InputEventMouseButton and (event as InputEventMouseButton).pressed:
			match (event as InputEventMouseButton).button_index:
				MOUSE_BUTTON_WHEEL_UP:  _step_up(); accept_event()
				MOUSE_BUTTON_WHEEL_DOWN:_step_down();accept_event()
	func _fmt(v:float)->String:
		var s:="%.4f"%v
		if "." in s: s=s.rstrip("0").rstrip(".")
		return s
	func _step_up()  ->void: _set_emit(snapped(value+step,step))
	func _step_down()->void: _set_emit(snapped(value-step,step))
	func _on_submitted(text:String)->void:
		# Allow any typed value — no clamping to min/max
		_set_emit(float(text))
		if is_instance_valid(_edit): _edit.release_focus()
	func _on_focus_exit()->void:
		_set_emit(float(_edit.text if is_instance_valid(_edit) else "0"))
	func _set_emit(v:float)->void:
		value=v; if is_instance_valid(_edit):_edit.text=_fmt(v); value_changed.emit(v)
	func set_value_no_signal(v:float)->void:
		value=v  # No clamping
		if is_instance_valid(_edit): _edit.text=_fmt(value)


# ─── State Variables ──────────────────────────────────────────────────────────
var placer:Node=null
var _es:float=1.0
var place_mode:int=1; var scroll_mode:int=0
var grid_enabled:bool=true; var grid_size:float=1.0
var grid_height:float=0.0; var height_offset:float=0.0
var height_snap:bool=false; var show_grid:bool=true
var align_to_normal:bool=false; var vertex_snap_mesh:bool=false
var vertex_snap_strength:float=42.0
var rotation_snap_mode:int=1; var custom_snap_deg:float=15.0
var random_rot:bool=false; var rrot_min:float=0.0; var rrot_max:float=360.0
var random_tilt:bool=false; var rtilt_min:float=-10.0; var rtilt_max:float=10.0
var uniform_scale:bool=true; var place_scale_all:float=1.0
var place_scale_x:float=1.0; var place_scale_y:float=1.0; var place_scale_z:float=1.0
var random_scale:bool=false; var rscale_min:float=0.8; var rscale_max:float=1.2
var paint_mode:bool=false; var paint_spacing:float=0.5
var paint_scatter:bool=false; var scatter_radius:float=0.5
var random_group_place:bool=false; var unpack_scenes:bool=false
var paint_as_brush:bool=false; var brush_radius:float=2.0
var brush_density:float=0.5; var brush_falloff:float=0.5
var brush_texture_path:String=""
var _active_spline_tool:Node=null
var multimesh_mode:bool=false; var mm_collision_enabled:bool=false
var parent_path:String=""; var parent_node:Node=null
var collision_enabled:bool=false; var collision_body_type:int=0
var collision_shape_type:int=0; var collision_auto_unpack:bool=true
var material_override_enabled:bool=false; var material_override_path:String=""
var material_override_mode:int=0
var import_formats:Array=ALL_FORMATS.duplicate()
var current_folder:String="res://"; var selected_path:String=""
var shortcuts:Dictionary={
	"rotate_y":KEY_R,"rotate_x":KEY_E,"rotate_z":KEY_Q,
	"scale_up":KEY_BRACKETRIGHT,"scale_down":KEY_BRACKETLEFT,
	"height_up":KEY_PAGEUP,"height_down":KEY_PAGEDOWN,
	"layer_up":KEY_HOME,"layer_down":KEY_END,
	"flip_x":KEY_G,"flip_z":KEY_B,"reset_rot":KEY_T,
}
var _preview_size:int=88; var _all_paths:Array=[]; var _groups:Array=[]
var _active_group:int=-1; var _is_placing:bool=false
var items_per_page:int=1000; var current_page:int=0
var _visible_paths_filtered:Array=[]
var _thumb_cache:Dictionary={}; var _thumb_lru:Array=[]
var _thumb_pending:Dictionary={}; var _thumb_heavy_count:int=0
var _thumb_perm_failed:Dictionary={}; var _card_ir_map:Dictionary={}
var _ir_path_map:Dictionary={}; var _thumb_retry_queue:Array=[]
var _thumb_retry_timer:float=0.0; var _thumb_check_timer:float=0.0
var _scan_dir_queue:Array=[]; var _is_scanning:bool=false
var _build_queue:Array=[]; var _visible_paths_ordered:Array=[]
var _multi_selected:Array=[]; var _last_clicked_path:String=""
var _selected_path_ui:String=""; var _card_map:Dictionary={}
var _browser_generation:int=0  # Increments on each rebuild; prevents stale thumbnail callbacks

var settings_ui:VBoxContainer=null; var browser_ui:VBoxContainer=null
var _search_panel:VBoxContainer=null; var _folder_edit:LineEdit=null
var _search_edit:LineEdit=null; var _asset_grid:GridContainer=null
var _asset_scroll:ScrollContainer=null; var _status_lbl:Label=null
var _stop_btn:Button=null; var _group_bar:FlowContainer=null
var _preview_lbl:Label=null; var _settings_tabs:TabContainer=null
var _mode_buttons:Array=[]; var _scroll_buttons:Array=[]
var _group_list_vbox:VBoxContainer=null; var _group_drop:OptionButton=null
var _multisel_bar:HBoxContainer=null; var _multisel_lbl:Label=null
var _multisel_group_opt:OptionButton=null
var _rot_x_spin:SliderSpin=null; var _rot_y_spin:SliderSpin=null; var _rot_z_spin:SliderSpin=null
var _grid_size_spin:SliderSpin=null; var _grid_h_spin:SliderSpin=null
var _height_spin:SliderSpin=null; var _scale_spin:SliderSpin=null
var _scale_x_spin:SliderSpin=null; var _scale_y_spin:SliderSpin=null; var _scale_z_spin:SliderSpin=null
var _custom_row:HBoxContainer=null; var _custom_spin:SliderSpin=null
var _xyz_box:VBoxContainer=null; var _rot_opt:OptionButton=null
var _parent_edit:LineEdit=null; var _col_warn_lbl:Label=null
var _mat_path_lbl:Label=null; var _mat_mode_opt:OptionButton=null
var _uni_scale_row:HBoxContainer=null; var _zoo_spacing_spin:SliderSpin=null
var _format_btns:Array=[]; var _vss_spin:SliderSpin=null; var _page_lbl:Label=null

var _zoo_show_labels:bool=true; var _zoo_paths_to_measure:Array=[]
var _zoo_items:Array=[]; var _zoo_node:Node3D=null
var _zoo_x_off:Array=[]; var _zoo_z_off:Array=[]
var _zoo_cols:int=1; var _zoo_index:int=0; var _zoo_is_building:bool=false
const ZOO_BATCH:=3; const ZOO_MEASURE_BATCH:=2
var _capturing_action:String=""; var _key_capture_btns:Dictionary={}

# ─── Offline Thumbnail Generator (for .tscn/.scn) ────────────────────────────
var _thumb_gen:Node=null                 # uap_thumb_gen.gd SubViewport instance
var _thumb_gen_ir_map:Dictionary={}      # path -> ir instance_id (for callback)

# ─── Spline Mode Management ───────────────────────────────────────────────────
var _prev_place_mode:int=1               # mode to restore when exiting spline
var _spline_mode_active:bool=false
var _spline_mode_lbl:Label=null          # status label inside Spline tab

func get_settings_ui() -> Control: return settings_ui
func get_browser_ui() -> Control: return browser_ui


# ─── Lifecycle ────────────────────────────────────────────────────────────────
func _ready()->void:
	if Engine.is_editor_hint(): _es=EditorInterface.get_editor_scale()
	_load_config(); _build_ui()
	await get_tree().process_frame; await get_tree().process_frame
	# ── Offline Scene Thumbnail Generator ─────────────────────────────────────
	if Engine.is_editor_hint():
		var tg_script = load("res://addons/ultimate_placer/uap_thumb_gen.gd")
		if tg_script != null:
			_thumb_gen = tg_script.new()
			_thumb_gen.name = "__UAPThumbGen__"
			add_child(_thumb_gen)
			_thumb_gen.thumbnail_ready.connect(_on_thumb_gen_ready)
	_scan_folder()

func _process(delta:float)->void:
	if _is_scanning: _tick_scan()
	if not _zoo_paths_to_measure.is_empty(): _tick_zoo_measure()
	if _zoo_is_building: _tick_zoo_build()
	var was_building := not _build_queue.is_empty()
	if was_building: _tick_build_queue()
	if was_building and _build_queue.is_empty(): _thumb_check_timer = 0.0
	if not _thumb_retry_queue.is_empty():
		_thumb_retry_timer -= delta
		if _thumb_retry_timer <= 0.0:
			_thumb_retry_timer = 0.5
			_process_thumb_retries()
	_thumb_check_timer -= delta
	if _thumb_check_timer <= 0.0:
		_thumb_check_timer = THUMB_INTERVAL
		_check_visible_thumbnails()

func _tick_build_queue()->void:
	var count := 0
	while not _build_queue.is_empty() and count < BUILD_BATCH:
		_add_card(_build_queue.pop_front() as String); count += 1
	if count > 0: _update_columns()
	if not _build_queue.is_empty():
		set_status("Building browser... %d / %d" % [_visible_paths_ordered.size()-_build_queue.size(), _visible_paths_ordered.size()], C_DIM)
	else:
		set_status("Loaded %d assets — click any to start placing" % _visible_paths_ordered.size(), C_OK)

func _tick_scan()->void:
	var count:=0
	while not _scan_dir_queue.is_empty() and count<SCAN_DIRS_FRAME:
		_scan_one_dir(_scan_dir_queue.pop_front() as String); count+=1
	if _scan_dir_queue.is_empty():
		_is_scanning=false; _on_scan_finished()
	else:
		set_status("Scanning... %d files, %d dirs left"%[_all_paths.size(),_scan_dir_queue.size()], C_DIM)

func _scan_one_dir(folder:String)->void:
	var da:=DirAccess.open(folder); if da==null: return
	da.list_dir_begin(); var fn:=da.get_next()
	while fn!="":
		if not fn.begins_with("."):
			var full:=folder.path_join(fn)
			if da.current_is_dir():
				if fn not in SKIP_DIRS: _scan_dir_queue.append(full)
			elif fn.get_extension().to_lower() in import_formats: _all_paths.append(full)
		fn=da.get_next()
	da.list_dir_end()

func _on_scan_finished()->void:
	var filter:=_search_edit.text if is_instance_valid(_search_edit) else ""
	_rebuild_browser(filter)
	set_status("Loaded %d assets — click any to start placing"%_all_paths.size(),C_OK)

func _is_heavy_format(path:String)->bool: return path.get_extension().to_lower() in HEAVY_PREVIEW_EXTS
func _can_preview_path(path:String)->bool: return path.get_extension().to_lower() in ALL_PREVIEW_EXTS

func _check_visible_thumbnails()->void:
	if not is_instance_valid(_asset_scroll): return
	var scroll_rect := _asset_scroll.get_global_rect()
	if scroll_rect.size.x <= 1.0 or scroll_rect.size.y <= 1.0: return
	var load_rect := scroll_rect.grow_side(SIDE_BOTTOM, float(_preview_size))

	# Count ONLY light-format pending to avoid tscn queue blocking GLB/GLTF dispatch
	var light_pending_count := 0
	for _v in _thumb_pending.values():
		if (_v as String) == "light": light_pending_count += 1

	var dispatched_light := 0

	for path in _visible_paths_ordered:
		if dispatched_light >= MAX_PER_TICK: break
		if _thumb_cache.has(path): continue
		if _thumb_pending.has(path): continue
		if _thumb_perm_failed.has(path): continue
		if not _can_preview_path(path): continue

		var ir := _card_ir_map.get(path, null) as TextureRect
		if not is_instance_valid(ir) or not ir.is_inside_tree(): continue
		if ir.size.x < 1.0 or ir.size.y < 1.0: continue
		if not load_rect.intersects(ir.get_global_rect()): continue

		var ir_id := ir.get_instance_id()
		var is_heavy := _is_heavy_format(path)

		if is_heavy:
			# ── TSCN / SCN: check disk cache first (may have been written ─────
			# by plugin.gd's scene-capture system OR a previous VP render)
			if _thumb_gen != null and _thumb_gen.has_disk_cache(path):
				var cached_tex: ImageTexture = _thumb_gen.load_disk_cache(path) as ImageTexture
				if cached_tex != null:
					_thumb_cache_set(path, cached_tex)
					_set_texture_safely(path, cached_tex, ir_id)
					continue
			if _thumb_gen == null: continue
			if _thumb_gen_ir_map.has(path): continue   # already queued in renderer
			_thumb_pending[path] = "heavy"
			_thumb_heavy_count += 1
			_thumb_gen_ir_map[path] = ir_id
			_thumb_gen.enqueue(path)
		else:
			# ── Light formats (.glb/.gltf/etc): EditorResourcePreview ─────────
			if light_pending_count >= MAX_PENDING: break
			_thumb_pending[path] = "light"
			light_pending_count += 1
			dispatched_light += 1
			EditorInterface.get_resource_previewer().queue_resource_preview(
				path, self, "_on_thumb_ready",
				{"path": path, "ir_id": ir_id, "gen": _browser_generation})

func _process_thumb_retries()->void:
	if _thumb_retry_queue.is_empty(): return
	var entry = _thumb_retry_queue.pop_front(); var ed = entry as Dictionary
	var path = ed["path"] as String; var ir_id = ed["ir_id"] as int
	var att = ed.get("attempts",0) as int; var gen = ed.get("gen", _browser_generation) as int
	if gen != _browser_generation: return
	var is_heavy = _is_heavy_format(path)
	# Heavy formats are handled by _thumb_gen — never retry via EditorResourcePreview
	if is_heavy:
		if _thumb_gen != null and not _thumb_gen_ir_map.has(path) and not _thumb_cache.has(path):
			_thumb_pending[path] = "heavy"; _thumb_heavy_count += 1
			_thumb_gen_ir_map[path] = ir_id; _thumb_gen.enqueue(path)
		return
	if MAX_THUMBNAIL_RETRIES != -1 and att >= MAX_THUMBNAIL_RETRIES:
		_thumb_perm_failed[path]=true; return
	if _thumb_cache.has(path): _set_texture_safely(path, _thumb_cache[path], ir_id); return
	_thumb_pending[path] = "light"
	EditorInterface.get_resource_previewer().queue_resource_preview(
		path, self, "_on_thumb_ready",
		{"path": path, "ir_id": ir_id, "attempts": att+1, "gen": gen})

func _on_thumb_ready(res_path:String, preview:Texture2D, small_preview:Texture2D, userdata:Variant)->void:
	var ud := userdata as Dictionary; if ud==null: return
	var req_path := ud.get("path",res_path) as String; var ir_id := ud.get("ir_id",0) as int
	var gen := ud.get("gen", _browser_generation) as int
	_thumb_pending.erase(req_path)
	# Discard callbacks from a previous browser generation (stale page/filter)
	if gen != _browser_generation: return
	var tex:Texture2D = preview if preview!=null else small_preview
	if tex!=null:
		_thumb_cache_set(req_path,tex); _set_texture_safely(req_path,tex,ir_id)
	else:
		_thumb_retry_queue.append({
			"path": req_path, "ir_id": ir_id,
			"attempts": ud.get("attempts",0) as int,
			"gen": gen
		})

# Called by uap_thumb_gen when a scene thumbnail is ready (from ERP or VP render)
func _on_thumb_gen_ready(path: String, tex: ImageTexture) -> void:
	var ir_id: int = _thumb_gen_ir_map.get(path, 0) as int
	_thumb_gen_ir_map.erase(path)
	_thumb_pending.erase(path)
	if _thumb_heavy_count > 0: _thumb_heavy_count -= 1

	if tex == null:
		# Could not render: 2D scene, broken deps, or non-3D root.
		# Mark permanent fail — no retry this session, no error output.
		_thumb_perm_failed[path] = true
		return

	_thumb_cache_set(path, tex)
	# Prefer live card-map lookup — ir_id may be stale if browser was rebuilt
	var ir := _card_ir_map.get(path, null) as TextureRect
	if is_instance_valid(ir):
		_set_texture_safely(path, tex, ir.get_instance_id())
	elif ir_id != 0:
		_set_texture_safely(path, tex, ir_id)

func _set_texture_safely(path:String, tex:Texture2D, ir_id:int)->void:
	var ir = instance_from_id(ir_id) as TextureRect
	if is_instance_valid(ir) and ir.get_meta("uap_path","") == path: ir.texture = tex

func _thumb_cache_set(path:String, tex:Texture2D)->void:
	if _thumb_cache.has(path): _thumb_lru.erase(path)
	_thumb_cache[path]=tex; _thumb_lru.append(path)
	while _thumb_lru.size()>THUMB_CACHE_MAX: _thumb_cache.erase(_thumb_lru.pop_front() as String)

func invalidate_thumb_cache(path: String) -> void:
	## Called by plugin.gd after a scene screenshot is saved to disk.
	## Removes the in-memory entry so the next visibility check reloads from disk.
	_thumb_cache.erase(path); _thumb_lru.erase(path)
	_thumb_perm_failed.erase(path)
	_thumb_pending.erase(path)
	_thumb_gen_ir_map.erase(path)
	# If this path is currently visible in the browser, reload immediately
	var ir := _card_ir_map.get(path, null) as TextureRect
	if not is_instance_valid(ir): return
	if _thumb_gen != null and _thumb_gen.has_disk_cache(path):
		var tex: ImageTexture = _thumb_gen.load_disk_cache(path) as ImageTexture
		if tex != null:
			_thumb_cache_set(path, tex)
			_set_texture_safely(path, tex, ir.get_instance_id())

func get_random_multi_selected_path()->String:
	if _multi_selected.size()>1:
		var valid:Array=[]
		for p in _multi_selected:
			if ResourceLoader.exists(p as String): valid.append(p)
		if not valid.is_empty(): return valid[randi()%valid.size()] as String
	return ""

func get_random_group_path()->String:
	var paths:Array=[]
	if _active_group==-2:
		for g in _groups:
			if (g as Dictionary)["name"]=="Favorites": paths=(g as Dictionary)["paths"] as Array; break
	elif _active_group>=0 and _active_group<_groups.size():
		paths=(_groups[_active_group] as Dictionary)["paths"] as Array
	if paths.is_empty(): return ""
	var valid:Array=[]
	for p in paths:
		if ResourceLoader.exists(p as String): valid.append(p)
	return "" if valid.is_empty() else valid[randi()%valid.size()] as String

func _input(event:InputEvent)->void:
	if not _capturing_action.is_empty() and event is InputEventKey:
		var ke:=event as InputEventKey; if not ke.pressed: return
		get_viewport().set_input_as_handled()
		if ke.keycode==KEY_ESCAPE:
			var ob:=_key_capture_btns.get(_capturing_action) as Button
			if is_instance_valid(ob): ob.text=_keycode_to_display(shortcuts.get(_capturing_action,KEY_NONE)); ob.remove_theme_color_override("font_color")
			_capturing_action=""; return
		shortcuts[_capturing_action]=ke.keycode
		var btn:=_key_capture_btns.get(_capturing_action) as Button
		if is_instance_valid(btn): btn.text=_keycode_to_display(ke.keycode); btn.remove_theme_color_override("font_color")
		_capturing_action=""; _save_config(); return
	if not event is InputEventMouseButton: return
	var mb:=event as InputEventMouseButton
	if not mb.ctrl_pressed or not mb.pressed: return
	if is_instance_valid(browser_ui) and not browser_ui.get_global_rect().has_point(mb.global_position): return
	if mb.button_index==MOUSE_BUTTON_WHEEL_UP: _set_preview_size(_preview_size+8); get_viewport().set_input_as_handled()
	elif mb.button_index==MOUSE_BUTTON_WHEEL_DOWN: _set_preview_size(_preview_size-8); get_viewport().set_input_as_handled()

func _set_preview_size(v:int)->void:
	_preview_size=clampi(v,int(54*_es),int(200*_es))
	if is_instance_valid(_preview_lbl): _preview_lbl.text="%dpx"%_preview_size
	_save_config(); _rebuild_browser_now()

func _update_columns()->void:
	if not is_instance_valid(_asset_grid) or not is_instance_valid(_asset_scroll): return
	var w:=_asset_scroll.size.x
	if w<20.0: w=browser_ui.size.x-4.0
	if w<20.0: w=180.0
	var cols:=maxi(1,int(w/float(_preview_size+6)))
	var n:=_asset_grid.get_child_count()
	if n>0: cols=mini(cols,n)
	_asset_grid.columns=cols


# ─── UI Helpers ───────────────────────────────────────────────────────────────
func _lbl(text:String, color:Color=C_TEXT)->Label:
	var l:=Label.new(); l.text=text; l.add_theme_color_override("font_color",color); return l

func _sep()->HSeparator: return HSeparator.new()

func _chk(val:bool, tip:String="")->CheckButton:
	var c:=CheckButton.new(); c.button_pressed=val; c.tooltip_text=tip; return c

func _info(parent:Node, text:String)->void:
	var l:=Label.new(); l.text=text; l.add_theme_color_override("font_color",C_DIM)
	l.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART; parent.add_child(l)

func _row(label:String, parent:Node, lw:int=90)->HBoxContainer:
	var row:=HBoxContainer.new(); row.add_theme_constant_override("separation",5)
	row.size_flags_horizontal=SIZE_EXPAND_FILL; row.custom_minimum_size=Vector2.ZERO
	var l:=Label.new(); l.text=label; l.add_theme_color_override("font_color",C_TEXT)
	l.size_flags_horizontal=SIZE_SHRINK_BEGIN; l.custom_minimum_size=Vector2(int(lw*_es),0); l.clip_text=true
	row.add_child(l); parent.add_child(row); return row

func _row_chk(label:String, parent:Node, val:bool, cb:Callable, tip:String="")->CheckButton:
	var row:=_row(label,parent); var c:=_chk(val,tip); c.toggled.connect(cb); row.add_child(c); return c

func _ss(lo:float, hi:float, val:float, step:float)->SliderSpin:
	var s:=SliderSpin.new(); s.min_value=lo; s.max_value=hi; s.value=val; s.step=step; return s

func _spin(lo:float, hi:float, val:float, step:float)->CompactSpin:
	var s:=CompactSpin.new(); s.min_value=lo; s.max_value=hi; s.value=val; s.step=step; return s

func _section(parent:VBoxContainer, title:String, open:bool=true)->VBoxContainer:
	var pc:=PanelContainer.new(); pc.size_flags_horizontal=SIZE_EXPAND_FILL
	var ps:=StyleBoxFlat.new(); ps.bg_color=Color(0.14,0.15,0.20); ps.set_corner_radius_all(4)
	ps.border_color=Color(C_ACCENT.r,C_ACCENT.g,C_ACCENT.b,0.20); ps.set_border_width_all(1)
	ps.set_content_margin_all(0); pc.add_theme_stylebox_override("panel",ps); parent.add_child(pc)
	var outer:=VBoxContainer.new(); outer.size_flags_horizontal=SIZE_EXPAND_FILL
	outer.add_theme_constant_override("separation",0); pc.add_child(outer)
	var hdr:=Button.new(); hdr.flat=true; hdr.alignment=HORIZONTAL_ALIGNMENT_LEFT
	hdr.size_flags_horizontal=SIZE_EXPAND_FILL
	hdr.text=("v  " if open else ">  ")+title
	hdr.add_theme_color_override("font_color",C_HEAD)
	var hs:=StyleBoxFlat.new(); hs.bg_color=Color(C_ACCENT.r,C_ACCENT.g,C_ACCENT.b,0.08)
	hs.set_corner_radius_all(0); hs.border_color=Color(C_ACCENT.r,C_ACCENT.g,C_ACCENT.b,0.20)
	hs.border_width_bottom=1; hs.set_content_margin_all(6)
	hdr.add_theme_stylebox_override("normal",hs); hdr.add_theme_stylebox_override("hover",hs)
	hdr.add_theme_stylebox_override("pressed",hs); outer.add_child(hdr)
	var wrap:=MarginContainer.new(); wrap.visible=open; wrap.size_flags_horizontal=SIZE_EXPAND_FILL
	for s in ["margin_left","margin_right","margin_top","margin_bottom"]: wrap.add_theme_constant_override(s,8)
	outer.add_child(wrap)
	var body:=VBoxContainer.new(); body.size_flags_horizontal=SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation",5); wrap.add_child(body)
	hdr.pressed.connect(func(): wrap.visible=not wrap.visible; hdr.text=("v  " if wrap.visible else ">  ")+title)
	return body

func _make_tab(n:String)->VBoxContainer:
	var sc:=ScrollContainer.new(); sc.name=n
	sc.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
	sc.size_flags_horizontal=SIZE_EXPAND_FILL; sc.size_flags_vertical=SIZE_EXPAND_FILL
	_settings_tabs.add_child(sc)
	var mg:=MarginContainer.new(); mg.size_flags_horizontal=SIZE_EXPAND_FILL
	for s in ["margin_left","margin_right","margin_top","margin_bottom"]: mg.add_theme_constant_override(s,6)
	sc.add_child(mg)
	var vb:=VBoxContainer.new(); vb.size_flags_horizontal=SIZE_EXPAND_FILL
	vb.add_theme_constant_override("separation",6); mg.add_child(vb); return vb

# ─── Main Build ───────────────────────────────────────────────────────────────
func _build_ui()->void:
	settings_ui=VBoxContainer.new(); settings_ui.name="UAP Settings"
	settings_ui.size_flags_horizontal=SIZE_EXPAND_FILL; settings_ui.size_flags_vertical=SIZE_EXPAND_FILL
	browser_ui=VBoxContainer.new(); browser_ui.name="UAP Browser"
	browser_ui.size_flags_horizontal=SIZE_EXPAND_FILL; browser_ui.size_flags_vertical=SIZE_EXPAND_FILL
	browser_ui.custom_minimum_size=Vector2(0, int(200*_es))
	_build_header(browser_ui); _build_browser_panel(browser_ui)
	_build_mode_bar(settings_ui); settings_ui.add_child(_sep()); _build_settings_panel(settings_ui)

func _build_header(root:VBoxContainer)->void:
	var hp:=PanelContainer.new(); hp.size_flags_horizontal=SIZE_EXPAND_FILL
	var hs:=StyleBoxFlat.new(); hs.bg_color=Color(0.09,0.10,0.14); hs.set_corner_radius_all(0)
	hs.set_content_margin_all(7); hs.border_color=C_ACCENT; hs.border_width_bottom=2
	hp.add_theme_stylebox_override("panel",hs); root.add_child(hp)
	var vb:=VBoxContainer.new(); vb.size_flags_horizontal=SIZE_EXPAND_FILL
	vb.clip_contents=true; vb.add_theme_constant_override("separation",5); hp.add_child(vb)
	var tr:=HBoxContainer.new(); tr.add_theme_constant_override("separation",6)
	tr.size_flags_horizontal=SIZE_EXPAND_FILL; vb.add_child(tr)
	var bar:=ColorRect.new(); bar.color=C_ACCENT; bar.custom_minimum_size=Vector2(3,0)
	bar.size_flags_vertical=SIZE_EXPAND_FILL; tr.add_child(bar)
	var tl:=Label.new(); tl.text="Ultimate Asset Placer"; tl.add_theme_color_override("font_color",C_HEAD)
	tl.size_flags_horizontal=SIZE_EXPAND_FILL; tl.clip_text=true; tr.add_child(tl)
	var ver:=Label.new(); ver.text=VERSION; ver.add_theme_color_override("font_color",C_DIM)
	ver.size_flags_horizontal=SIZE_SHRINK_END; tr.add_child(ver)
	var toggle_btn:=Button.new(); toggle_btn.text="v  Search & Filters"
	toggle_btn.toggle_mode=true; toggle_btn.button_pressed=true; toggle_btn.flat=true
	toggle_btn.alignment=HORIZONTAL_ALIGNMENT_LEFT; toggle_btn.size_flags_horizontal=SIZE_EXPAND_FILL
	toggle_btn.add_theme_color_override("font_color",C_ACCENT2); vb.add_child(toggle_btn)
	_search_panel=VBoxContainer.new(); _search_panel.size_flags_horizontal=SIZE_EXPAND_FILL
	_search_panel.add_theme_constant_override("separation",5); vb.add_child(_search_panel)
	toggle_btn.toggled.connect(func(v:bool):
		_search_panel.visible=v; toggle_btn.text=("v  " if v else ">  ")+"Search & Filters")
	var fr:=HBoxContainer.new(); fr.add_theme_constant_override("separation",3)
	fr.size_flags_horizontal=SIZE_EXPAND_FILL; fr.clip_contents=true; _search_panel.add_child(fr)
	var flbl:=Label.new(); flbl.text="Folder:"; flbl.custom_minimum_size=Vector2(int(44*_es),0)
	flbl.add_theme_color_override("font_color",C_DIM); fr.add_child(flbl)
	_folder_edit=LineEdit.new(); _folder_edit.text=current_folder
	_folder_edit.size_flags_horizontal=SIZE_EXPAND_FILL
	_folder_edit.text_submitted.connect(_on_folder_submitted); fr.add_child(_folder_edit)
	var brw:=Button.new(); brw.text="..."; brw.pressed.connect(_on_browse_pressed); fr.add_child(brw)
	var rfr:=Button.new(); rfr.text="Refresh"; rfr.tooltip_text="Refresh folder scan"
	rfr.pressed.connect(_scan_folder); fr.add_child(rfr)
	var sr:=HBoxContainer.new(); sr.add_theme_constant_override("separation",3)
	sr.size_flags_horizontal=SIZE_EXPAND_FILL; sr.clip_contents=true; _search_panel.add_child(sr)
	_search_edit=LineEdit.new(); _search_edit.placeholder_text="Search assets..."
	_search_edit.size_flags_horizontal=SIZE_EXPAND_FILL
	_search_edit.text_changed.connect(_on_search_changed); sr.add_child(_search_edit)
	_preview_lbl=Label.new(); _preview_lbl.text="%dpx"%_preview_size
	_preview_lbl.tooltip_text="Ctrl+Scroll to resize thumbnails"
	_preview_lbl.add_theme_color_override("font_color",C_DIM)
	_preview_lbl.size_flags_horizontal=SIZE_SHRINK_END; _preview_lbl.clip_text=true
	_preview_lbl.custom_minimum_size=Vector2.ZERO; sr.add_child(_preview_lbl)
	var clrb:=Button.new(); clrb.text="Clear"
	clrb.size_flags_horizontal=SIZE_SHRINK_END; clrb.pressed.connect(_on_clear_browser); sr.add_child(clrb)
	_group_bar=FlowContainer.new(); _group_bar.size_flags_horizontal=SIZE_EXPAND_FILL
	_group_bar.clip_contents=true; _group_bar.add_theme_constant_override("h_separation",2)
	_group_bar.add_theme_constant_override("v_separation",2); _search_panel.add_child(_group_bar)
	_rebuild_group_bar()
	_multisel_bar=HBoxContainer.new(); _multisel_bar.size_flags_horizontal=SIZE_EXPAND_FILL
	_multisel_bar.add_theme_constant_override("separation",4); _multisel_bar.visible=false; _search_panel.add_child(_multisel_bar)
	_multisel_lbl=Label.new(); _multisel_lbl.add_theme_color_override("font_color",C_MULTI)
	_multisel_lbl.size_flags_horizontal=SIZE_EXPAND_FILL; _multisel_bar.add_child(_multisel_lbl)
	_multisel_group_opt=OptionButton.new(); _multisel_group_opt.size_flags_horizontal=SIZE_EXPAND_FILL
	_multisel_group_opt.add_item("⭐ Favorites")
	for g in _groups: _multisel_group_opt.add_item((g as Dictionary)["name"])
	_multisel_bar.add_child(_multisel_group_opt)
	var asel:=Button.new(); asel.text="Add All"; asel.tooltip_text="Add all selected to chosen group"
	asel.pressed.connect(_on_add_multi_selected_to_group); _multisel_bar.add_child(asel)
	var rmsel:=Button.new(); rmsel.text="Remove"
	rmsel.add_theme_color_override("font_color",C_ERROR)
	rmsel.tooltip_text="Remove all selected assets from the current group\n(or from all groups if viewing All/search)"
	rmsel.pressed.connect(_on_smart_remove_from_group); _multisel_bar.add_child(rmsel)
	var csel:=Button.new(); csel.text="X"; csel.pressed.connect(_clear_multi_select); _multisel_bar.add_child(csel)

func _build_mode_bar(root:VBoxContainer)->void:
	var mp:=PanelContainer.new(); mp.size_flags_horizontal=SIZE_EXPAND_FILL
	var ms:=StyleBoxFlat.new(); ms.bg_color=Color(0.11,0.12,0.16)
	ms.border_color=C_BORDER; ms.border_width_bottom=1; ms.set_content_margin_all(6)
	mp.add_theme_stylebox_override("panel",ms); root.add_child(mp)
	var vb:=VBoxContainer.new(); vb.size_flags_horizontal=SIZE_EXPAND_FILL
	vb.clip_contents=true; vb.add_theme_constant_override("separation",5); mp.add_child(vb)
	var ml:=Label.new(); ml.text="PLACEMENT MODE"; ml.add_theme_color_override("font_color",C_DIM); vb.add_child(ml)
	var mf:=HBoxContainer.new(); mf.size_flags_horizontal=SIZE_EXPAND_FILL; mf.clip_contents=true
	mf.add_theme_constant_override("separation",3); vb.add_child(mf)
	_mode_buttons.clear()
	# Only show Free/Grid/Surface/Vertex buttons here — Spline is in its own tab
	for i in MODE_BUTTON_INDICES:
		var mi:int = i as int
		var btn:=Button.new(); btn.text=MODE_LABELS[mi]; btn.toggle_mode=true
		btn.tooltip_text=MODE_TIPS[mi]; btn.button_pressed=(mi==place_mode)
		btn.size_flags_horizontal=SIZE_EXPAND_FILL
		btn.pressed.connect(_on_mode_selected.bind(mi)); _mode_buttons.append(btn); mf.add_child(btn)
	_refresh_mode_buttons()
	vb.add_child(_sep())
	var sl:=Label.new(); sl.text="SCROLL WHEEL CONTROL"; sl.add_theme_color_override("font_color",C_DIM); vb.add_child(sl)
	var sf:=HBoxContainer.new(); sf.size_flags_horizontal=SIZE_EXPAND_FILL; sf.clip_contents=true
	sf.add_theme_constant_override("separation",3); vb.add_child(sf)
	_scroll_buttons.clear()
	for i in SCROLL_LABELS.size():
		var btn:=Button.new(); btn.text=SCROLL_LABELS[i]; btn.toggle_mode=true
		btn.button_pressed=(i==scroll_mode); btn.size_flags_horizontal=SIZE_EXPAND_FILL
		btn.pressed.connect(_on_scroll_mode_selected.bind(i)); _scroll_buttons.append(btn); sf.add_child(btn)
	_refresh_scroll_buttons()

func _build_browser_panel(root:VBoxContainer)->void:
	var stp:=PanelContainer.new(); stp.size_flags_horizontal=SIZE_EXPAND_FILL
	var ss:=StyleBoxFlat.new(); ss.bg_color=Color(0.08,0.09,0.12); ss.set_corner_radius_all(3)
	ss.set_content_margin_all(5); stp.add_theme_stylebox_override("panel",ss); root.add_child(stp)
	var str_r:=HBoxContainer.new(); str_r.add_theme_constant_override("separation",4)
	str_r.size_flags_horizontal=SIZE_EXPAND_FILL; str_r.clip_contents=true; stp.add_child(str_r)
	_status_lbl=Label.new(); _status_lbl.text="Click an asset to start placing"
	_status_lbl.size_flags_horizontal=SIZE_EXPAND_FILL
	_status_lbl.add_theme_color_override("font_color",C_OK); _status_lbl.clip_text=true; str_r.add_child(_status_lbl)
	_stop_btn=Button.new(); _stop_btn.text="Stop"; _stop_btn.disabled=true
	_stop_btn.size_flags_horizontal=SIZE_SHRINK_END; _stop_btn.pressed.connect(_on_stop_pressed); str_r.add_child(_stop_btn)
	var pg_wrap:=HBoxContainer.new(); pg_wrap.alignment=BoxContainer.ALIGNMENT_CENTER
	pg_wrap.size_flags_horizontal=SIZE_EXPAND_FILL
	var pb1:=Button.new(); pb1.text="<"; pb1.pressed.connect(_prev_page); pg_wrap.add_child(pb1)
	_page_lbl=Label.new(); _page_lbl.text="Page 1/1"; _page_lbl.custom_minimum_size=Vector2(int(80*_es),0)
	_page_lbl.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER; pg_wrap.add_child(_page_lbl)
	var pb2:=Button.new(); pb2.text=">"; pb2.pressed.connect(_next_page); pg_wrap.add_child(pb2)
	root.add_child(pg_wrap)
	_asset_scroll=ScrollContainer.new()
	_asset_scroll.size_flags_horizontal=SIZE_EXPAND_FILL; _asset_scroll.size_flags_vertical=SIZE_EXPAND_FILL
	_asset_scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
	_asset_scroll.clip_contents=true; _asset_scroll.custom_minimum_size=Vector2(0,int(60*_es))
	_asset_scroll.resized.connect(func(): call_deferred("_update_columns"))
	_asset_scroll.set_drag_forwarding(Callable(),_can_drop_asset_files,_drop_asset_files)
	_asset_scroll.get_v_scroll_bar().value_changed.connect(func(_v:float): _thumb_check_timer=0.0)
	root.add_child(_asset_scroll)
	_asset_grid=GridContainer.new(); _asset_grid.columns=3
	_asset_grid.size_flags_horizontal=SIZE_EXPAND_FILL
	_asset_grid.add_theme_constant_override("h_separation",5); _asset_grid.add_theme_constant_override("v_separation",5)
	_asset_scroll.add_child(_asset_grid)

func _build_settings_panel(root:VBoxContainer)->void:
	_settings_tabs=TabContainer.new(); _settings_tabs.size_flags_horizontal=SIZE_EXPAND_FILL
	_settings_tabs.size_flags_vertical=SIZE_EXPAND_FILL; _settings_tabs.clip_contents=true
	_settings_tabs.custom_minimum_size=Vector2(0,int(80*_es)); _settings_tabs.clip_tabs=true
	root.add_child(_settings_tabs)
	_build_place_tab(); _build_transform_tab(); _build_paint_tab()
	_build_spline_tab(); _build_material_tab(); _build_groups_tab()
	_build_keys_tab(); _build_collision_tab(); _build_docs_tab()


# ─── TABS ─────────────────────────────────────────────────────────────────────
func _build_place_tab()->void:
	var vb:=_make_tab("Place")
	var pc:=_section(vb,"Parent Node",false)
	_info(pc,"Placed assets will be children of this node.")
	var pr:=_row("Parent",pc)
	_parent_edit=LineEdit.new(); _parent_edit.placeholder_text="(scene root)"; _parent_edit.editable=false
	_parent_edit.size_flags_horizontal=SIZE_EXPAND_FILL; pr.add_child(_parent_edit)
	var pkb:=Button.new(); pkb.text="Pick"; pkb.pressed.connect(_on_pick_parent); pr.add_child(pkb)
	var clp:=Button.new(); clp.text="X"; clp.pressed.connect(_on_clear_parent); pr.add_child(clp)
	var us:=_section(vb,"Scene Settings")
	_row_chk("Unpack Scenes",us,unpack_scenes,func(v:bool):unpack_scenes=v;_save_config(),
		"If True, scene structure is fully visible in the tree.\nIf False, scenes remain packed instances.")
	var g:=_section(vb,"Grid & Snapping")
	_row_chk("Show Grid",g,show_grid,_on_show_grid_changed,"Show grid lines in 3D viewport")
	_row_chk("Snap to Grid",g,grid_enabled,_on_grid_enabled_changed,"Snap placement to grid XZ")
	var gsr:=_row("Grid Size",g); _grid_size_spin=_ss(0.0625,200.0,grid_size,0.0625)
	_grid_size_spin.value_changed.connect(_on_grid_size_changed); gsr.add_child(_grid_size_spin)
	var gml:=Label.new(); gml.text="m"; gml.add_theme_color_override("font_color",C_DIM); gsr.add_child(gml)
	var grb:=Button.new(); grb.text="1m"
	grb.pressed.connect(func(): grid_size=1.0; if is_instance_valid(_grid_size_spin):_grid_size_spin.set_value_no_signal(1.0); if is_instance_valid(placer):placer.call("rebuild_grid"); _save_config())
	gsr.add_child(grb)
	var ghr:=_row("Grid Y",g); _grid_h_spin=_ss(-100.0,100.0,grid_height,0.5)
	_grid_h_spin.value_changed.connect(_on_grid_h_changed); ghr.add_child(_grid_h_spin)
	var ld:=Button.new(); ld.text="v"; ld.pressed.connect(func(): nudge_grid_height(-grid_size)); ghr.add_child(ld)
	var lu:=Button.new(); lu.text="^"; lu.pressed.connect(func(): nudge_grid_height(grid_size)); ghr.add_child(lu)
	var h:=_section(vb,"Height Offset")
	var hor:=_row("Offset Y",h); _height_spin=_ss(-500.0,500.0,height_offset,0.05)
	_height_spin.value_changed.connect(_on_height_changed); hor.add_child(_height_spin)
	_row_chk("Snap Height",h,height_snap,_on_height_snap_changed,"Snap to Grid Size steps")
	var sv:=_section(vb,"Surface & Vertex Options",false)
	_row_chk("Align to Normal",sv,align_to_normal,_on_align_normal_changed,"Surface mode: tilt asset to surface normal.")
	_row_chk("Mesh Vertex Snap",sv,vertex_snap_mesh,_on_vertex_mesh_changed,"Vertex mode: test actual mesh vertices.")
	var vssr:=_row("Magnet px",sv); _vss_spin=_ss(5.0,300.0,vertex_snap_strength,1.0)
	_vss_spin.value_changed.connect(func(v:float): vertex_snap_strength=v;_save_config()); vssr.add_child(_vss_spin)
	var ff:=_section(vb,"Format Filter",false)
	_info(ff,"Choose which 3D formats to scan.")
	var fmt_flow:=FlowContainer.new(); fmt_flow.size_flags_horizontal=SIZE_EXPAND_FILL
	fmt_flow.add_theme_constant_override("h_separation",3); fmt_flow.add_theme_constant_override("v_separation",3); ff.add_child(fmt_flow)
	_format_btns.clear()
	for i in ALL_FORMATS.size():
		var ext:=ALL_FORMATS[i] as String; var fb:=Button.new(); fb.text=FORMAT_LABELS[i]
		fb.toggle_mode=true; fb.button_pressed=import_formats.has(ext); fb.tooltip_text="."+ext
		fb.pressed.connect(_on_format_toggled.bind(ext)); fmt_flow.add_child(fb); _format_btns.append(fb)
	var fr2:=HBoxContainer.new(); fr2.add_theme_constant_override("separation",4); ff.add_child(fr2)
	var allb:=Button.new(); allb.text="All On"
	allb.pressed.connect(func(): import_formats=ALL_FORMATS.duplicate(); for fb in _format_btns:(fb as Button).button_pressed=true; _scan_folder();_save_config())
	fr2.add_child(allb)
	var nonb:=Button.new(); nonb.text="All Off"
	nonb.pressed.connect(func(): import_formats.clear(); for fb in _format_btns:(fb as Button).button_pressed=false; _scan_folder();_save_config())
	fr2.add_child(nonb)
	var zoo:=_section(vb,"Asset Zoo",false)
	_info(zoo,"Lays out all loaded assets in a grid for inspection.")
	var zr:=HBoxContainer.new(); zr.add_theme_constant_override("separation",4); zoo.add_child(zr)
	var zb:=Button.new(); zb.text="Create Asset Zoo"; zb.size_flags_horizontal=SIZE_EXPAND_FILL
	zb.pressed.connect(_on_zoo_pressed); zr.add_child(zb)
	var zsp:=_row("Spacing",zoo); _zoo_spacing_spin=_ss(0.5,50.0,2.0,0.5); zsp.add_child(_zoo_spacing_spin)
	var zlr:=_row("Show Labels",zoo)
	var zlchk:=_chk(_zoo_show_labels,"Show floating Label3D names above each asset.")
	zlchk.toggled.connect(func(v:bool): _zoo_show_labels=v;_save_config()); zlr.add_child(zlchk)

func _build_transform_tab()->void:
	var vb:=_make_tab("Transform")
	var rot:=_section(vb,"Rotation Snap")
	var rmr:=_row("Snap Mode",rot); _rot_opt=OptionButton.new(); _rot_opt.size_flags_horizontal=SIZE_EXPAND_FILL
	for it in ["Free","90 deg","45 deg","15 deg","Custom"]: _rot_opt.add_item(it)
	_rot_opt.selected=rotation_snap_mode; _rot_opt.item_selected.connect(_on_rot_mode_changed); rmr.add_child(_rot_opt)
	_custom_row=_row("Custom deg",rot); _custom_row.visible=(rotation_snap_mode==4)
	_custom_spin=_ss(0.5,180.0,custom_snap_deg,0.5)
	_custom_spin.value_changed.connect(_on_custom_deg_changed); _custom_row.add_child(_custom_spin)
	var rv:=_section(vb,"Current Rotation")
	var xr:=_row("Rot X",rv); _rot_x_spin=_ss(-360.0,360.0,0.0,1.0); _rot_x_spin.value_changed.connect(_on_rot_x_changed); xr.add_child(_rot_x_spin)
	var yr:=_row("Rot Y",rv); _rot_y_spin=_ss(-360.0,360.0,0.0,1.0); _rot_y_spin.value_changed.connect(_on_rot_y_changed); yr.add_child(_rot_y_spin)
	var zr2:=_row("Rot Z",rv); _rot_z_spin=_ss(-360.0,360.0,0.0,1.0); _rot_z_spin.value_changed.connect(_on_rot_z_changed); zr2.add_child(_rot_z_spin)
	var rb2:=Button.new(); rb2.text="Reset X Y Z"; rb2.size_flags_horizontal=SIZE_EXPAND_FILL
	rb2.pressed.connect(func(): if is_instance_valid(placer):placer.call("apply_preset_orient",0.0,0.0,0.0)); rv.add_child(rb2)
	var oi:=_section(vb,"Quick Orient Presets",false)
	var of_:=FlowContainer.new(); of_.size_flags_horizontal=SIZE_EXPAND_FILL
	of_.add_theme_constant_override("h_separation",3); of_.add_theme_constant_override("v_separation",3); oi.add_child(of_)
	_orient_btn(of_,"Normal",0,0,0); _orient_btn(of_,"Upside Down",180,0,0)
	_orient_btn(of_,"Lay Fwd",90,0,0); _orient_btn(of_,"Lay Back",-90,0,0)
	_orient_btn(of_,"Tilt L",0,0,-90); _orient_btn(of_,"Tilt R",0,0,90)
	_orient_btn(of_,"Turn 90",0,90,0); _orient_btn(of_,"Turn 180",0,180,0)
	var rr:=_section(vb,"Random Rotation")
	_row_chk("Enable",rr,random_rot,_on_random_rot_changed)
	var rmnr:=_row("Min deg",rr); var rmins:=_ss(-360.0,360.0,rrot_min,1.0)
	rmins.value_changed.connect(func(v:float):rrot_min=v;_save_config()); rmnr.add_child(rmins)
	var rmxr:=_row("Max deg",rr); var rmaxs:=_ss(-360.0,360.0,rrot_max,1.0)
	rmaxs.value_changed.connect(func(v:float):rrot_max=v;_save_config()); rmxr.add_child(rmaxs)
	var rt:=_section(vb,"Random Tilt"); _info(rt,"Tilts X and Z randomly.")
	_row_chk("Enable",rt,random_tilt,func(v:bool):random_tilt=v;_save_config())
	var rtmr:=_row("+/- Max deg",rt); var rtms:=_ss(0.0,180.0,rtilt_max,0.5)
	rtms.value_changed.connect(func(v:float):rtilt_max=v;rtilt_min=-v;_save_config()); rtmr.add_child(rtms)
	var sc:=_section(vb,"Scale")
	var sp2:=FlowContainer.new(); sp2.size_flags_horizontal=SIZE_EXPAND_FILL
	sp2.add_theme_constant_override("h_separation",3); sp2.add_theme_constant_override("v_separation",3); sc.add_child(sp2)
	for pv:float in [0.25,0.5,1.0,1.5,2.0,3.0,5.0]:
		var pb:=Button.new(); var raw:="%.4f"%pv; raw=raw.rstrip("0").rstrip(".")
		pb.text="x"+raw; pb.pressed.connect(_apply_scale_preset.bind(pv)); sp2.add_child(pb)
	var unir:=_row("Uniform",sc); var unic:=_chk(uniform_scale); unic.toggled.connect(_on_uniform_toggled); unir.add_child(unic)
	var u2:=_row("Scale",sc); u2.visible=uniform_scale
	_scale_spin=_ss(0.01,20.0,place_scale_all,0.01); _scale_spin.value_changed.connect(_on_scale_all_changed)
	u2.add_child(_scale_spin); _uni_scale_row=u2
	_xyz_box=VBoxContainer.new(); _xyz_box.visible=not uniform_scale; _xyz_box.size_flags_horizontal=SIZE_EXPAND_FILL
	_xyz_box.add_theme_constant_override("separation",4); sc.add_child(_xyz_box)
	var sxr:=_row("X",_xyz_box); _scale_x_spin=_ss(0.01,20.0,place_scale_x,0.01); _scale_x_spin.value_changed.connect(_on_scale_x_changed); sxr.add_child(_scale_x_spin)
	var syr:=_row("Y",_xyz_box); _scale_y_spin=_ss(0.01,20.0,place_scale_y,0.01); _scale_y_spin.value_changed.connect(_on_scale_y_changed); syr.add_child(_scale_y_spin)
	var szr:=_row("Z",_xyz_box); _scale_z_spin=_ss(0.01,20.0,place_scale_z,0.01); _scale_z_spin.value_changed.connect(_on_scale_z_changed); szr.add_child(_scale_z_spin)
	var rs:=_section(vb,"Random Scale")
	_row_chk("Enable",rs,random_scale,_on_random_scale_changed)
	var rsmn:=_row("Min",rs); var rsmins:=_ss(0.01,20.0,rscale_min,0.01)
	rsmins.value_changed.connect(func(v:float):rscale_min=v;_save_config()); rsmn.add_child(rsmins)
	var rsmx:=_row("Max",rs); var rsmaxs:=_ss(0.01,20.0,rscale_max,0.01)
	rsmaxs.value_changed.connect(func(v:float):rscale_max=v;_save_config()); rsmx.add_child(rsmaxs)

func _orient_btn(parent:Container,label:String,rx:float,ry:float,rz:float)->void:
	var btn:=Button.new(); btn.text=label
	btn.pressed.connect(func(): if is_instance_valid(placer):placer.call("apply_preset_orient",rx,ry,rz)); parent.add_child(btn)

func _apply_scale_preset(v:float)->void:
	if uniform_scale:
		place_scale_all=v;place_scale_x=v;place_scale_y=v;place_scale_z=v
		if is_instance_valid(_scale_spin):_scale_spin.set_value_no_signal(v)
	else:
		place_scale_x=v;place_scale_y=v;place_scale_z=v
		if is_instance_valid(_scale_x_spin):_scale_x_spin.set_value_no_signal(v)
		if is_instance_valid(_scale_y_spin):_scale_y_spin.set_value_no_signal(v)
		if is_instance_valid(_scale_z_spin):_scale_z_spin.set_value_no_signal(v)
	_save_config()

func _build_paint_tab()->void:
	var vb:=_make_tab("Paint")
	var pm:=_section(vb,"Paint Mode")
	_row_chk("Enable Paint",pm,paint_mode,_on_paint_changed,"Hold LMB and drag to place continuously")
	var spr:=_row("Spacing",pm); var sps:=_ss(0.1,10.0,paint_spacing,0.05)
	sps.value_changed.connect(func(v:float):paint_spacing=v;_save_config()); spr.add_child(sps)
	_row_chk("Scatter",pm,paint_scatter,func(v:bool):paint_scatter=v;_save_config(),"Random XZ offset")
	var scr:=_row("Scatter R",pm); var scs:=_ss(0.01,50.0,scatter_radius,0.05)
	scs.value_changed.connect(func(v:float):scatter_radius=v;_save_config()); scr.add_child(scs)
	var br:=_section(vb,"Volumetric Brush",false)
	_info(br,"Replaces drag-painting with a volumetric ring brush. Assets scatter inside the circle.")
	var _br_row:=_row("Use Brush",br)
	var brchk:=_chk(paint_as_brush,"Use Brush instead of single-instance dragging")
	brchk.toggled.connect(func(v:bool): paint_as_brush=v;_save_config(); if is_instance_valid(placer):placer.call("refresh_ghosts"))
	_br_row.add_child(brchk)
	var rr:=_row("Radius m",br); var rs:=_ss(0.1,50.0,brush_radius,0.1)
	rs.value_changed.connect(_on_brush_radius_changed); rr.add_child(rs)
	var dr:=_row("Density",br); var ds:=_ss(0.05,10.0,brush_density,0.05)
	ds.value_changed.connect(func(v:float):brush_density=v;_save_config()); dr.add_child(ds)
	var ffr:=_row("Falloff",br); var fs:=_ss(0.0,1.0,brush_falloff,0.05)
	fs.value_changed.connect(func(v:float):brush_falloff=v;_save_config()); ffr.add_child(fs)
	var mpr:=_row("Mask Texture",br)
	var mlbl:=Label.new(); mlbl.text="(none)" if brush_texture_path.is_empty() else brush_texture_path.get_file()
	mlbl.size_flags_horizontal=SIZE_EXPAND_FILL; mlbl.add_theme_color_override("font_color",C_DIM); mlbl.clip_text=true; mpr.add_child(mlbl)
	var mpk:=Button.new(); mpk.text="Pick"
	mpk.pressed.connect(func():
		var dlg:=EditorFileDialog.new(); dlg.file_mode=EditorFileDialog.FILE_MODE_OPEN_FILE
		dlg.access=EditorFileDialog.ACCESS_RESOURCES
		dlg.filters=PackedStringArray(["*.png ; PNG Image","*.jpg ; JPG Image","*.webp ; WebP Image"])
		dlg.file_selected.connect(func(p:String): brush_texture_path=p;mlbl.text=p.get_file();_save_config(); if is_instance_valid(placer):placer.call("set_brush_texture_path",p))
		add_child(dlg); dlg.popup_centered(Vector2i(700,500)))
	mpr.add_child(mpk)
	var mclr:=Button.new(); mclr.text="X"
	mclr.pressed.connect(func(): brush_texture_path="";mlbl.text="(none)";_save_config(); if is_instance_valid(placer):placer.call("set_brush_texture_path",""))
	mpr.add_child(mclr)
	var rgp:=_section(vb,"Random Group Placer")
	var _rgp_row:=_row("Enable",rgp)
	var _rgp_chk:=_chk(random_group_place,"Random asset from active group per placement")
	_rgp_chk.toggled.connect(func(v:bool): random_group_place=v;_save_config(); if v and _active_group==-1:set_status("Activate a group in the browser bar first.",C_WARN))
	_rgp_row.add_child(_rgp_chk)
	_info(rgp,"If MULTIPLE items are selected in the browser, the brush will automatically random-paint those instead.")
	var mm:=_section(vb,"MultiMesh Painter",false)
	_row_chk("MultiMesh Mode",mm,multimesh_mode,_on_multimesh_toggled,"Paint multiple instances as one MultiMesh")
	_row_chk("Add Collision",mm,mm_collision_enabled,func(v:bool):mm_collision_enabled=v;_save_config())
	var mclr_btn:=Button.new(); mclr_btn.text="Clear All MultiMesh Instances"
	mclr_btn.size_flags_horizontal=SIZE_EXPAND_FILL; mclr_btn.pressed.connect(_on_mm_clear); mm.add_child(mclr_btn)
	var mcol:=Button.new(); mcol.text="Generate Instance Collision"
	mcol.size_flags_horizontal=SIZE_EXPAND_FILL; mcol.pressed.connect(_on_mm_generate_collision); mm.add_child(mcol)
	var mbk:=Button.new(); mbk.text="Commit MultiMesh"; mbk.size_flags_horizontal=SIZE_EXPAND_FILL
	mbk.pressed.connect(func(): if is_instance_valid(placer):placer.call("mm_commit_to_scene");set_status("MultiMesh committed.",C_OK))
	mm.add_child(mbk)

func _active_group_name()->String:
	if _active_group==-2: return "Favorites"
	if _active_group>=0 and _active_group<_groups.size(): return str((_groups[_active_group] as Dictionary)["name"])
	return "(no group active)"


func _build_spline_tab()->void:
	var vb:=_make_tab("Spline")
	# ── Mode status banner ────────────────────────────────────────────────────
	_spline_mode_lbl=Label.new()
	_spline_mode_lbl.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	_spline_mode_lbl.size_flags_horizontal=SIZE_EXPAND_FILL
	vb.add_child(_spline_mode_lbl)
	var exit_row:=HBoxContainer.new(); exit_row.add_theme_constant_override("separation",4); vb.add_child(exit_row)
	var exit_btn:=Button.new(); exit_btn.text="✕  Exit Spline Mode"; exit_btn.size_flags_horizontal=SIZE_EXPAND_FILL
	exit_btn.tooltip_text="Restore the previous placement mode and re-enable the ghost cursor."
	exit_btn.pressed.connect(_exit_spline_mode); exit_row.add_child(exit_btn)
	_update_spline_mode_label()
	vb.add_child(_sep())
	_info(vb,"Advanced Spline System: Draw a curve, then add meshes to it.\nUse Godot's built-in Path3D handles in the viewport to shape the curve.")
	vb.add_child(_sep())
	var cs_sec:=_section(vb,"1. Spline Node Setup")
	var btn_row1:=HBoxContainer.new()
	var csbtn:=Button.new(); csbtn.text="+ Create New Spline"; csbtn.size_flags_horizontal=SIZE_EXPAND_FILL
	csbtn.pressed.connect(_on_create_spline_node); btn_row1.add_child(csbtn)
	var selbtn:=Button.new(); selbtn.text="Use Selected Spline"; selbtn.size_flags_horizontal=SIZE_EXPAND_FILL
	selbtn.pressed.connect(_on_select_existing_spline); btn_row1.add_child(selbtn); cs_sec.add_child(btn_row1)
	var util_row:=HBoxContainer.new()
	var sm_btn:=Button.new(); sm_btn.text="Smooth"; sm_btn.size_flags_horizontal=SIZE_EXPAND_FILL
	sm_btn.pressed.connect(func(): if is_instance_valid(_active_spline_tool):_active_spline_tool.call("smooth_all_points"))
	var sh_btn:=Button.new(); sh_btn.text="Sharpen"; sh_btn.size_flags_horizontal=SIZE_EXPAND_FILL
	sh_btn.pressed.connect(func(): if is_instance_valid(_active_spline_tool):_active_spline_tool.call("sharpen_all_points"))
	util_row.add_child(sm_btn); util_row.add_child(sh_btn); cs_sec.add_child(util_row)
	var del_btn:=Button.new(); del_btn.text="Delete Active Spline"
	del_btn.add_theme_color_override("font_color",C_ERROR)
	del_btn.pressed.connect(_on_delete_active_spline); cs_sec.add_child(del_btn)
	vb.add_child(_sep())
	var ts:=_section(vb,"2. Terrain Snapping")
	_info(ts,"Requires physics collision below the spline.")
	var drop_btn:=Button.new(); drop_btn.text="Drop to Ground (Keep Shape)"
	drop_btn.tooltip_text="Moves the whole spline down so the lowest point touches the floor."
	drop_btn.pressed.connect(func(): if is_instance_valid(_active_spline_tool):_active_spline_tool.call("snap_lowest_to_ground")); ts.add_child(drop_btn)
	var conf_btn:=Button.new(); conf_btn.text="Wrap Points to Terrain"
	conf_btn.tooltip_text="Drops existing control points directly onto the collision surface."
	conf_btn.pressed.connect(func(): if is_instance_valid(_active_spline_tool):_active_spline_tool.call("conform_to_terrain")); ts.add_child(conf_btn)
	var conf2_btn:=Button.new(); conf2_btn.text="Subdivide & Wrap (Exact Shape)"
	conf2_btn.tooltip_text="Adds points every 1 meter and hugs hills and cliffs exactly."
	conf2_btn.pressed.connect(func(): if is_instance_valid(_active_spline_tool):_active_spline_tool.call("subdivide_and_conform")); ts.add_child(conf2_btn)
	vb.add_child(_sep())
	var lm:=_section(vb,"3. Layer Manager")
	var btn_row2:=HBoxContainer.new()
	var add_rep:=Button.new(); add_rep.text="+ Scatter (Props)"; add_rep.size_flags_horizontal=SIZE_EXPAND_FILL
	add_rep.pressed.connect(func(): _on_add_spline_layer(0)); btn_row2.add_child(add_rep)
	var add_str:=Button.new(); add_str.text="+ Deform (Roads)"; add_str.size_flags_horizontal=SIZE_EXPAND_FILL
	add_str.pressed.connect(func(): _on_add_spline_layer(1)); btn_row2.add_child(add_str); lm.add_child(btn_row2)
	var layer_vbox:=VBoxContainer.new(); layer_vbox.name="SplineLayerList"; lm.add_child(layer_vbox)
	vb.add_child(_sep())
	var uc:=_section(vb,"4. Bake to Scene",false)
	_info(uc,"Procedural Splines respawn objects if you delete them. To delete individual parts, you MUST BAKE the spline first!")
	var bake_btn:=Button.new(); bake_btn.text="BAKE TO NODES (Finalize)"
	bake_btn.custom_minimum_size=Vector2(0,int(40*_es)); bake_btn.add_theme_color_override("font_color",C_OK)
	bake_btn.pressed.connect(func():
		if is_instance_valid(_active_spline_tool):
			_active_spline_tool.call("bake_to_nodes"); _active_spline_tool=null
			_exit_spline_mode()
			_rebuild_spline_layer_ui(); set_status("Spline baked! You can now edit or delete individual pieces.",C_OK))
	uc.add_child(bake_btn)
	var bake_mm_btn:=Button.new(); bake_mm_btn.text="BAKE TO MULTIMESH (Performance)"
	bake_mm_btn.custom_minimum_size=Vector2(0,int(40*_es))
	bake_mm_btn.add_theme_color_override("font_color",C_ACCENT)
	bake_mm_btn.tooltip_text="Bakes scatter layers as MultiMeshInstance3D nodes instead of individual MeshInstance3D nodes. Ideal for grass, rocks, and any layer with many repeated instances. Deform layers are baked as a regular mesh."
	bake_mm_btn.pressed.connect(func():
		if is_instance_valid(_active_spline_tool):
			_active_spline_tool.call("bake_to_multimesh"); _active_spline_tool=null
			_exit_spline_mode()
			_rebuild_spline_layer_ui(); set_status("Spline baked as MultiMesh! Scatter layers are now MultiMeshInstance3D for best performance.",C_ACCENT))
	uc.add_child(bake_mm_btn)

# ─── Spline Mode Helpers ──────────────────────────────────────────────────────
func _enter_spline_mode()->void:
	if place_mode != 4: _prev_place_mode = place_mode
	place_mode = 4
	_spline_mode_active = true
	_refresh_mode_buttons()
	if is_instance_valid(placer): placer.call("refresh_ghosts"); placer.call("rebuild_grid")
	_update_spline_mode_label()

func _exit_spline_mode()->void:
	place_mode = _prev_place_mode
	_spline_mode_active = false
	_refresh_mode_buttons()
	if is_instance_valid(placer): placer.call("refresh_ghosts"); placer.call("rebuild_grid")
	_update_spline_mode_label()
	_save_config()

func _update_spline_mode_label()->void:
	if not is_instance_valid(_spline_mode_lbl): return
	if _spline_mode_active and is_instance_valid(_active_spline_tool):
		_spline_mode_lbl.text = "● SPLINE MODE ACTIVE  —  %s\nViewport LMB clicks edit the curve. Press 'Exit Spline Mode' to resume normal placement." % _active_spline_tool.name
		_spline_mode_lbl.add_theme_color_override("font_color",C_OK)
	elif _spline_mode_active:
		_spline_mode_lbl.text = "● Spline mode active but no spline node selected."
		_spline_mode_lbl.add_theme_color_override("font_color",C_WARN)
	else:
		_spline_mode_lbl.text = "○ No spline active  —  Create or select a spline below."
		_spline_mode_lbl.add_theme_color_override("font_color",C_DIM)

func _on_create_spline_node()->void:
	var root:=EditorInterface.get_edited_scene_root()
	if root==null or not root is Node3D: set_status("Open a 3D scene first.",C_WARN); return
	var script:=load("res://addons/ultimate_placer/uap_path.gd")
	if script==null: set_status("uap_path.gd not found.",C_ERROR); return
	var p3d:=Path3D.new()
	p3d.curve=Curve3D.new()
	# Assign a unique name BEFORE adding to tree to avoid Godot auto-naming (@NodeXXX)
	var base_name:="AdvancedSpline"; var candidate:=base_name; var n_idx:=1
	while (root as Node3D).has_node(candidate):
		n_idx+=1; candidate=base_name+"_%d"%n_idx
	p3d.name=candidate
	p3d.set_script(script)
	(root as Node3D).add_child(p3d); p3d.owner=root
	_active_spline_tool=p3d
	EditorInterface.get_selection().clear(); EditorInterface.get_selection().add_node(p3d)
	_enter_spline_mode()   # auto-activate mode 4 so the placer doesn't steal viewport clicks
	_rebuild_spline_layer_ui(); set_status("Advanced Spline created: "+p3d.name,C_OK)

func _delete_spline_node(node:Node)->void:
	if is_instance_valid(node): node.queue_free()
	if _active_spline_tool==node: _active_spline_tool=null
	_rebuild_spline_layer_ui()

func _on_select_existing_spline()->void:
	var sel:=EditorInterface.get_selection().get_selected_nodes()
	for n in sel:
		if n is Path3D and n.get_script()!=null:
			_active_spline_tool=n
			_enter_spline_mode()   # auto-activate mode 4
			_rebuild_spline_layer_ui()
			set_status("Active spline: "+n.name,C_OK); return
	set_status("Select a Path3D with UAPSplineTool script.",C_WARN)

func _on_add_spline_layer(ltype:int)->void:
	if not is_instance_valid(_active_spline_tool): return
	if selected_path.is_empty(): return
	_active_spline_tool.call("add_layer",ltype,selected_path); _rebuild_spline_layer_ui()

func _on_remove_spline_layer(idx:int)->void:
	if not is_instance_valid(_active_spline_tool): return
	_active_spline_tool.call("remove_layer",idx); _rebuild_spline_layer_ui()

func _on_spline_force_rebuild()->void:
	if not is_instance_valid(_active_spline_tool): return
	_active_spline_tool.call("force_rebuild")

func _on_delete_active_spline()->void:
	if not is_instance_valid(_active_spline_tool): return
	var node:=_active_spline_tool; _active_spline_tool=null
	node.queue_free()
	_exit_spline_mode()
	_rebuild_spline_layer_ui()

func _rebuild_spline_layer_ui()->void:
	_update_spline_mode_label()
	if not is_instance_valid(_settings_tabs): return
	var sc:Node=null
	for i in _settings_tabs.get_child_count():
		if _settings_tabs.get_child(i).name=="Spline": sc=_settings_tabs.get_child(i); break
	if sc==null: return
	var llv:=_find_node_named("SplineLayerList",sc); if llv==null: return
	for c in llv.get_children(): llv.remove_child(c); c.queue_free()
	if not is_instance_valid(_active_spline_tool): return
	var count:int=_active_spline_tool.l_type.size()
	for i in count:
		var type=_active_spline_tool.l_type[i]
		var label="Scatter: " if type==0 else "Deform: "
		var sec:=_section(llv,label+str(_active_spline_tool.l_mesh[i].get_file().get_basename()),false)
		_row_chk("Add Collision on Bake",sec,bool(_active_spline_tool.l_col_bake[i]),
			func(v:bool): _active_spline_tool.call("update_layer",i,"col_bake",v),
			"Generates accurate Trimesh StaticBody collisions automatically when you press Bake.")
		sec.add_child(HSeparator.new())
		if type==0:
			var mesh_row:=_row("Meshes",sec)
			var mesh_edit:=LineEdit.new(); mesh_edit.text=_active_spline_tool.l_mesh[i]
			mesh_edit.size_flags_horizontal=SIZE_EXPAND_FILL
			mesh_edit.text_submitted.connect(func(t:String): _active_spline_tool.call("update_layer",i,"mesh",t))
			mesh_row.add_child(mesh_edit)
			var add_btn:=Button.new(); add_btn.text="+ Add Selected"
			add_btn.pressed.connect(func():
				if selected_path.is_empty(): set_status("Select an asset in the browser first.",C_WARN); return
				var current=_active_spline_tool.l_mesh[i]
				_active_spline_tool.call("update_layer",i,"mesh",current+", "+selected_path); _rebuild_spline_layer_ui())
			mesh_row.add_child(add_btn)
			var sr2:=_row("Spacing",sec)
			var sv2:=_ss(0.1,100.0,float(_active_spline_tool.l_spacing[i]),0.1)
			sv2.value_changed.connect(func(v:float): _active_spline_tool.call("update_layer",i,"spacing",v)); sr2.add_child(sv2)
			_row_chk("Align to Curve",sec,bool(_active_spline_tool.l_align[i]),
				func(v:bool): _active_spline_tool.call("update_layer",i,"align",v))
			_row_chk("Use MultiMesh (Optimization)",sec,bool(_active_spline_tool.l_use_mm[i]),
				func(v:bool): _active_spline_tool.call("update_layer",i,"use_mm",v),
				"ON: Uses heavy optimization.\nOFF: Spawns individual mesh nodes so you can delete them before baking.")
			var yr2:=_row("Rnd Yaw deg",sec)
			var yv2:=_ss(0.0,180.0,float(_active_spline_tool.l_rnd_yaw[i]),1.0)
			yv2.value_changed.connect(func(v:float): _active_spline_tool.call("update_layer",i,"rnd_yaw",v)); yr2.add_child(yv2)
		if type==1:
			_row_chk("Invert Faces (Inside-Out)",sec,bool(_active_spline_tool.l_flip_faces[i]),
				func(v:bool): _active_spline_tool.call("update_layer",i,"flip_faces",v),
				"Check this if your road or track is facing backwards.")
		var scl_row:=_row("Scale X|Y|Z",sec)
		var scl=_active_spline_tool.l_scale[i] as Vector3
		var sx=_ss(0.01,10.0,scl.x,0.01); sx.value_changed.connect(func(v:float): _active_spline_tool.call("update_layer",i,"scale_x",v))
		var sy=_ss(0.01,10.0,scl.y,0.01); sy.value_changed.connect(func(v:float): _active_spline_tool.call("update_layer",i,"scale_y",v))
		var sz=_ss(0.01,10.0,scl.z,0.01); sz.value_changed.connect(func(v:float): _active_spline_tool.call("update_layer",i,"scale_z",v))
		scl_row.add_child(sx); scl_row.add_child(sy); scl_row.add_child(sz)
		var off_row:=_row("Offset X|Y|Z",sec)
		var off=_active_spline_tool.l_offset[i] as Vector3
		var ox=_ss(-50.0,50.0,off.x,0.1); ox.value_changed.connect(func(v:float): _active_spline_tool.call("update_layer",i,"offset_x",v))
		var oy=_ss(-50.0,50.0,off.y,0.1); oy.value_changed.connect(func(v:float): _active_spline_tool.call("update_layer",i,"offset_y",v))
		var oz=_ss(-50.0,50.0,off.z,0.1); oz.value_changed.connect(func(v:float): _active_spline_tool.call("update_layer",i,"offset_z",v))
		off_row.add_child(ox); off_row.add_child(oy); off_row.add_child(oz)
		if type==1:
			var uv_row:=_row("UV Tile X|Y",sec)
			var uv=_active_spline_tool.l_uv_tile[i] as Vector2
			var ux=_ss(0.01,50.0,uv.x,0.1); ux.value_changed.connect(func(v:float): _active_spline_tool.call("update_layer",i,"uv_x",v))
			var uy=_ss(0.01,50.0,uv.y,0.1); uy.value_changed.connect(func(v:float): _active_spline_tool.call("update_layer",i,"uv_y",v))
			uv_row.add_child(ux); uv_row.add_child(uy)
		var bot:=HBoxContainer.new()
		var rm:=Button.new(); rm.text="Remove Layer"
		rm.pressed.connect(func(): _active_spline_tool.call("remove_layer",i); _rebuild_spline_layer_ui()); bot.add_child(rm); sec.add_child(bot)

func _build_material_tab()->void:
	var vb:=_make_tab("Material")
	var mo:=_section(vb,"Material Override")
	_row_chk("Enable Override",mo,material_override_enabled,_on_mat_override_toggled,"Apply to all MeshInstances on place")
	var mr:=_row("Apply Mode",mo); _mat_mode_opt=OptionButton.new(); _mat_mode_opt.size_flags_horizontal=SIZE_EXPAND_FILL
	_mat_mode_opt.add_item("Replace"); _mat_mode_opt.add_item("Next Pass")
	_mat_mode_opt.selected=material_override_mode
	_mat_mode_opt.item_selected.connect(func(i:int):material_override_mode=i;_save_config()); mr.add_child(_mat_mode_opt)
	var mpr:=_row("Material",mo)
	_mat_path_lbl=Label.new(); _mat_path_lbl.text="(none)" if material_override_path.is_empty() else material_override_path.get_file()
	_mat_path_lbl.size_flags_horizontal=SIZE_EXPAND_FILL; _mat_path_lbl.add_theme_color_override("font_color",C_DIM); _mat_path_lbl.clip_text=true; mpr.add_child(_mat_path_lbl)
	var mpk:=Button.new(); mpk.text="Pick"; mpk.pressed.connect(_on_pick_material); mpr.add_child(mpk)
	var mcl:=Button.new(); mcl.text="X"; mcl.pressed.connect(_on_clear_material); mpr.add_child(mcl)

func _build_groups_tab()->void:
	var vb:=_make_tab("Groups")
	var ar:=HBoxContainer.new(); ar.add_theme_constant_override("separation",4); vb.add_child(ar)
	var ne:=LineEdit.new(); ne.placeholder_text="New group name..."; ne.size_flags_horizontal=SIZE_EXPAND_FILL; ar.add_child(ne)
	var ab:=Button.new(); ab.text="+ Add"; ab.pressed.connect(_on_add_group.bind(ne)); ar.add_child(ab)
	vb.add_child(_sep())
	_group_list_vbox=VBoxContainer.new(); _group_list_vbox.size_flags_horizontal=SIZE_EXPAND_FILL
	_group_list_vbox.add_theme_constant_override("separation",3); vb.add_child(_group_list_vbox); _rebuild_group_list()
	vb.add_child(_sep())
	# ── Add selected asset to a group ────────────────────────────────────────────
	var ator:=VBoxContainer.new(); ator.size_flags_horizontal=SIZE_EXPAND_FILL
	ator.add_theme_constant_override("separation",3); vb.add_child(ator)
	var ar2:=HBoxContainer.new(); ar2.add_theme_constant_override("separation",4)
	ar2.size_flags_horizontal=SIZE_EXPAND_FILL; ator.add_child(ar2)
	var go:=OptionButton.new(); go.size_flags_horizontal=SIZE_EXPAND_FILL; go.name="GroupDrop"
	go.add_item("⭐ Favorites")
	for g in _groups: go.add_item((g as Dictionary)["name"])
	ar2.add_child(go); _group_drop=go
	var gb:=Button.new(); gb.text="Add"; gb.pressed.connect(_on_add_to_group.bind(go)); ar2.add_child(gb)
	# ── Remove selected asset(s) from groups ─────────────────────────────────────
	# The remove system is smart: it detects which groups the selected asset(s) are
	# in automatically — no need to pick a group from a dropdown.
	# • When viewing a specific group: removes only from that group.
	# • When viewing All / Favorites / search: removes from every group they belong to.
	var rmr:=HBoxContainer.new(); rmr.add_theme_constant_override("separation",4)
	rmr.size_flags_horizontal=SIZE_EXPAND_FILL; ator.add_child(rmr)
	var rm_info:=Label.new(); rm_info.text="Remove selected:"
	rm_info.add_theme_color_override("font_color",C_DIM); rm_info.size_flags_horizontal=SIZE_EXPAND_FILL; rmr.add_child(rm_info)
	var rm_btn:=Button.new(); rm_btn.text="Remove from Group"
	rm_btn.add_theme_color_override("font_color",C_ERROR)
	rm_btn.tooltip_text="Removes selected asset(s) from the currently viewed group.\nIf viewing All or search, removes from every group they belong to.\nSupports multi-selection (Ctrl+Click / Shift+Click)."
	rm_btn.pressed.connect(_on_smart_remove_from_group); rmr.add_child(rm_btn)
	vb.add_child(_sep())
	# ── Import folder to group ────────────────────────────────────────────────────
	var imp:=_section(vb,"Import Folder to Group",false)
	var ir2:=HBoxContainer.new(); ir2.add_theme_constant_override("separation",4); imp.add_child(ir2)
	var igo:=OptionButton.new(); igo.size_flags_horizontal=SIZE_EXPAND_FILL; igo.name="ImpGroupDrop"
	igo.add_item("⭐ Favorites")
	for g in _groups: igo.add_item((g as Dictionary)["name"])
	ir2.add_child(igo)
	var ib:=Button.new(); ib.text="Browse..."; ib.pressed.connect(_on_import_folder_to_group.bind(igo)); ir2.add_child(ib)
	# ── Drag & Drop hint ────────────────────────────────────────────────────────
	vb.add_child(_sep())
	var dd_sec:=_section(vb,"Drag & Drop",false)
	_info(dd_sec,"Drag asset files from Godot's FileSystem panel directly onto the asset browser area.\n• If a named group or ⭐ Favorites is active, the dropped files are added to that group immediately — even if already in the browser.\n• Dropping onto All view adds files to the global browser only.")

func _on_smart_remove_from_group()->void:
	# Collect the paths to remove: multi-selected takes priority, then single selected.
	var targets:Array=[]
	if not _multi_selected.is_empty(): targets=_multi_selected.duplicate()
	elif not selected_path.is_empty(): targets=[selected_path]
	if targets.is_empty(): set_status("Select one or more assets first.",C_WARN); return

	var removed:int=0

	if _active_group==-2:
		# Viewing Favorites — remove from Favorites only.
		for g in _groups:
			if (g as Dictionary)["name"]=="Favorites":
				for p in targets:
					if (g as Dictionary)["paths"].has(p): (g as Dictionary)["paths"].erase(p); removed+=1
				break
	elif _active_group>=0 and _active_group<_groups.size():
		# Viewing a specific named group — remove only from that group.
		var gd:=_groups[_active_group] as Dictionary
		for p in targets:
			if gd["paths"].has(p): gd["paths"].erase(p); removed+=1
	else:
		# Viewing All or search results — remove from every group the asset is in.
		for g in _groups:
			for p in targets:
				if (g as Dictionary)["paths"].has(p): (g as Dictionary)["paths"].erase(p); removed+=1

	if removed>0:
		_save_config(); _rebuild_group_list(); _rebuild_group_bar()
		# Refresh the browser so removed assets disappear when inside a group view.
		if _active_group != -1: _rebuild_browser_now()
		var noun:="asset" if targets.size()==1 else "assets"
		set_status("Removed %d %s from group(s)." % [targets.size(), noun], C_OK)
		if not _multi_selected.is_empty(): _clear_multi_select()
	else:
		set_status("Selected asset(s) are not in any group.",C_WARN)

func _on_import_folder_to_group(opt:OptionButton)->void:
	var dlg:=EditorFileDialog.new(); dlg.file_mode=EditorFileDialog.FILE_MODE_OPEN_DIR
	dlg.access=EditorFileDialog.ACCESS_RESOURCES
	dlg.dir_selected.connect(_do_import_folder_to_group.bind(opt.selected))
	add_child(dlg); dlg.popup_centered(Vector2i(700,500))

func _do_import_folder_to_group(dir:String,group_idx:int)->void:
	var new_paths:Array=[]; _collect_files(dir,new_paths)
	if new_paths.is_empty(): set_status("No supported assets found in that folder.",C_WARN); return
	var added:=0
	if group_idx==0:
		for g in _groups:
			if (g as Dictionary)["name"]=="Favorites":
				for p in new_paths:
					if not (g as Dictionary)["paths"].has(p): (g as Dictionary)["paths"].append(p); added+=1
				break
	elif group_idx-1<_groups.size():
		var gd:=_groups[group_idx-1] as Dictionary
		for p in new_paths:
			if not gd["paths"].has(p): gd["paths"].append(p); added+=1
	var ba:=0
	for p in new_paths:
		if not _all_paths.has(p): _all_paths.append(p); ba+=1
	if ba>0: _rebuild_browser_now()
	_rebuild_group_list(); _rebuild_group_bar(); _save_config()
	set_status("Imported %d assets into group."%added,C_OK)

func _build_keys_tab()->void:
	var vb:=_make_tab("Keys")
	_key_capture_btns.clear()
	for action in SHORTCUT_LABELS.keys():
		var row:=_row(str(SHORTCUT_LABELS[action]),vb,130)
		var kbtn:=Button.new(); kbtn.size_flags_horizontal=SIZE_EXPAND_FILL
		kbtn.text=_keycode_to_display(shortcuts.get(action,KEY_NONE))
		var ac:=str(action); kbtn.pressed.connect(_on_capture_start.bind(ac))
		row.add_child(kbtn); _key_capture_btns[action]=kbtn
	vb.add_child(_sep())
	var rb:=Button.new(); rb.text="Reset All to Defaults"
	rb.size_flags_horizontal=SIZE_EXPAND_FILL; rb.pressed.connect(_on_reset_shortcuts); vb.add_child(rb)

func _build_collision_tab()->void:
	var vb:=_make_tab("Collision")
	var col:=_section(vb,"Auto Collision")
	_row_chk("Enable on Place",col,collision_enabled,_on_col_enabled_changed)
	var body:=_section(vb,"Body Type")
	var bo:=OptionButton.new(); bo.size_flags_horizontal=SIZE_EXPAND_FILL
	for it in ["StaticBody3D","RigidBody3D","CharacterBody3D","Area3D"]: bo.add_item(it)
	bo.selected=collision_body_type; bo.item_selected.connect(_on_col_body_changed); body.add_child(bo)
	var shp:=_section(vb,"Shape Type")
	var so:=OptionButton.new(); so.size_flags_horizontal=SIZE_EXPAND_FILL
	for it in ["Trimesh","Convex Hull","Box","Sphere","Capsule"]: so.add_item(it)
	so.selected=collision_shape_type; so.item_selected.connect(_on_col_shape_changed); shp.add_child(so)
	_col_warn_lbl=Label.new(); _col_warn_lbl.text="Warning: Trimesh invalid for dynamic bodies."
	_col_warn_lbl.add_theme_color_override("font_color",C_WARN)
	_col_warn_lbl.visible=_col_warn_needed(); shp.add_child(_col_warn_lbl)
	var fbx:=_section(vb,"FBX / GLTF Options",false)
	_row_chk("Auto-Unpack",fbx,collision_auto_unpack,func(v:bool):collision_auto_unpack=v;_save_config())

func _col_warn_needed()->bool: return collision_shape_type==0 and collision_body_type in [1,2]

func _build_docs_tab() -> void:
	var vb := _make_tab("📖 Docs")
	var rtl := RichTextLabel.new()
	rtl.bbcode_enabled = true
	rtl.fit_content = true
	rtl.scroll_active = false
	rtl.size_flags_horizontal = SIZE_EXPAND_FILL
	
	# Load the text cleanly from our external script
	var docs_script = preload("res://addons/ultimate_placer/uap_docs.gd")
	rtl.text = docs_script.get_manual_text()
	rtl.meta_underlined = true
	rtl.meta_clicked.connect(func(meta): OS.shell_open(str(meta)))
	
	vb.add_child(rtl)


# ─── Mode/Scroll refresh ──────────────────────────────────────────────────────
func _on_mode_selected(idx:int)->void:
	place_mode=idx; _refresh_mode_buttons()
	if is_instance_valid(placer):
		placer.call("refresh_ghosts"); placer.call("rebuild_grid")
		if _is_placing and not selected_path.is_empty(): placer.call("start_placement",selected_path)
	_save_config()

func _on_scroll_mode_selected(idx:int)->void: scroll_mode=idx; _refresh_scroll_buttons(); _save_config()

func _refresh_mode_buttons()->void:
	# _mode_buttons array aligns with MODE_BUTTON_INDICES (no Spline button)
	for b_idx in _mode_buttons.size():
		var mode_idx:int = MODE_BUTTON_INDICES[b_idx] as int
		var btn:=_mode_buttons[b_idx] as Button; if not is_instance_valid(btn): continue
		btn.button_pressed=(mode_idx==place_mode)
		if mode_idx==place_mode:
			var c:=MODE_COLORS[mode_idx] as Color
			btn.add_theme_color_override("font_color",c)
			var sb:=StyleBoxFlat.new(); sb.bg_color=Color(c.r,c.g,c.b,0.20); sb.set_corner_radius_all(3)
			sb.border_color=Color(c.r,c.g,c.b,0.70); sb.set_border_width_all(1); sb.set_content_margin_all(5)
			btn.add_theme_stylebox_override("normal",sb); btn.add_theme_stylebox_override("pressed",sb); btn.add_theme_stylebox_override("hover",sb)
		else:
			btn.remove_theme_color_override("font_color")
			btn.remove_theme_stylebox_override("normal"); btn.remove_theme_stylebox_override("pressed"); btn.remove_theme_stylebox_override("hover")

func _refresh_scroll_buttons()->void:
	for i in _scroll_buttons.size():
		var btn:=_scroll_buttons[i] as Button; if not is_instance_valid(btn): continue
		btn.button_pressed=(i==scroll_mode)
		if i==scroll_mode and i!=0:
			btn.add_theme_color_override("font_color",C_ACCENT)
			var sb:=StyleBoxFlat.new(); sb.bg_color=Color(C_ACCENT.r,C_ACCENT.g,C_ACCENT.b,0.18); sb.set_corner_radius_all(3)
			sb.border_color=Color(C_ACCENT.r,C_ACCENT.g,C_ACCENT.b,0.60); sb.set_border_width_all(1); sb.set_content_margin_all(5)
			btn.add_theme_stylebox_override("normal",sb); btn.add_theme_stylebox_override("pressed",sb); btn.add_theme_stylebox_override("hover",sb)
		else:
			btn.remove_theme_color_override("font_color")
			btn.remove_theme_stylebox_override("normal"); btn.remove_theme_stylebox_override("pressed"); btn.remove_theme_stylebox_override("hover")

# ─── Event Handlers ───────────────────────────────────────────────────────────
func _on_brush_radius_changed(v:float)->void:
	brush_radius=v; _save_config(); if is_instance_valid(placer):placer.call("set_brush_radius",v)

func _on_show_grid_changed(v:bool)->void: show_grid=v; if is_instance_valid(placer):placer.call("rebuild_grid"); _save_config()
func _on_grid_enabled_changed(v:bool)->void: grid_enabled=v; _save_config()
func _on_grid_size_changed(v:float)->void: grid_size=v; if is_instance_valid(placer):placer.call("rebuild_grid"); _save_config()
func _on_grid_h_changed(v:float)->void: grid_height=v; if is_instance_valid(placer):placer.call("rebuild_grid"); _save_config()
func _on_height_changed(v:float)->void: height_offset=v; _save_config()
func _on_height_snap_changed(v:bool)->void: height_snap=v; _save_config()
func _on_align_normal_changed(v:bool)->void: align_to_normal=v; _save_config(); if is_instance_valid(placer):placer.call("refresh_ghosts")
func _on_vertex_mesh_changed(v:bool)->void: vertex_snap_mesh=v; _save_config()
func _on_paint_changed(v:bool)->void: paint_mode=v; _save_config(); if is_instance_valid(placer):placer.call("refresh_ghosts")
func _on_multimesh_toggled(v:bool)->void: multimesh_mode=v; if not v and is_instance_valid(placer):placer.call("mm_commit_to_scene"); _save_config()
func _on_mm_clear()->void: if is_instance_valid(placer):placer.call("mm_clear"); set_status("MultiMesh cleared.",C_WARN)
func _on_mm_generate_collision()->void: if is_instance_valid(placer):placer.call("mm_generate_collision")
func _on_pick_parent()->void:
	var nodes:=EditorInterface.get_selection().get_selected_nodes()
	if nodes.is_empty(): set_status("Select a Node3D first.",C_WARN); return
	var n:=nodes[0] as Node; if not n is Node3D: set_status("Parent must be a Node3D.",C_WARN); return
	var root:=EditorInterface.get_edited_scene_root(); if n==root: _on_clear_parent(); return
	parent_node=n; parent_path=str(root.get_path_to(n))
	if is_instance_valid(_parent_edit): _parent_edit.text=n.name
	set_status("Parent: "+n.name,C_OK); _save_config()
func _on_clear_parent()->void:
	parent_node=null; parent_path=""
	if is_instance_valid(_parent_edit): _parent_edit.text=""; _parent_edit.placeholder_text="(scene root)"
	set_status("Parent cleared.",C_DIM); _save_config()
func _on_rot_mode_changed(idx:int)->void: rotation_snap_mode=idx; if is_instance_valid(_custom_row):_custom_row.visible=(idx==4); _save_config()
func _on_custom_deg_changed(v:float)->void: custom_snap_deg=v; _save_config()
func _on_random_rot_changed(v:bool)->void: random_rot=v; _save_config()
func _on_random_scale_changed(v:bool)->void: random_scale=v; _save_config()
func _on_rot_x_changed(v:float)->void:
	if is_instance_valid(placer): placer.call("set_rotation",v,_rot_y_spin.value if is_instance_valid(_rot_y_spin) else 0.0,_rot_z_spin.value if is_instance_valid(_rot_z_spin) else 0.0)
func _on_rot_y_changed(v:float)->void:
	if is_instance_valid(placer): placer.call("set_rotation",_rot_x_spin.value if is_instance_valid(_rot_x_spin) else 0.0,v,_rot_z_spin.value if is_instance_valid(_rot_z_spin) else 0.0)
func _on_rot_z_changed(v:float)->void:
	if is_instance_valid(placer): placer.call("set_rotation",_rot_x_spin.value if is_instance_valid(_rot_x_spin) else 0.0,_rot_y_spin.value if is_instance_valid(_rot_y_spin) else 0.0,v)
func _on_uniform_toggled(v:bool)->void:
	uniform_scale=v; if is_instance_valid(_uni_scale_row):_uni_scale_row.visible=v
	if is_instance_valid(_xyz_box):_xyz_box.visible=not v; _save_config()
func _on_scale_all_changed(v:float)->void: place_scale_all=v;place_scale_x=v;place_scale_y=v;place_scale_z=v;_save_config()
func _on_scale_x_changed(v:float)->void: place_scale_x=v;_save_config()
func _on_scale_y_changed(v:float)->void: place_scale_y=v;_save_config()
func _on_scale_z_changed(v:float)->void: place_scale_z=v;_save_config()
func _on_mat_override_toggled(v:bool)->void: material_override_enabled=v;_save_config()
func _on_pick_material()->void:
	var dlg:=EditorFileDialog.new(); dlg.file_mode=EditorFileDialog.FILE_MODE_OPEN_FILE
	dlg.access=EditorFileDialog.ACCESS_RESOURCES
	dlg.filters=PackedStringArray(["*.tres ; Material Resource","*.res ; Binary Resource"])
	dlg.file_selected.connect(_on_material_chosen); add_child(dlg); dlg.popup_centered(Vector2i(700,500))
func _on_material_chosen(path:String)->void:
	material_override_path=path; if is_instance_valid(_mat_path_lbl):_mat_path_lbl.text=path.get_file(); _save_config()
func _on_clear_material()->void:
	material_override_path=""; if is_instance_valid(_mat_path_lbl):_mat_path_lbl.text="(none)"; _save_config()
func _on_capture_start(action:String)->void:
	if not _capturing_action.is_empty():
		var ob:=_key_capture_btns.get(_capturing_action) as Button
		if is_instance_valid(ob): ob.text=_keycode_to_display(shortcuts.get(_capturing_action,KEY_NONE)); ob.remove_theme_color_override("font_color")
	_capturing_action=action
	var btn:=_key_capture_btns.get(action) as Button
	if is_instance_valid(btn): btn.text="[ press any key... ]"; btn.add_theme_color_override("font_color",C_WARN)
func _keycode_to_display(kc:int)->String: return "(none)" if kc==KEY_NONE or kc==0 else OS.get_keycode_string(kc)
func _on_reset_shortcuts()->void:
	shortcuts={"rotate_y":KEY_R,"rotate_x":KEY_E,"rotate_z":KEY_Q,"scale_up":KEY_BRACKETRIGHT,
		"scale_down":KEY_BRACKETLEFT,"height_up":KEY_PAGEUP,"height_down":KEY_PAGEDOWN,
		"layer_up":KEY_HOME,"layer_down":KEY_END,"flip_x":KEY_G,"flip_z":KEY_B,"reset_rot":KEY_T}
	_capturing_action=""
	for action in _key_capture_btns.keys():
		var btn:=_key_capture_btns[action] as Button
		if is_instance_valid(btn): btn.text=_keycode_to_display(shortcuts.get(action,KEY_NONE)); btn.remove_theme_color_override("font_color")
	_save_config()
func _on_col_enabled_changed(v:bool)->void: collision_enabled=v;_save_config()
func _on_col_body_changed(idx:int)->void: collision_body_type=idx; if is_instance_valid(_col_warn_lbl):_col_warn_lbl.visible=_col_warn_needed();_save_config()
func _on_col_shape_changed(idx:int)->void: collision_shape_type=idx; if is_instance_valid(_col_warn_lbl):_col_warn_lbl.visible=_col_warn_needed();_save_config()
func _on_folder_submitted(text:String)->void: current_folder=text;_save_config();_scan_folder()
func _on_browse_pressed()->void:
	var dlg:=EditorFileDialog.new(); dlg.file_mode=EditorFileDialog.FILE_MODE_OPEN_DIR
	dlg.access=EditorFileDialog.ACCESS_RESOURCES; dlg.dir_selected.connect(_on_dir_chosen)
	add_child(dlg); dlg.popup_centered(Vector2i(700,500))
func _on_dir_chosen(dir:String)->void:
	_is_scanning=false; _scan_dir_queue.clear()
	current_folder=dir; if is_instance_valid(_folder_edit):_folder_edit.text=dir; _save_config(); _scan_folder()
func _on_search_changed(text:String)->void: current_page=0; _rebuild_browser(text)

func _scan_folder()->void:
	_is_scanning=false; _scan_dir_queue.clear()
	_all_paths.clear(); _build_queue.clear()
	_thumb_pending.clear(); _ir_path_map.clear(); _card_ir_map.clear()
	_thumb_retry_queue.clear(); _thumb_perm_failed.clear(); _thumb_heavy_count=0
	_scan_dir_queue=[current_folder]; _is_scanning=true; set_status("Scanning...",C_DIM)

func _on_clear_browser()->void:
	if is_instance_valid(placer):placer.call("cancel_placement")
	_is_scanning=false; _scan_dir_queue.clear()
	_all_paths.clear(); _build_queue.clear()
	_thumb_pending.clear(); _thumb_cache.clear(); _thumb_lru.clear()
	_ir_path_map.clear(); _card_ir_map.clear()
	_thumb_retry_queue.clear(); _thumb_perm_failed.clear(); _thumb_heavy_count=0
	if is_instance_valid(_search_edit): _search_edit.text=""
	_rebuild_browser(""); set_status("Browser cleared.",C_DIM); _save_config()

func _merge_extra_paths(extras:Array)->void:
	for p in extras:
		if ResourceLoader.exists(p) and not _all_paths.has(p): _all_paths.append(p)
	if not extras.is_empty(): _rebuild_browser_now()

func _collect_files(folder:String,out:Array)->void:
	var da:=DirAccess.open(folder); if da==null: return
	da.list_dir_begin(); var fn:=da.get_next()
	while fn!="":
		if not fn.begins_with("."):
			var full:=folder.path_join(fn)
			if da.current_is_dir():
				if fn not in SKIP_DIRS: _collect_files(full,out)
			elif fn.get_extension().to_lower() in import_formats: out.append(full)
		fn=da.get_next()
	da.list_dir_end()

const _DRAG_EXTS:=["glb","gltf","fbx","obj","dae","blend","tscn","scn","res","mesh"]

func _can_drop_asset_files(_at:Vector2,data:Variant)->bool:
	if not data is Dictionary or not (data as Dictionary).has("files"): return false
	for f in (data as Dictionary)["files"] as Array:
		if (f as String).get_extension().to_lower() in _DRAG_EXTS: return true
	return false

func _drop_asset_files(_at:Vector2,data:Variant)->void:
	if not data is Dictionary: return
	var files:=(data as Dictionary).get("files",[]) as Array
	var globally_added:=0      # files newly added to the global _all_paths list
	var group_added:=0         # files newly added to the active group
	var group_paths:Array=[]   # files eligible to add to the active group

	for f in files:
		var fs:=f as String
		if not fs.get_extension().to_lower() in _DRAG_EXTS: continue
		# Always collect for potential group membership regardless of global presence.
		group_paths.append(fs)
		if not _all_paths.has(fs):
			_all_paths.append(fs); globally_added+=1

	# Add to active group — this runs even for files already in _all_paths.
	if _active_group==-2:
		for g in _groups:
			if (g as Dictionary)["name"]=="Favorites":
				for p in group_paths:
					if not (g as Dictionary)["paths"].has(p): (g as Dictionary)["paths"].append(p); group_added+=1
				break
	elif _active_group>=0 and _active_group<_groups.size():
		var gd:=_groups[_active_group] as Dictionary
		for p in group_paths:
			if not gd["paths"].has(p): gd["paths"].append(p); group_added+=1

	var total:=maxi(globally_added, group_added)
	if total>0 or group_added>0:
		var filter:=_search_edit.text if is_instance_valid(_search_edit) else ""
		_rebuild_browser(filter); _rebuild_group_list(); _rebuild_group_bar()
		_save_config()
		if group_added>0 and globally_added==0:
			set_status("Added %d asset(s) to group." % group_added, C_OK)
		elif group_added>0:
			set_status("Added %d asset(s) to browser and group." % group_added, C_OK)
		else:
			set_status("Added %d asset(s) to browser." % globally_added, C_OK)
	elif not group_paths.is_empty():
		set_status("Asset(s) already in the current group.",C_DIM)

func _prev_page()->void:
	if current_page>0: current_page-=1; _rebuild_browser_now()

func _next_page()->void:
	var total_pages=int(max(1,ceil(_visible_paths_filtered.size()/float(items_per_page))))
	if current_page<total_pages-1: current_page+=1; _rebuild_browser_now()

func _rebuild_browser_now()->void:
	_rebuild_browser(_search_edit.text if is_instance_valid(_search_edit) else "")

func _rebuild_browser(filter:String)->void:
	if not is_instance_valid(_asset_grid): return
	# Increment generation — all in-flight thumbnail callbacks from the previous
	# browser layout will see a mismatched generation and discard themselves safely.
	_browser_generation += 1
	_build_queue.clear(); _thumb_pending.clear(); _thumb_retry_queue.clear()
	_thumb_check_timer=THUMB_INTERVAL; _thumb_heavy_count=0
	# Clear offline renderer queue — paths from the old page are no longer visible
	_thumb_gen_ir_map.clear()
	if _thumb_gen != null: _thumb_gen.clear_queue()
	for c in _asset_grid.get_children(): _asset_grid.remove_child(c); c.queue_free()
	_card_map.clear(); _card_ir_map.clear(); _ir_path_map.clear()
	_selected_path_ui=""
	_visible_paths_filtered=_filtered_paths(filter)
	var total_pages=int(max(1,ceil(_visible_paths_filtered.size()/float(items_per_page))))
	current_page=clampi(current_page,0,total_pages-1)
	var start_idx=current_page*items_per_page
	var end_idx=mini(start_idx+items_per_page,_visible_paths_filtered.size())
	_visible_paths_ordered=_visible_paths_filtered.slice(start_idx,end_idx)
	if is_instance_valid(_page_lbl): _page_lbl.text="Page %d/%d"%[(current_page+1),total_pages]
	_build_queue=_visible_paths_ordered.duplicate()
	call_deferred("_update_columns")

func _filtered_paths(filter:String)->Array:
	var base:=_all_paths
	if _active_group==-2:
		for g in _groups:
			if (g as Dictionary)["name"]=="Favorites": base=(g as Dictionary)["paths"] as Array; break
	elif _active_group>=0 and _active_group<_groups.size():
		base=(_groups[_active_group] as Dictionary)["paths"] as Array
	if filter.strip_edges().is_empty(): return base
	var lf:=filter.to_lower(); var result:Array=[]
	for p in base:
		if (p as String).get_file().to_lower().contains(lf): result.append(p)
	return result

func _add_card(path:String)->void:
	var card:=PanelContainer.new()
	card.custom_minimum_size=Vector2(_preview_size,_preview_size+20)
	card.mouse_filter=Control.MOUSE_FILTER_STOP
	var normal_style:=StyleBoxFlat.new(); normal_style.bg_color=C_CARD_BG
	normal_style.set_corner_radius_all(5); normal_style.set_border_width_all(1)
	normal_style.border_color=C_CARD_BD; card.add_theme_stylebox_override("panel",normal_style)
	var vb:=VBoxContainer.new(); vb.add_theme_constant_override("separation",2)
	vb.mouse_filter=Control.MOUSE_FILTER_IGNORE; card.add_child(vb)
	var ir:=TextureRect.new(); ir.custom_minimum_size=Vector2(_preview_size-4,_preview_size-4)
	ir.expand_mode=TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	ir.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	ir.mouse_filter=Control.MOUSE_FILTER_IGNORE; vb.add_child(ir)
	ir.set_meta("uap_path",path)
	_card_ir_map[path]=ir; _ir_path_map[ir.get_instance_id()]=path
	if _thumb_cache.has(path): ir.texture=_thumb_cache[path] as Texture2D
	else:
		var fb:=_fallback_icon(path); if fb!=null: ir.texture=fb
	var nl:=Label.new(); nl.text=path.get_file().get_basename(); nl.clip_text=true
	nl.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	nl.mouse_filter=Control.MOUSE_FILTER_IGNORE; vb.add_child(nl)
	card.tooltip_text=path
	var ext2:=path.get_extension().to_lower()
	if (ext2=="tscn" or ext2=="scn"):
		var opened_root:=EditorInterface.get_edited_scene_root()
		if is_instance_valid(opened_root) and opened_root.scene_file_path==path:
			var open_style:=StyleBoxFlat.new()
			open_style.bg_color=Color(0.30,0.15,0.05,1.0)
			open_style.set_corner_radius_all(5); open_style.set_border_width_all(2)
			open_style.border_color=C_WARN; card.add_theme_stylebox_override("panel",open_style)
			card.tooltip_text=path+"\nCurrently open — cannot place inside itself."
			var wl:=Label.new(); wl.text="Open"; wl.add_theme_color_override("font_color",C_WARN)
			wl.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER; wl.mouse_filter=Control.MOUSE_FILTER_IGNORE; vb.add_child(wl)
	if _multi_selected.has(path):
		var ms:=StyleBoxFlat.new(); ms.bg_color=Color(C_MULTI.r,C_MULTI.g,C_MULTI.b,0.18)
		ms.set_corner_radius_all(5); ms.set_border_width_all(2); ms.border_color=C_MULTI
		card.add_theme_stylebox_override("panel",ms)
	var card_path:=path
	card.gui_input.connect(func(ev:InputEvent):
		if not ev is InputEventMouseButton: return
		var mb:=ev as InputEventMouseButton
		if mb.button_index==MOUSE_BUTTON_LEFT and mb.pressed:
			if mb.ctrl_pressed: _toggle_multi_select(card_path,card)
			elif mb.shift_pressed: _range_select(card_path)
			else: _clear_multi_select(); _select_card(card_path,card,normal_style))
	_card_map[path]=card; _asset_grid.add_child(card)

func _fallback_icon(path:String)->Texture2D:
	var theme:=EditorInterface.get_editor_theme(); if theme==null: return null
	var ext:=path.get_extension().to_lower(); var icon_name:String
	match ext:
		"tscn","scn":             icon_name="PackedScene"
		"glb","gltf","fbx","dae": icon_name="MeshInstance3D"
		"blend":                  icon_name="MeshInstance3D"
		"obj","mesh":             icon_name="Mesh"
		"res":                    icon_name="Resource"
		_:                        icon_name="Object"
	for candidate in [icon_name,"MeshInstance3D","Object","Node"]:
		if theme.has_icon(candidate,"EditorIcons"): return theme.get_icon(candidate,"EditorIcons")
	return null

func _select_card(path:String,card:PanelContainer,normal_style:StyleBoxFlat)->void:
	if not ResourceLoader.exists(path):
		set_status("File not found: "+path.get_file()+" — refresh the browser.",C_ERROR); return
	var ext:=path.get_extension().to_lower()
	if ext=="tscn" or ext=="scn":
		var root:=EditorInterface.get_edited_scene_root()
		if is_instance_valid(root):
			var open_path:=root.scene_file_path
			if not open_path.is_empty() and open_path==path:
				set_status("This scene is currently open — cannot place it inside itself.",C_WARN); return
	if not _selected_path_ui.is_empty() and _card_map.has(_selected_path_ui):
		var prev:=_card_map[_selected_path_ui] as PanelContainer
		if is_instance_valid(prev) and prev!=card:
			var ns:=StyleBoxFlat.new(); ns.bg_color=C_CARD_BG; ns.set_corner_radius_all(5)
			ns.set_border_width_all(1); ns.border_color=C_CARD_BD; prev.add_theme_stylebox_override("panel",ns)
	selected_path=path; _selected_path_ui=path; _last_clicked_path=path
	var sel:=StyleBoxFlat.new(); sel.bg_color=C_CARD_BG.lerp(C_SEL_BD,0.18)
	sel.set_corner_radius_all(5); sel.set_border_width_all(2); sel.border_color=C_SEL_BD
	card.add_theme_stylebox_override("panel",sel)
	var root:=EditorInterface.get_edited_scene_root()
	if root==null or not root is Node3D:
		set_status("Open a 3D scene first to start placing assets.",C_WARN); return
	if is_instance_valid(placer):placer.call("start_placement",path)
	_is_placing=true
	if is_instance_valid(_stop_btn):_stop_btn.disabled=false
	set_status("Placing: "+path.get_file().get_basename()+"   |   RMB / ESC = cancel",C_PLACING)

func _toggle_multi_select(path:String,card:PanelContainer)->void:
	if _multi_selected.has(path):
		_multi_selected.erase(path)
		var ns:=StyleBoxFlat.new(); ns.bg_color=C_CARD_BG; ns.set_corner_radius_all(5); ns.set_border_width_all(1); ns.border_color=C_CARD_BD; card.add_theme_stylebox_override("panel",ns)
	else:
		_multi_selected.append(path); _last_clicked_path=path
		var ms:=StyleBoxFlat.new(); ms.bg_color=Color(C_MULTI.r,C_MULTI.g,C_MULTI.b,0.18)
		ms.set_corner_radius_all(5); ms.set_border_width_all(2); ms.border_color=C_MULTI
		card.add_theme_stylebox_override("panel",ms)
	_update_multi_select_bar()

func _range_select(path:String)->void:
	if _last_clicked_path.is_empty() or not _visible_paths_ordered.has(_last_clicked_path): _last_clicked_path=path
	var a:=_visible_paths_ordered.find(_last_clicked_path); var b:=_visible_paths_ordered.find(path)
	if a<0 or b<0: return
	if a>b: var tmp:=a; a=b; b=tmp
	for i in range(a,b+1):
		var p:=_visible_paths_ordered[i] as String
		if not _multi_selected.has(p): _multi_selected.append(p)
		var c:=_card_map.get(p,null) as PanelContainer
		if is_instance_valid(c):
			var ms:=StyleBoxFlat.new(); ms.bg_color=Color(C_MULTI.r,C_MULTI.g,C_MULTI.b,0.18)
			ms.set_corner_radius_all(5); ms.set_border_width_all(2); ms.border_color=C_MULTI
			c.add_theme_stylebox_override("panel",ms)
	_update_multi_select_bar()

func _clear_multi_select()->void:
	for path in _multi_selected:
		var c:=_card_map.get(path,null) as PanelContainer
		if is_instance_valid(c) and path!=_selected_path_ui:
			var ns:=StyleBoxFlat.new(); ns.bg_color=C_CARD_BG; ns.set_corner_radius_all(5); ns.set_border_width_all(1); ns.border_color=C_CARD_BD; c.add_theme_stylebox_override("panel",ns)
	_multi_selected.clear(); _update_multi_select_bar()

func _update_multi_select_bar()->void:
	if not is_instance_valid(_multisel_bar): return
	_multisel_bar.visible=(_multi_selected.size()>0)
	if is_instance_valid(_multisel_lbl): _multisel_lbl.text="%d selected"%_multi_selected.size()

func _on_add_multi_selected_to_group()->void:
	if _multi_selected.is_empty(): set_status("No assets selected.",C_WARN); return
	if not is_instance_valid(_multisel_group_opt): return
	var idx:=_multisel_group_opt.selected; var added:=0
	if idx==0:
		# Favorites is a built-in slot — find its _groups entry but never create a new one.
		for g in _groups:
			if (g as Dictionary)["name"]=="Favorites":
				for p in _multi_selected:
					if not (g as Dictionary)["paths"].has(p): (g as Dictionary)["paths"].append(p); added+=1
				break
	elif idx-1<_groups.size():
		var gd:=_groups[idx-1] as Dictionary
		for p in _multi_selected:
			if not gd["paths"].has(p): gd["paths"].append(p); added+=1
	_rebuild_group_list(); _rebuild_group_bar(); _save_config()
	set_status("Added %d assets to group."%added,C_OK); _clear_multi_select()

func _on_stop_pressed()->void:
	if is_instance_valid(placer):
		var mode:=place_mode
		if mode==4: placer.call("spline_clear")
		placer.call("cancel_placement")
	on_placement_stopped()

func on_placement_stopped()->void:
	_is_placing=false
	if not _selected_path_ui.is_empty() and _card_map.has(_selected_path_ui):
		var prev:=_card_map[_selected_path_ui] as PanelContainer
		if is_instance_valid(prev):
			var ns:=StyleBoxFlat.new(); ns.bg_color=C_CARD_BG; ns.set_corner_radius_all(5); ns.set_border_width_all(1); ns.border_color=C_CARD_BD; prev.add_theme_stylebox_override("panel",ns)
	_selected_path_ui=""; selected_path=""
	if is_instance_valid(_stop_btn):_stop_btn.disabled=true
	set_status("Click an asset to start placing",C_OK)

func _on_format_toggled(ext:String)->void:
	if import_formats.has(ext): import_formats.erase(ext)
	else: import_formats.append(ext)
	_scan_folder(); _save_config()

func _on_group_filter(idx:int)->void: _active_group=idx; _rebuild_browser_now()

func _rebuild_group_bar()->void:
	if not is_instance_valid(_group_bar): return
	for c in _group_bar.get_children(): _group_bar.remove_child(c); c.queue_free()
	_add_filter_btn("All",-1); _add_filter_btn("⭐",-2)
	# Guard: if an old config saved "Favorites" as a named group entry, purge it here
	# so it never shows as a second button alongside the built-in star slot.
	_groups = _groups.filter(func(g): return (g as Dictionary)["name"] != "Favorites")
	for i in _groups.size(): _add_filter_btn((_groups[i] as Dictionary)["name"],i)
	for drop_name in ["GroupDrop","ImpGroupDrop"]:
		var drop:Node
		if drop_name=="GroupDrop": drop=_group_drop
		else: drop=_find_node_named(drop_name,self)
		if is_instance_valid(drop) and drop is OptionButton:
			(drop as OptionButton).clear(); (drop as OptionButton).add_item("⭐ Favorites")
			for g in _groups: (drop as OptionButton).add_item((g as Dictionary)["name"])
	if is_instance_valid(_multisel_group_opt):
		_multisel_group_opt.clear(); _multisel_group_opt.add_item("⭐ Favorites")
		for g in _groups: _multisel_group_opt.add_item((g as Dictionary)["name"])

func _add_filter_btn(label:String,idx:int)->void:
	var btn:=Button.new(); btn.text=label; btn.toggle_mode=true
	btn.button_pressed=(_active_group==idx)
	btn.pressed.connect(func(): _on_group_filter(idx)); _group_bar.add_child(btn)

func _on_add_group(ne:LineEdit)->void:
	var gn:=ne.text.strip_edges(); if gn.is_empty(): return
	_groups.append({"name":gn,"paths":[]}); ne.text=""
	_rebuild_group_list(); _rebuild_group_bar(); _save_config()

func _on_remove_group(idx:int)->void:
	_groups.remove_at(idx)
	if _active_group>=_groups.size(): _active_group=-1
	_rebuild_group_list(); _rebuild_group_bar(); _save_config()

func _on_add_to_group(opt:OptionButton)->void:
	if selected_path.is_empty(): set_status("Select an asset first.",C_WARN); return
	var idx:=opt.selected
	if idx==0:
		# Favorites is a special built-in slot — find it in _groups if it exists,
		# but NEVER create a new _groups entry for it (that would cause duplicates).
		for g in _groups:
			if (g as Dictionary)["name"]=="Favorites":
				if not (g as Dictionary)["paths"].has(selected_path): (g as Dictionary)["paths"].append(selected_path)
				break
	elif idx-1<_groups.size():
		var gd:=_groups[idx-1] as Dictionary
		if not gd["paths"].has(selected_path): gd["paths"].append(selected_path)
	_rebuild_group_list(); _rebuild_group_bar(); _save_config()

func _rebuild_group_list()->void:
	if not is_instance_valid(_group_list_vbox): return
	for c in _group_list_vbox.get_children(): _group_list_vbox.remove_child(c); c.queue_free()
	for i in _groups.size():
		var gd:=_groups[i] as Dictionary
		var row:=HBoxContainer.new(); row.add_theme_constant_override("separation",4); _group_list_vbox.add_child(row)
		var lbl:=Label.new(); lbl.text=str(gd["name"])+"  ("+str((gd["paths"] as Array).size())+")"
		lbl.size_flags_horizontal=SIZE_EXPAND_FILL; row.add_child(lbl)
		var db:=Button.new(); db.text="X"; db.pressed.connect(_on_remove_group.bind(i)); row.add_child(db)

func _find_node_named(n:String,from:Node)->Node:
	if from.name==n: return from
	for c in from.get_children():
		var r:=_find_node_named(n,c); if r!=null: return r
	return null

func update_rot_display(rx:float,ry:float,rz:float)->void:
	if is_instance_valid(_rot_x_spin): _rot_x_spin.set_value_no_signal(rx)
	if is_instance_valid(_rot_y_spin): _rot_y_spin.set_value_no_signal(ry)
	if is_instance_valid(_rot_z_spin): _rot_z_spin.set_value_no_signal(rz)

func get_place_scale()->Vector3:
	return Vector3(place_scale_all,place_scale_all,place_scale_all) if uniform_scale else Vector3(place_scale_x,place_scale_y,place_scale_z)

func get_rot_snap()->float:
	match rotation_snap_mode:
		0: return 0.0
		1: return 90.0
		2: return 45.0
		3: return 15.0
		4: return custom_snap_deg
	return 90.0

func nudge_height(delta:float)->void:
	if height_snap:
		var step:=grid_size if grid_size>0.0 else 1.0; height_offset=snapped(height_offset+delta,step)
	else: height_offset+=delta
	if is_instance_valid(_height_spin): _height_spin.set_value_no_signal(height_offset); _save_config()

func nudge_grid_height(delta:float)->void:
	grid_height+=delta
	if is_instance_valid(_grid_h_spin): _grid_h_spin.set_value_no_signal(grid_height)
	if is_instance_valid(placer):placer.call("rebuild_grid"); _save_config()

func nudge_scale(delta:float)->void:
	if uniform_scale:
		place_scale_all=maxf(0.01,place_scale_all+delta)
		place_scale_x=place_scale_all; place_scale_y=place_scale_all; place_scale_z=place_scale_all
		if is_instance_valid(_scale_spin):_scale_spin.set_value_no_signal(place_scale_all)
	else:
		place_scale_x=maxf(0.01,place_scale_x+delta); place_scale_y=maxf(0.01,place_scale_y+delta); place_scale_z=maxf(0.01,place_scale_z+delta)
		if is_instance_valid(_scale_x_spin):_scale_x_spin.set_value_no_signal(place_scale_x)
		if is_instance_valid(_scale_y_spin):_scale_y_spin.set_value_no_signal(place_scale_y)
		if is_instance_valid(_scale_z_spin):_scale_z_spin.set_value_no_signal(place_scale_z)
	_save_config()

func set_status(msg:String,color:Variant=null)->void:
	if not is_instance_valid(_status_lbl): return
	_status_lbl.text=msg
	var _sc:Color=C_OK
	if color!=null: _sc=color as Color
	_status_lbl.add_theme_color_override("font_color",_sc)


# ─── Asset Zoo ────────────────────────────────────────────────────────────────
func _on_zoo_pressed()->void:
	var root:=EditorInterface.get_edited_scene_root()
	if root==null or not root is Node3D: set_status("Open a 3D scene first.",C_WARN); return
	if _all_paths.is_empty(): set_status("No assets loaded.",C_WARN); return
	if not is_instance_valid(placer): return
	_zoo_is_building=false; _zoo_items.clear(); _zoo_paths_to_measure.clear()
	var zoo:=Node3D.new(); zoo.name="AssetZoo"
	(root as Node3D).add_child(zoo); zoo.owner=root
	_zoo_node=zoo; _zoo_index=0
	for path in _all_paths:
		if ResourceLoader.exists(path): _zoo_paths_to_measure.append(path)
	EditorInterface.get_selection().clear(); EditorInterface.get_selection().add_node(zoo)
	set_status("Zoo: measuring %d assets..."%_zoo_paths_to_measure.size(),C_DIM)

func _tick_zoo_measure()->void:
	if not is_instance_valid(_zoo_node): _zoo_paths_to_measure.clear(); return
	var count:=0
	while not _zoo_paths_to_measure.is_empty() and count<ZOO_MEASURE_BATCH:
		var path:=_zoo_paths_to_measure.pop_front() as String
		if not ResourceLoader.exists(path): count+=1; continue
		var res:=ResourceLoader.load(path,"",ResourceLoader.CACHE_MODE_REUSE)
		if res==null: count+=1; continue
		var aabb:=AABB()
		if res is Mesh: aabb=(res as Mesh).get_aabb()
		elif res is PackedScene:
			var tmp:=(res as PackedScene).instantiate()
			if tmp!=null: aabb=_collect_aabb_offline(tmp); tmp.queue_free()
		if aabb.size==Vector3.ZERO: aabb=AABB(Vector3(-0.5,0,-0.5),Vector3(1,1,1))
		_zoo_items.append({"res":res,"path":path,"aabb":aabb,"half":maxf(aabb.size.x,aabb.size.z)*0.5+0.1})
		count+=1
	set_status("Zoo: measuring... %d remaining"%_zoo_paths_to_measure.size(),C_DIM)
	if _zoo_paths_to_measure.is_empty() and not _zoo_items.is_empty(): _zoo_compute_layout()

func _zoo_compute_layout()->void:
	var spacing:=_zoo_spacing_spin.value if is_instance_valid(_zoo_spacing_spin) else 2.0
	var items:=_zoo_items; var cols:=int(ceil(sqrt(float(items.size()))))
	var col_max:Array=[]; var row_max:Array=[]
	for i in items.size():
		var ci:=i%cols; var ri:=i/cols
		while col_max.size()<=ci: col_max.append(0.0)
		while row_max.size()<=ri: row_max.append(0.0)
		var hh:=items[i]["half"] as float
		col_max[ci]=maxf(col_max[ci],hh); row_max[ri]=maxf(row_max[ri],hh)
	var x_off:Array=[]; var acc:=0.0
	for ci in cols: x_off.append(acc+col_max[ci]); acc+=col_max[ci]*2.0+spacing
	var z_off:Array=[]; acc=0.0
	for ri in row_max.size(): z_off.append(acc+row_max[ri]); acc+=row_max[ri]*2.0+spacing
	for i in items.size():
		var ci:=i%cols; var ri:=i/cols
		(items[i] as Dictionary)["x"]=x_off[ci]; (items[i] as Dictionary)["z"]=z_off[ri]
	_zoo_cols=cols; _zoo_x_off=x_off; _zoo_z_off=z_off; _zoo_index=0
	_zoo_is_building=true; set_status("Zoo: placing 0 / %d..."%items.size(),C_DIM)

func _tick_zoo_build()->void:
	if not is_instance_valid(_zoo_node):
		_zoo_is_building=false; _zoo_items.clear(); set_status("Zoo: root deleted — build cancelled.",C_WARN); return
	var root:=EditorInterface.get_edited_scene_root()
	if root==null: _zoo_is_building=false; _zoo_items.clear(); return
	var count:=0
	while _zoo_index<_zoo_items.size() and count<ZOO_BATCH:
		if not is_instance_valid(_zoo_node):
			_zoo_is_building=false; _zoo_items.clear(); set_status("Zoo: root deleted — build cancelled.",C_WARN); return
		var item:=_zoo_items[_zoo_index] as Dictionary
		var res:=item["res"] as Resource; var aabb:=item["aabb"] as AABB
		var bn:=(item["path"] as String).get_file().get_basename()
		var tx:=item["x"] as float; var tz:=item["z"] as float
		if res!=null and is_instance_valid(placer):
			var inst:Node3D=placer.call("instantiate_resource_pub",res)
			if inst!=null and is_instance_valid(_zoo_node):
				_zoo_node.add_child(inst)
				inst.name=bn if not bn.is_empty() else "Asset_%d"%_zoo_index
				_set_owner_recursive(inst,root)
				inst.position=Vector3(tx-aabb.get_center().x,-aabb.position.y,tz-aabb.get_center().z)
				if _zoo_show_labels:
					var lbl:=Label3D.new()
					lbl.name="Label_"+inst.name; lbl.text=inst.name; lbl.pixel_size=0.008
					lbl.billboard=BaseMaterial3D.BILLBOARD_ENABLED; lbl.no_depth_test=true
					lbl.outline_modulate=Color(0,0,0,1); lbl.outline_size=8; lbl.font_size=32
					lbl.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
					lbl.position=Vector3(aabb.get_center().x,aabb.size.y+0.35+(-aabb.position.y),aabb.get_center().z)
					inst.add_child(lbl); lbl.owner=root
			elif inst!=null: inst.queue_free()
		_zoo_index+=1; count+=1
	if _zoo_index>=_zoo_items.size():
		_zoo_is_building=false; set_status("Zoo: %d assets placed."%_zoo_items.size(),C_OK); _zoo_items.clear()
	else:
		set_status("Zoo: placing %d / %d..."%[_zoo_index,_zoo_items.size()],C_DIM)

func _collect_aabb_offline(node:Node)->AABB:
	var result:=AABB()
	for mi in _find_meshes_offline(node):
		var aabb:=(mi as MeshInstance3D).mesh.get_aabb()
		result=aabb if result.size==Vector3.ZERO else result.merge(aabb)
	return result

func _find_meshes_offline(node:Node)->Array:
	var out:Array=[]
	if node is MeshInstance3D and (node as MeshInstance3D).mesh!=null: out.append(node)
	for c in node.get_children(): out.append_array(_find_meshes_offline(c))
	return out

func _set_owner_recursive(node:Node,root:Node)->void:
	if not is_instance_valid(node) or node==root: return
	node.owner=root
	for c in node.get_children(): _set_owner_recursive(c,root)

func _collect_aabb(node:Node,origin:Node3D,inout:AABB)->AABB:
	if node is MeshInstance3D:
		var mi:=node as MeshInstance3D
		if mi.mesh!=null:
			var rel:=origin.global_transform.affine_inverse()*mi.global_transform
			var xf:=rel*mi.mesh.get_aabb()
			inout=xf if inout.size==Vector3.ZERO else inout.merge(xf)
	for c in node.get_children(): inout=_collect_aabb(c,origin,inout)
	return inout

# ─── Config ───────────────────────────────────────────────────────────────────
func _save_config()->void:
	var cfg:=ConfigFile.new()
	cfg.set_value("s","folder",current_folder)
	var extra:Array=[]
	for p in _all_paths:
		if not (p as String).begins_with(current_folder): extra.append(p)
	cfg.set_value("s","extra_paths",extra)
	cfg.set_value("s","place_mode",place_mode); cfg.set_value("s","scroll_mode",scroll_mode)
	cfg.set_value("s","grid_size",grid_size); cfg.set_value("s","grid_height",grid_height)
	cfg.set_value("s","height_offset",height_offset); cfg.set_value("s","height_snap",height_snap)
	cfg.set_value("s","show_grid",show_grid); cfg.set_value("s","grid_enabled",grid_enabled)
	cfg.set_value("s","align_to_normal",align_to_normal); cfg.set_value("s","vertex_snap_mesh",vertex_snap_mesh)
	cfg.set_value("s","vertex_snap_strength",vertex_snap_strength)
	cfg.set_value("s","rot_snap",rotation_snap_mode); cfg.set_value("s","custom_deg",custom_snap_deg)
	cfg.set_value("s","rrot",random_rot); cfg.set_value("s","rrot_min",rrot_min); cfg.set_value("s","rrot_max",rrot_max)
	cfg.set_value("s","uniform",uniform_scale); cfg.set_value("s","scale_all",place_scale_all)
	cfg.set_value("s","scale_x",place_scale_x); cfg.set_value("s","scale_y",place_scale_y); cfg.set_value("s","scale_z",place_scale_z)
	cfg.set_value("s","rscale",random_scale); cfg.set_value("s","rscale_min",rscale_min); cfg.set_value("s","rscale_max",rscale_max)
	cfg.set_value("s","random_tilt",random_tilt); cfg.set_value("s","rtilt_max",rtilt_max)
	cfg.set_value("s","paint",paint_mode); cfg.set_value("s","paint_spacing",paint_spacing)
	cfg.set_value("s","paint_scatter",paint_scatter); cfg.set_value("s","scatter_radius",scatter_radius)
	cfg.set_value("s","random_group_place",random_group_place)
	cfg.set_value("s","unpack_scenes",unpack_scenes)
	cfg.set_value("s","multimesh_mode",multimesh_mode); cfg.set_value("s","mm_col_en",mm_collision_enabled)
	cfg.set_value("s","parent_path",parent_path); cfg.set_value("s","preview_size",_preview_size)
	cfg.set_value("s","col_en",collision_enabled); cfg.set_value("s","col_body",collision_body_type)
	cfg.set_value("s","col_shape",collision_shape_type); cfg.set_value("s","col_unpack",collision_auto_unpack)
	cfg.set_value("s","mat_en",material_override_enabled); cfg.set_value("s","mat_path",material_override_path)
	cfg.set_value("s","mat_mode",material_override_mode); cfg.set_value("s","import_formats",import_formats)
	cfg.set_value("s","zoo_labels",_zoo_show_labels)
	cfg.set_value("s","paint_as_brush",paint_as_brush)
	cfg.set_value("s","brush_radius",brush_radius); cfg.set_value("s","brush_density",brush_density)
	cfg.set_value("s","brush_falloff",brush_falloff); cfg.set_value("s","brush_tex",brush_texture_path)
	for a in shortcuts.keys(): cfg.set_value("k",a,shortcuts[a])
	cfg.set_value("g","count",_groups.size())
	for i in _groups.size():
		var g:=_groups[i] as Dictionary
		cfg.set_value("g","g%d_n"%i,g["name"]); cfg.set_value("g","g%d_p"%i,g["paths"])
	cfg.save(CONFIG_PATH)

func _load_config()->void:
	var cfg:=ConfigFile.new(); if cfg.load(CONFIG_PATH)!=OK: return
	current_folder        =cfg.get_value("s","folder","res://")
	var saved_extra:Array =cfg.get_value("s","extra_paths",[]) as Array
	call_deferred("_merge_extra_paths",saved_extra)
	place_mode            =cfg.get_value("s","place_mode",1)
	scroll_mode           =cfg.get_value("s","scroll_mode",0)
	grid_size             =cfg.get_value("s","grid_size",1.0)
	grid_height           =cfg.get_value("s","grid_height",0.0)
	height_offset         =cfg.get_value("s","height_offset",0.0)
	height_snap           =cfg.get_value("s","height_snap",false)
	show_grid             =cfg.get_value("s","show_grid",true)
	grid_enabled          =cfg.get_value("s","grid_enabled",true)
	align_to_normal       =cfg.get_value("s","align_to_normal",false)
	vertex_snap_mesh      =cfg.get_value("s","vertex_snap_mesh",false)
	vertex_snap_strength  =cfg.get_value("s","vertex_snap_strength",42.0)
	rotation_snap_mode    =cfg.get_value("s","rot_snap",1)
	custom_snap_deg       =cfg.get_value("s","custom_deg",15.0)
	random_rot            =cfg.get_value("s","rrot",false)
	rrot_min              =cfg.get_value("s","rrot_min",0.0)
	rrot_max              =cfg.get_value("s","rrot_max",360.0)
	uniform_scale         =cfg.get_value("s","uniform",true)
	place_scale_all       =cfg.get_value("s","scale_all",1.0)
	place_scale_x         =cfg.get_value("s","scale_x",1.0)
	place_scale_y         =cfg.get_value("s","scale_y",1.0)
	place_scale_z         =cfg.get_value("s","scale_z",1.0)
	random_scale          =cfg.get_value("s","rscale",false)
	rscale_min            =cfg.get_value("s","rscale_min",0.8)
	rscale_max            =cfg.get_value("s","rscale_max",1.2)
	random_tilt           =cfg.get_value("s","random_tilt",false)
	rtilt_max             =cfg.get_value("s","rtilt_max",10.0); rtilt_min=-rtilt_max
	paint_mode            =cfg.get_value("s","paint",false)
	paint_spacing         =cfg.get_value("s","paint_spacing",0.5)
	paint_scatter         =cfg.get_value("s","paint_scatter",false)
	scatter_radius        =cfg.get_value("s","scatter_radius",0.5)
	random_group_place    =cfg.get_value("s","random_group_place",false)
	unpack_scenes         =cfg.get_value("s","unpack_scenes",false)
	multimesh_mode        =cfg.get_value("s","multimesh_mode",false)
	mm_collision_enabled  =cfg.get_value("s","mm_col_en",false)
	parent_path           =cfg.get_value("s","parent_path","")
	_preview_size         =cfg.get_value("s","preview_size",88)
	collision_enabled     =cfg.get_value("s","col_en",false)
	collision_body_type   =cfg.get_value("s","col_body",0)
	collision_shape_type  =cfg.get_value("s","col_shape",0)
	collision_auto_unpack =cfg.get_value("s","col_unpack",true)
	material_override_enabled=cfg.get_value("s","mat_en",false)
	material_override_path   =cfg.get_value("s","mat_path","")
	material_override_mode   =cfg.get_value("s","mat_mode",0)
	var saved_fmts:Array=cfg.get_value("s","import_formats",ALL_FORMATS.duplicate()) as Array
	import_formats=saved_fmts
	for a in shortcuts.keys():
		if cfg.has_section_key("k",a): shortcuts[a]=cfg.get_value("k",a,shortcuts[a])
	var gc:int=cfg.get_value("g","count",0); _groups.clear()
	for i in gc:
		_groups.append({"name":cfg.get_value("g","g%d_n"%i,"Group"),"paths":cfg.get_value("g","g%d_p"%i,[])})
	# Purge any "Favorites" entry that was incorrectly saved by older versions —
	# Favorites is now always the built-in ⭐ slot (index -2) and must never live in _groups.
	_groups = _groups.filter(func(g): return (g as Dictionary)["name"] != "Favorites")
	_zoo_show_labels=cfg.get_value("s","zoo_labels",true)
	paint_as_brush  =cfg.get_value("s","paint_as_brush",false)
	brush_radius    =cfg.get_value("s","brush_radius",2.0)
	brush_density   =cfg.get_value("s","brush_density",0.5)
	brush_falloff   =cfg.get_value("s","brush_falloff",0.5)
	brush_texture_path=cfg.get_value("s","brush_tex","")
