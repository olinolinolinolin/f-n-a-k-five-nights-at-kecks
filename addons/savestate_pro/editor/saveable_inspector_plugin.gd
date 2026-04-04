@tool
extends EditorInspectorPlugin

const LOG_PREFIX := "[SaveState Pro | Saveable Inspector]"

func _can_handle(object: Object) -> bool:
	return object is Saveable


func _parse_begin(object: Object) -> void:
	var s: Saveable = object as Saveable
	if s == null:
		return

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 6)

	var header := Label.new()
	header.text = "Saveable Property Picker"
	header.add_theme_font_size_override("font_size", 14)
	root.add_child(header)

	var hint := Label.new()
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.text = "Select properties from the parent node. Safe types are enabled; unsupported types are shown but disabled."
	root.add_child(hint)

	var target: Node = s.get_parent()
	if target == null:
		var warn := Label.new()
		warn.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		warn.add_theme_color_override("font_color", Color(1.0, 0.8, 0.6))
		warn.text = "No parent node. Add this Saveable as a child of the node you want to save."
		root.add_child(warn)
		add_custom_control(root)
		return

	var search := LineEdit.new()
	search.placeholder_text = "Search properties…"
	root.add_child(search)

	var preset_bar := HBoxContainer.new()
	root.add_child(preset_bar)

	var btn_all_safe := Button.new()
	btn_all_safe.text = "Select all safe"
	preset_bar.add_child(btn_all_safe)

	var btn_clear := Button.new()
	btn_clear.text = "Clear"
	preset_bar.add_child(btn_clear)

	var btn_write_meta := CheckBox.new()
	btn_write_meta.text = "Also write metadata flags on parent (savestate_*)"
	btn_write_meta.tooltip_text = "Optional: sets parent meta keys so selections are visible without selecting the Saveable."
	btn_write_meta.button_pressed = bool(s.write_parent_metadata_flags)
	btn_write_meta.toggled.connect(func(on: bool) -> void:
		if s != null:
			s.write_parent_metadata_flags = on
	)
	root.add_child(btn_write_meta)

	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0, 220)
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(scroll)

	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(list)

	var allow := {}
	for name in s.property_allowlist:
		allow[str(name)] = true

	var props: Array = target.get_property_list()
	var rows: Array[Dictionary] = []
	for p in props:
		var n := str(p.get("name", ""))
		if n.is_empty():
			continue
		if n == "script" or n.begins_with("_"):
			continue
		var usage := int(p.get("usage", 0))
		# Skip editor-only / internal properties (reduces noise).
		if (usage & PROPERTY_USAGE_STORAGE) == 0 and (usage & PROPERTY_USAGE_EDITOR) == 0:
			continue
		var t := int(p.get("type", TYPE_NIL))
		var safe := _is_safe_type(t)
		rows.append({"name": n, "type": t, "safe": safe})

	rows.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return str(a["name"]) < str(b["name"])
	)

	var checkboxes: Array[CheckBox] = []
	var checkbox_name: Dictionary = {} # CheckBox -> String
	var checkbox_safe: Dictionary = {} # CheckBox -> bool

	# Build the full list once, then filter by visibility for stability.
	for r in rows:
		var n := str(r["name"])
		var t := int(r["type"])
		var safe := bool(r["safe"])
		var cb := CheckBox.new()
		cb.text = "%s  (%s)" % [n, type_string(t)]
		cb.disabled = not safe
		cb.tooltip_text = "" if safe else "Unsupported type for zero-code Saveable. Use custom serialization or store a simpler value."
		cb.button_pressed = allow.has(n)
		cb.toggled.connect(func(pressed: bool) -> void:
			var want_meta := bool(btn_write_meta.button_pressed) or bool(s.write_parent_metadata_flags)
			_set_allowlist_entry(s, target, n, pressed, want_meta)
		)
		list.add_child(cb)
		checkboxes.append(cb)
		checkbox_name[cb] = n
		checkbox_safe[cb] = safe

	search.text_changed.connect(func(t: String) -> void:
		var q := t.strip_edges().to_lower()
		for cb in checkboxes:
			var nm := str(checkbox_name.get(cb, ""))
			cb.visible = q.is_empty() or nm.to_lower().contains(q)
	)

	btn_clear.pressed.connect(func() -> void:
		for cb in checkboxes:
			if bool(checkbox_safe.get(cb, false)) == false:
				continue
			cb.button_pressed = false
		s.property_allowlist = []
		s.notify_property_list_changed()
		if bool(btn_write_meta.button_pressed) or bool(s.write_parent_metadata_flags):
			_clear_parent_meta_for_missing(target, {})
	)

	btn_all_safe.pressed.connect(func() -> void:
		var next_allow := {}
		for cb in checkboxes:
			if bool(checkbox_safe.get(cb, false)) == false:
				continue
			cb.button_pressed = true
			var n := str(checkbox_name.get(cb, ""))
			if not n.is_empty():
				next_allow[n] = true
		s.property_allowlist = next_allow.keys()
		s.notify_property_list_changed()
		if bool(btn_write_meta.button_pressed):
			_apply_parent_meta_from_allow(target, next_allow)
	)

	add_custom_control(root)


func _is_safe_type(t: int) -> bool:
	return (
		t == TYPE_BOOL
		or t == TYPE_INT
		or t == TYPE_FLOAT
		or t == TYPE_STRING
		or t == TYPE_VECTOR2
		or t == TYPE_VECTOR3
		or t == TYPE_VECTOR4
		or t == TYPE_COLOR
		or t == TYPE_RECT2
		or t == TYPE_RECT2I
		or t == TYPE_VECTOR2I
		or t == TYPE_VECTOR3I
		or t == TYPE_QUATERNION
		or t == TYPE_BASIS
		or t == TYPE_TRANSFORM2D
		or t == TYPE_TRANSFORM3D
		or t == TYPE_DICTIONARY
		or t == TYPE_ARRAY
	)


func _set_allowlist_entry(s: Saveable, parent: Node, prop: String, pressed: bool, write_meta: bool) -> void:
	var cur := {}
	for name in s.property_allowlist:
		cur[str(name)] = true
	if pressed:
		cur[prop] = true
	else:
		cur.erase(prop)
	s.property_allowlist = cur.keys()
	s.notify_property_list_changed()
	if write_meta:
		_apply_parent_meta_from_allow(parent, cur)


func _apply_parent_meta_from_allow(parent: Node, allow: Dictionary) -> void:
	for k in allow:
		parent.set_meta("savestate_%s" % str(k), true)
	_clear_parent_meta_for_missing(parent, allow)


func _clear_parent_meta_for_missing(parent: Node, allow: Dictionary) -> void:
	# Best-effort cleanup: remove savestate_* meta for properties that are no longer selected.
	var meta := parent.get_meta_list()
	for mk in meta:
		var mks := str(mk)
		if not mks.begins_with("savestate_"):
			continue
		var pname := mks.trim_prefix("savestate_")
		if not allow.has(pname):
			parent.remove_meta(mks)

