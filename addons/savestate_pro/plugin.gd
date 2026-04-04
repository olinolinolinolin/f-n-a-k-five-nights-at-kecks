@tool
extends EditorPlugin

const LITE_AUTOLOAD := "res://addons/savestate/save_manager.gd"
const PRO_AUTOLOAD := "res://addons/savestate_pro/pro_manager.gd"
const LITE_PLUGIN_CFG := "res://addons/savestate/plugin.cfg"
const PRO_PLUGIN_CFG := "res://addons/savestate_pro/plugin.cfg"
const EDITOR_PLUGINS_ENABLED := "editor_plugins/enabled"

var _saveable_inspector: EditorInspectorPlugin
var _debugger_plugin: EditorDebuggerPlugin
var _quick_setup_menu_added: bool = false


func get_plugin_name() -> String:
	return "SaveState Pro"


func _hook_save_browser_debugger() -> void:
	# Dock is created by SaveState Lite; attach debugger once the tree exists.
	var nodes := get_tree().get_nodes_in_group("savestate_save_browser")
	for n in nodes:
		if n != null and n.has_method("set_debugger_plugin"):
			n.call("set_debugger_plugin", _debugger_plugin)
			print("[SaveState Pro] Save Browser dock debugger hook attached")
			return


func _lite_addon_present() -> bool:
	# plugin.cfg is not a loadable Resource — ResourceLoader.exists() is false even when Lite is installed.
	return FileAccess.file_exists(LITE_PLUGIN_CFG) and FileAccess.file_exists(LITE_AUTOLOAD)


func _enter_tree() -> void:
	# Do not register autoload, inspector, or debugger until Lite exists — half-initialized Pro breaks the editor.
	if not _lite_addon_present():
		push_error(
			"SaveState Pro: addons/savestate/ (SaveState Lite) is missing. "
			+ "Copy BOTH addons into your project: addons/savestate/ and addons/savestate_pro/."
		)
		call_deferred("_show_lite_missing_dialog")
		return
	_ensure_lite_plugin_dependency()
	print("[SaveState Pro] plugin _enter_tree: registering project settings + Pro autoload (Save Browser dock is registered by SaveState Lite)")
	_register_pro_project_settings()
	if ProjectSettings.has_setting("autoload/SaveManager"):
		remove_autoload_singleton("SaveManager")
	add_autoload_singleton("SaveManager", PRO_AUTOLOAD)
	print("[SaveState Pro] autoload SaveManager → ", PRO_AUTOLOAD)
	_saveable_inspector = preload("res://addons/savestate_pro/editor/saveable_inspector_plugin.gd").new()
	add_inspector_plugin(_saveable_inspector)
	print("[SaveState Pro] Saveable inspector plugin enabled")
	_debugger_plugin = preload("res://addons/savestate_pro/editor/savestate_debugger_plugin.gd").new()
	add_debugger_plugin(_debugger_plugin)
	call_deferred("_hook_save_browser_debugger")
	print("[SaveState Pro] Debugger plugin enabled")
	add_tool_menu_item("SaveState Pro/Quick Setup: Add Saveable to selection", Callable(self, "_quick_setup_add_saveable"))
	_quick_setup_menu_added = true
	print("[SaveState Pro] Tool menu: Quick Setup added")


func _exit_tree() -> void:
	print("[SaveState Pro] plugin _exit_tree: restoring Lite autoload (Save Browser dock is owned by SaveState Lite)")
	if _quick_setup_menu_added:
		remove_tool_menu_item("SaveState Pro/Quick Setup: Add Saveable to selection")
		_quick_setup_menu_added = false
	if _debugger_plugin:
		remove_debugger_plugin(_debugger_plugin)
		_debugger_plugin = null
	if _saveable_inspector:
		remove_inspector_plugin(_saveable_inspector)
		_saveable_inspector = null
	if ProjectSettings.has_setting("autoload/SaveManager"):
		remove_autoload_singleton("SaveManager")
	add_autoload_singleton("SaveManager", LITE_AUTOLOAD)
	print("[SaveState Pro] autoload SaveManager → ", LITE_AUTOLOAD)


func _quick_setup_add_saveable() -> void:
	var sel := get_editor_interface().get_selection()
	if sel == null:
		return
	var nodes: Array = sel.get_selected_nodes()
	if nodes.is_empty():
		push_warning("SaveState Pro: Quick Setup: no nodes selected")
		return

	var ur := get_undo_redo()
	ur.create_action("SaveState Pro: Add Saveable")
	for n in nodes:
		if not (n is Node):
			continue
		var node: Node = n
		var already := false
		for c in node.get_children():
			if c is Saveable:
				already = true
				break
		if already:
			continue
		var s := Saveable.new()
		s.name = "Saveable"
		# Default preset: only add if properties exist.
		var valid := {}
		for p in node.get_property_list():
			valid[str(p.get("name", ""))] = true
		var allow: Array[String] = []
		for pname in ["global_position", "position", "velocity", "health", "mana", "gold", "level"]:
			if valid.has(pname):
				allow.append(pname)
		if not allow.is_empty():
			s.property_allowlist = allow
		ur.add_do_method(node, "add_child", s, true)
		ur.add_do_method(s, "set_owner", node.owner)
		ur.add_undo_method(node, "remove_child", s)
	ur.commit_action()


func _has_main_screen() -> bool:
	return false


func _register_pro_project_settings() -> void:
	const KEYS := [
		["savestate_pro/encryption_enabled", false],
		["savestate_pro/aes_key_hex", ""],
		["savestate_pro/hmac_key_hex", ""],
	]
	for item in KEYS:
		var k: String = str(item[0])
		if not ProjectSettings.has_setting(k):
			ProjectSettings.set_setting(k, item[1])
			var t := typeof(item[1])
			var info := {"name": k, "type": t}
			ProjectSettings.add_property_info(info)


func _plugin_enabled_list_contains(enabled: PackedStringArray, plugin_cfg: String) -> bool:
	for p in enabled:
		if str(p) == plugin_cfg:
			return true
	return false


func _ensure_lite_plugin_dependency() -> void:
	if not ProjectSettings.has_setting(EDITOR_PLUGINS_ENABLED):
		return
	var enabled: PackedStringArray = ProjectSettings.get_setting(EDITOR_PLUGINS_ENABLED)
	if _plugin_enabled_list_contains(enabled, LITE_PLUGIN_CFG):
		_ensure_lite_before_pro_in_enabled_list(enabled)
		return
	var new_enabled: PackedStringArray = enabled.duplicate()
	new_enabled.insert(0, LITE_PLUGIN_CFG)
	ProjectSettings.set_setting(EDITOR_PLUGINS_ENABLED, new_enabled)
	ProjectSettings.save()
	push_warning(
		"SaveState Pro: SaveState (Lite) was not enabled in Project Settings → Plugins. "
		+ "It has been added automatically. Restart the Godot editor so Lite loads (Save Browser dock + shared base)."
	)
	call_deferred("_show_lite_auto_enabled_dialog")


func _ensure_lite_before_pro_in_enabled_list(enabled: PackedStringArray) -> void:
	var li := -1
	var pi := -1
	for i in range(enabled.size()):
		var s := str(enabled[i])
		if s == LITE_PLUGIN_CFG:
			li = i
		if s == PRO_PLUGIN_CFG:
			pi = i
	if li < 0 or pi < 0 or li <= pi:
		return
	var arr: Array = Array(enabled)
	var lite_path: String = str(arr[li])
	arr.remove_at(li)
	pi = arr.find(PRO_PLUGIN_CFG)
	if pi < 0:
		return
	arr.insert(pi, lite_path)
	ProjectSettings.set_setting(EDITOR_PLUGINS_ENABLED, PackedStringArray(arr))
	ProjectSettings.save()
	push_warning(
		"SaveState Pro: Reordered Project Settings → Plugins so SaveState (Lite) loads before SaveState Pro. Restart the editor."
	)


func _show_lite_missing_dialog() -> void:
	var dlg := AcceptDialog.new()
	dlg.title = "SaveState Pro"
	dlg.dialog_text = (
		"The SaveState Lite addon folder is missing.\n\n"
		+ "SaveState Pro depends on addons/savestate/ (Lite). Copy BOTH addons into your project, then enable SaveState (Lite) in Project → Project Settings → Plugins."
	)
	dlg.ok_button_text = "OK"
	# Project Settings (Plugins) already holds an exclusive modal; do not stack another exclusive popup.
	dlg.exclusive = false
	var base := get_editor_interface().get_base_control()
	base.add_child(dlg)
	dlg.popup_centered()
	dlg.confirmed.connect(func() -> void:
		if is_instance_valid(dlg):
			dlg.queue_free()
	)


func _show_lite_auto_enabled_dialog() -> void:
	var dlg := AcceptDialog.new()
	dlg.title = "SaveState Pro"
	dlg.dialog_text = (
		"SaveState (Lite) was not enabled. It has been added to Project Settings → Plugins automatically.\n\n"
		+ "Restart the Godot editor so Lite loads. The Save Browser dock is provided by Lite; Pro stacks on top."
	)
	dlg.ok_button_text = "OK"
	dlg.exclusive = false
	var base := get_editor_interface().get_base_control()
	base.add_child(dlg)
	dlg.popup_centered()
	dlg.confirmed.connect(func() -> void:
		if is_instance_valid(dlg):
			dlg.queue_free()
	)
