@tool
extends EditorPlugin

## Ultimate Asset Placer — Plugin Entry Point v1.4
##
## Minecraft-style scene thumbnail capture:
## Hooks EditorInterface.get_editor_main_screen() to detect when the user
## switches scene tabs. Captures the 3D viewport BEFORE the switch happens
## by polling the current scene path every frame and saving when it changes.
## Also captures on scene_closed and when the plugin exits.

const THUMB_CACHE_DIR := "user://uap_thumbnails/"
const THUMB_SIZE      := Vector2i(256, 256)

var _manager:       Node    = null
var _settings_dock: Control = null
var _browser_dock:  Control = null
var _placer:        Node    = null

# We need a real Node in the tree to get _process — plugin _process is unreliable
var _ticker: Node = null

# Scene-capture state
# We track the TYPE of the scene at the moment we first see it.
# By the time _do_capture fires, get_edited_scene_root() may already show
# the NEW scene — so we must NOT query it inside _do_capture.
var _current_scene_path:    String = ""
var _current_scene_is_2d:   bool   = false
var _pending_capture_path:  String = ""
var _pending_capture_is_2d: bool   = false
var _capture_cooldown:      int    = 0

func _enter_tree() -> void:
	DirAccess.make_dir_recursive_absolute(THUMB_CACHE_DIR)

	_placer = load("res://addons/ultimate_placer/ultimate_placer.gd").new()
	_placer.name = "UAP_Placer"
	_placer.set("editor_plugin", self)
	add_child(_placer)

	_manager = load("res://addons/ultimate_placer/ultimate_panel.gd").new()
	_manager.name = "UAP_Manager"
	_manager.set("placer", _placer)
	_placer.set("panel", _manager)

	get_editor_interface().get_base_control().add_child(_manager)
	_manager.hide()

	_settings_dock = _manager.get_settings_ui()
	_browser_dock  = _manager.get_browser_ui()
	add_control_to_dock(DOCK_SLOT_RIGHT_UL, _settings_dock)
	add_control_to_bottom_panel(_browser_dock, "Asset Browser")

	# Create a ticker node so we reliably get _process every frame
	_ticker = Node.new()
	_ticker.name = "__UAP_Ticker__"
	_ticker.set_script(_make_ticker_script())
	_ticker.set("plugin_ref", self)
	get_editor_interface().get_base_control().add_child(_ticker)

	# Connect close signal for capture-on-close
	scene_closed.connect(_on_scene_closed)

	# Record what is already open — store path AND type before any switch
	var cur_root := get_editor_interface().get_edited_scene_root()
	if cur_root != null and not cur_root.scene_file_path.is_empty():
		_current_scene_path  = cur_root.scene_file_path
		_current_scene_is_2d = (cur_root is Node2D) or (cur_root is Control)

	print("[Ultimate Asset Placer v1.4] Ready.")

func _exit_tree() -> void:
	# Capture the currently visible scene before the plugin shuts down
	_do_capture(_current_scene_path, _current_scene_is_2d)

	if scene_closed.is_connected(_on_scene_closed):
		scene_closed.disconnect(_on_scene_closed)

	if is_instance_valid(_ticker):
		_ticker.queue_free()
	_ticker = null

	if is_instance_valid(_placer):
		_placer.call("cleanup"); _placer.queue_free()
	if is_instance_valid(_settings_dock):
		remove_control_from_docks(_settings_dock); _settings_dock.queue_free()
	if is_instance_valid(_browser_dock):
		remove_control_from_bottom_panel(_browser_dock); _browser_dock.queue_free()
	if is_instance_valid(_manager):
		_manager.queue_free()

	_placer = null; _settings_dock = null
	_browser_dock = null; _manager = null

func _handles(object: Object) -> bool:
	return object is Node3D

func _forward_3d_gui_input(camera: Camera3D, event: InputEvent) -> int:
	if is_instance_valid(_placer):
		var consumed: bool = _placer.call("handle_input", camera, event)
		if consumed:
			get_viewport().set_input_as_handled()
			return EditorPlugin.AFTER_GUI_INPUT_STOP
	return EditorPlugin.AFTER_GUI_INPUT_PASS

# ── Called by ticker node every editor frame ──────────────────────────────────
func tick() -> void:
	# Handle pending delayed capture (from scene_closed)
	if not _pending_capture_path.is_empty():
		if _capture_cooldown > 0:
			_capture_cooldown -= 1
		else:
			_do_capture(_pending_capture_path, _pending_capture_is_2d)
			_pending_capture_path = ""; _pending_capture_is_2d = false

	# Poll for scene tab switch
	var now_path := _get_current_scene_path()
	if now_path == _current_scene_path: return

	# ── Scene switched ────────────────────────────────────────────────────────
	# At this exact frame, get_edited_scene_root() ALREADY returns the NEW root.
	# But we stored _current_scene_is_2d from the PREVIOUS frame when the old
	# scene was still active — so we use that, NOT get_edited_scene_root() here.
	if not _current_scene_path.is_empty():
		_do_capture(_current_scene_path, _current_scene_is_2d)

	# Now update to new scene — record its type immediately for next switch
	_current_scene_path = now_path
	_current_scene_is_2d = false
	if not now_path.is_empty():
		var new_root := get_editor_interface().get_edited_scene_root()
		if is_instance_valid(new_root):
			_current_scene_is_2d = (new_root is Node2D) or (new_root is Control)

# ── On scene tab closed ───────────────────────────────────────────────────────
func _on_scene_closed(filepath: String) -> void:
	if filepath.is_empty(): return
	# The scene root is still available briefly when this signal fires
	var closed_root := get_editor_interface().get_edited_scene_root()
	var is_2d := false
	if is_instance_valid(closed_root) and closed_root.scene_file_path == filepath:
		is_2d = (closed_root is Node2D) or (closed_root is Control)
	elif filepath == _current_scene_path:
		# Fall back to our tracked type
		is_2d = _current_scene_is_2d
	_pending_capture_path  = filepath
	_pending_capture_is_2d = is_2d
	_capture_cooldown      = 3
	if filepath == _current_scene_path:
		_current_scene_path  = ""; _current_scene_is_2d = false

# ── Viewport capture ──────────────────────────────────────────────────────────
func _do_capture(scene_path: String, is_2d: bool = false) -> void:
	if scene_path.is_empty(): return

	if is_2d:
		# 2D scene: use uap_thumb_gen's offline 2D SubViewport renderer.
		# The 3D viewport shows nothing useful for these.
		if is_instance_valid(_manager):
			var thumb_gen: Node = _manager.get("_thumb_gen")
			if is_instance_valid(thumb_gen) and not thumb_gen.has_disk_cache(scene_path):
				thumb_gen.enqueue_2d(scene_path)
		return

	# ── 3D scene: capture the editor's 3D viewport ────────────────────────────
	var vp: Viewport = get_editor_interface().get_editor_viewport_3d(0)
	if not is_instance_valid(vp): return

	var vp_tex := vp.get_texture()
	if vp_tex == null: return

	var img := vp_tex.get_image()
	if img == null or img.is_empty(): return
	if _image_is_blank(img): return

	# Centre-crop to square (editor viewport is 16:9)
	var w := img.get_width(); var h := img.get_height()
	if w > 0 and h > 0 and w != h:
		var sq := mini(w, h)
		var ox := (w - sq) / 2; var oy := (h - sq) / 2
		img = img.get_region(Rect2i(ox, oy, sq, sq))

	if img.is_empty(): return
	img.resize(THUMB_SIZE.x, THUMB_SIZE.y, Image.INTERPOLATE_LANCZOS)

	var cp  := _cache_path_for(scene_path)
	var err := img.save_png(cp)
	if err == OK and is_instance_valid(_manager):
		_manager.call("invalidate_thumb_cache", scene_path)

func _image_is_blank(img: Image) -> bool:
	## Returns true if the image is a solid uniform colour (nothing rendered).
	## Samples a 4x4 grid of pixels and checks variance.
	var w := img.get_width(); var h := img.get_height()
	if w < 4 or h < 4: return true
	var ref := img.get_pixel(w / 2, h / 2)
	for xi in 4:
		for yi in 4:
			var c := img.get_pixel(xi * (w-1) / 3, yi * (h-1) / 3)
			if absf(c.r-ref.r)+absf(c.g-ref.g)+absf(c.b-ref.b) > 0.08:
				return false
	return true

func _get_current_scene_path() -> String:
	var root := get_editor_interface().get_edited_scene_root()
	if root == null: return ""
	return root.scene_file_path

func _cache_path_for(scene_path: String) -> String:
	return THUMB_CACHE_DIR + scene_path.md5_text() + ".png"

# ── Inline ticker script ───────────────────────────────────────────────────────
func _make_ticker_script() -> GDScript:
	## Returns a tiny GDScript that calls plugin_ref.tick() every frame.
	## We create it in-code so we don't need a separate file.
	var src := """
@tool
extends Node
var plugin_ref = null
func _process(_dt: float) -> void:
	if plugin_ref != null and is_instance_valid(plugin_ref):
		plugin_ref.tick()
"""
	var s := GDScript.new()
	s.source_code = src
	s.reload()
	return s
