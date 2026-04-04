extends CanvasLayer
## Pro v1.2 template: scrollable slot list with timestamps, thumbnails (if [code]slot_N.jpg[/code] exists), Load / Save / Delete (with confirm). Uses [method SaveManagerBase.export_current_to_slot] and [method SaveManagerBase.import_slot_into_runtime].

@export var slot_file_prefix: String = "slot_"
@export var scan_max_index: int = 24

@onready var _slot_list: VBoxContainer = %SlotList
@onready var _close_btn: Button = $Center/Panel/Margin/VBox/BottomRow/CloseBtn
@onready var _new_btn: Button = $Center/Panel/Margin/VBox/BottomRow/NewBtn
@onready var _delete_dlg: ConfirmationDialog = $DeleteConfirm


func _ready() -> void:
	hide()
	_close_btn.pressed.connect(_on_close_pressed)
	_new_btn.pressed.connect(_on_new_slot_pressed)
	_delete_dlg.confirmed.connect(_on_delete_confirmed)


func open_menu() -> void:
	refresh_slots()
	show()


func _on_close_pressed() -> void:
	hide()


func hide() -> void:
	super.hide()


func refresh_slots() -> void:
	for c in _slot_list.get_children():
		c.queue_free()
	var root_path: String = SaveManager.save_root
	var abs_root := ProjectSettings.globalize_path(root_path)
	if not DirAccess.dir_exists_absolute(abs_root):
		var lbl := Label.new()
		lbl.text = "Save folder missing: %s" % root_path
		_slot_list.add_child(lbl)
		return
	for i in range(1, scan_max_index + 1):
		var base := "%s%d" % [slot_file_prefix, i]
		var sid := StringName(base)
		var p_bin := root_path.path_join(base + ".bin")
		var p_json := root_path.path_join(base + ".json")
		var path := ""
		if FileAccess.file_exists(p_bin):
			path = p_bin
		elif FileAccess.file_exists(p_json):
			path = p_json
		if path.is_empty():
			continue
		_add_slot_row(sid, path, abs_root)


func _add_slot_row(slot_id: StringName, save_path: String, abs_root: String) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	var thumb := TextureRect.new()
	thumb.custom_minimum_size = Vector2(72, 40)
	thumb.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	thumb.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	var jpg_path := save_path.get_basename() + ".jpg"
	var jpg_abs := ProjectSettings.globalize_path(jpg_path)
	if FileAccess.file_exists(jpg_path):
		var img := Image.load_from_file(jpg_abs)
		if img != null:
			thumb.texture = ImageTexture.create_from_image(img)
	row.add_child(thumb)
	var texts := VBoxContainer.new()
	var title := Label.new()
	title.text = str(slot_id)
	texts.add_child(title)
	var sub := Label.new()
	sub.add_theme_font_size_override("font_size", 12)
	sub.add_theme_color_override("font_color", Color(0.75, 0.78, 0.85))
	var unix := int(FileAccess.get_modified_time(save_path))
	var dt := SaveStateUnixDisplay.format_modified_time(unix)
	sub.text = dt if not dt.is_empty() else "—"
	texts.add_child(sub)
	row.add_child(texts)
	var btns := VBoxContainer.new()
	var b_load := Button.new()
	b_load.text = "Load"
	b_load.pressed.connect(func() -> void:
		_do_load(slot_id)
	)
	btns.add_child(b_load)
	var b_save := Button.new()
	b_save.text = "Save"
	b_save.pressed.connect(func() -> void:
		_do_save(slot_id)
	)
	btns.add_child(b_save)
	var b_del := Button.new()
	b_del.text = "Delete"
	b_del.pressed.connect(func() -> void:
		_pending_delete_slot = slot_id
		_delete_dlg.popup_centered()
	)
	btns.add_child(b_del)
	row.add_child(btns)
	_slot_list.add_child(row)


var _pending_delete_slot: StringName = &""


func _do_load(slot_id: StringName) -> void:
	var err: Error = SaveManager.import_slot_into_runtime(slot_id) as Error
	if err != OK:
		push_warning("SaveMenuPro: load failed %s" % error_string(err))


func _do_save(slot_id: StringName) -> void:
	var err: Error = SaveManager.export_current_to_slot(slot_id) as Error
	if err != OK:
		push_warning("SaveMenuPro: save failed %s" % error_string(err))
	else:
		refresh_slots()


func _on_new_slot_pressed() -> void:
	var sid := _find_next_free_slot()
	if str(sid).is_empty():
		return
	var err: Error = SaveManager.export_current_to_slot(sid) as Error
	if err == OK:
		refresh_slots()


func _find_next_free_slot() -> StringName:
	var root_path: String = SaveManager.save_root
	for i in range(1, scan_max_index + 1):
		var base := "%s%d" % [slot_file_prefix, i]
		var p1 := root_path.path_join(base + ".bin")
		var p2 := root_path.path_join(base + ".json")
		if not FileAccess.file_exists(p1) and not FileAccess.file_exists(p2):
			return StringName(base)
	return &""


func _on_delete_confirmed() -> void:
	if str(_pending_delete_slot).is_empty():
		return
	var root_path: String = SaveManager.save_root
	var base := str(_pending_delete_slot)
	for ext in [".bin", ".json"]:
		var p := root_path.path_join(base + ext)
		if FileAccess.file_exists(p):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(p))
		var bak := p + ".bak"
		if FileAccess.file_exists(bak):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(bak))
	var jpg := root_path.path_join(base + ".jpg")
	if FileAccess.file_exists(jpg):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(jpg))
	_pending_delete_slot = &""
	refresh_slots()
