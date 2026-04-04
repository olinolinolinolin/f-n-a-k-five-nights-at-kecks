@tool
extends Node
class_name Saveable
## Collects snapshot [Dictionary] from parent (or self). Add to scene, set [member storage_key], add [code]save_[/code] exports on the parent — zero manual dictionary wiring for common cases.

@export var storage_key: StringName = &"entity"
## If set, only these properties are saved (overrides prefix/metadata when non-empty).
@export var property_allowlist: Array[String] = []
@export var property_prefix: String = "save_"
@export var use_metadata_filter: bool = true
## When enabled, any picked properties can be mirrored onto the parent as `savestate_*` metadata flags
## (useful for teams: you can see what will be saved without selecting the Saveable).
var _write_parent_metadata_flags: bool = false
@export var write_parent_metadata_flags: bool:
	get:
		return _write_parent_metadata_flags
	set(v):
		_write_parent_metadata_flags = v
		if Engine.is_editor_hint():
			_apply_parent_metadata_from_allowlist()
## When on a chest/door, set parent [code]opened[/code] bool and enable this to persist open state without extra code.
@export var auto_sync_parent_opened: bool = false


func _enter_tree() -> void:
	add_to_group("savestate_saveable")
	if Engine.is_editor_hint():
		_apply_parent_metadata_from_allowlist()


func _exit_tree() -> void:
	if is_instance_valid(self):
		remove_from_group("savestate_saveable")


func get_storage_key() -> StringName:
	return storage_key


func collect_snapshot() -> Dictionary:
	var target: Node = get_parent() if get_parent() else self
	var out: Dictionary
	if not property_allowlist.is_empty():
		out = _collect_allowlist(target)
	else:
		out = _collect_from_node(target)
	if auto_sync_parent_opened:
		for p in target.get_property_list():
			if str(p.get("name", "")) == "opened":
				out["opened"] = bool(target.get("opened"))
				break
	return out


func _collect_allowlist(node: Node) -> Dictionary:
	var out := {}
	var valid := {}
	for p in node.get_property_list():
		valid[str(p.get("name", ""))] = true
	for pname in property_allowlist:
		if pname.is_empty():
			continue
		if valid.has(pname):
			out[pname] = node.get(pname)
	return out


func apply_snapshot(data: Dictionary) -> void:
	var target: Node = get_parent() if get_parent() else self
	for key in data:
		target.set(str(key), data[key])


func _collect_from_node(node: Node) -> Dictionary:
	var out := {}
	for prop in node.get_property_list():
		var pname: String = str(prop.get("name", ""))
		if pname == "script" or pname.begins_with("_"):
			continue
		if use_metadata_filter:
			var mk := "savestate_%s" % pname
			if node.has_meta(mk) and bool(node.get_meta(mk)):
				out[pname] = node.get(pname)
				continue
		if not property_prefix.is_empty() and pname.begins_with(property_prefix):
			out[pname] = node.get(pname)
	return out


func _apply_parent_metadata_from_allowlist() -> void:
	if not write_parent_metadata_flags:
		return
	var parent := get_parent()
	if parent == null:
		return
	var allow := {}
	for name in property_allowlist:
		var s := str(name)
		if not s.is_empty():
			allow[s] = true
	for k in allow:
		parent.set_meta("savestate_%s" % str(k), true)
	# Cleanup anything we previously set that is no longer selected.
	var meta := parent.get_meta_list()
	for mk in meta:
		var mks := str(mk)
		if not mks.begins_with("savestate_"):
			continue
		var pname := mks.trim_prefix("savestate_")
		if not allow.has(pname):
			parent.remove_meta(mks)
