extends SaveManagerBase
## Pro autoload script: async save/load via [WorkerThreadPool], optional AES+HMAC via [method _pre_write_transform] / [method _post_read_transform].

@export var encryption_enabled: bool = false


func _ready() -> void:
	backup_on_commit = true
	super._ready()


func _execute_debounced_persist() -> void:
	persist_async(dirty_persist_includes_saveables, true)


## Sync [method SaveManagerBase.persist] skips [method persist_async]; still capture [code]slot_0.jpg[/code] so simple games get thumbnails.
func persist() -> Error:
	_capture_kv_thumbnail(KV_SLOT_ID)
	return super.persist()


func persist_including_saveables() -> Error:
	_capture_kv_thumbnail(KV_SLOT_ID)
	return super.persist_including_saveables()


## Writes [code]slot_N.jpg[/code] next to the named slot when exporting (Save Browser / Pro menu expect this naming).
func export_current_to_slot(slot_id: StringName) -> Error:
	_capture_kv_thumbnail(slot_id)
	return super.export_current_to_slot(slot_id)


## Async flush: optional viewport thumbnail ([code]slot_0.jpg[/code]), includes [method SaveManagerBase.gather_saveable_snapshots] under [code]__saveables[/code].
## Snapshot phase: runs on the main thread — [method SaveManagerBase._hydrate_kv_if_needed], duplicate KV map, [method SaveManagerBase.gather_saveable_snapshots], then [method save_slot_async] deep-duplicates again before [WorkerThreadPool] I/O. Game state can change during the worker; the serialized bytes always match the snapshot taken before the thread started.
func persist_async(include_saveables: bool = true, capture_thumbnail: bool = true) -> void:
	save_requested.emit()
	_hydrate_kv_if_needed()
	if capture_thumbnail:
		_capture_kv_thumbnail(KV_SLOT_ID)
	var data := _kv_data.duplicate(true)
	if include_saveables:
		data["__saveables"] = gather_saveable_snapshots()
	save_slot_async(KV_SLOT_ID, data)


func _capture_kv_thumbnail(slot_id: StringName = KV_SLOT_ID) -> void:
	var vp := get_viewport()
	if vp == null:
		return
	var tex := vp.get_texture()
	if tex == null:
		return
	var img: Image = tex.get_image()
	if img == null:
		return
	img = img.duplicate() as Image
	var w := img.get_width()
	var h := img.get_height()
	if w < 2 or h < 2:
		return
	img.resize(256, 256, Image.INTERPOLATE_LANCZOS)
	# Slot ids are normally [code]slot_0[/code], [code]slot_1[/code], … (file base name without extension).
	var base := str(slot_id)
	var out_path := save_root.path_join(base + ".jpg")
	var err := img.save_jpg(out_path, 0.85)
	if err != OK:
		push_warning("SaveState Pro: thumbnail save failed: %s" % str(err))


func _thread_save_impl(path: String, data: Dictionary) -> Error:
	var payload := _serialize_envelope(data)
	var flags := FLAG_JSON if use_json else 0
	var file_bytes := _compose_file_bytes(FORMAT_VERSION, get_current_schema_version(), flags, payload)
	var final_bytes := _pre_write_transform(file_bytes)
	return AtomicWriter.write_atomic(path, final_bytes, backup_on_commit)


## Deep-copies [param data] on the main thread before scheduling [method _thread_save_impl] on a worker. Prevents torn or mixed state if nodes mutate while async save runs.
func save_slot_async(slot_id: StringName, data: Dictionary) -> void:
	save_started.emit(slot_id)
	var slot: SaveSlot = _slots.get(slot_id) as SaveSlot
	if slot == null:
		call_deferred("_emit_save_failed", slot_id, ERR_DOES_NOT_EXIST)
		return

	var snapshot := data.duplicate(true)
	var path := slot.get_file_path(save_root, use_json)
	WorkerThreadPool.add_task(
		func() -> void:
			var err := _thread_save_impl(path, snapshot)
			call_deferred("_emit_save_result", slot_id, err)
	)


func _emit_save_failed(slot_id: StringName, err: int) -> void:
	save_failed.emit(slot_id, err)


func _emit_save_result(slot_id: StringName, err: int) -> void:
	var slot: SaveSlot = _slots.get(slot_id) as SaveSlot
	if slot and err == OK:
		slot.last_modified_unix = int(Time.get_unix_time_from_system())
		slot.file_schema_version = get_current_schema_version()
	if err == OK:
		save_completed.emit(slot_id)
	else:
		save_failed.emit(slot_id, err)


func load_slot_async(slot_id: StringName) -> void:
	load_started.emit(slot_id)
	var slot: SaveSlot = _slots.get(slot_id) as SaveSlot
	if slot == null:
		call_deferred("_emit_load_failed", slot_id, ERR_DOES_NOT_EXIST)
		return

	var path := slot.get_file_path(save_root, use_json)
	WorkerThreadPool.add_task(
		func() -> void:
			var res := _thread_load_raw(path)
			call_deferred("_finish_load_async", slot_id, slot, res)
	)


func _thread_load_raw(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {"err": ERR_FILE_NOT_FOUND, "processed": PackedByteArray()}

	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {"err": FileAccess.get_open_error(), "processed": PackedByteArray()}
	var raw := file.get_buffer(file.get_length())
	file.close()
	var processed := _post_read_transform(raw)
	return {"err": OK, "processed": processed}


func _finish_load_async(slot_id: StringName, slot: SaveSlot, res: Dictionary) -> void:
	var err: int = int(res.get("err", ERR_FILE_CANT_OPEN))
	if err != OK:
		load_failed.emit(slot_id, err)
		return

	var processed: PackedByteArray = res.get("processed", PackedByteArray()) as PackedByteArray
	var pr := parse_save_file_buffer(processed)
	if not pr.get("ok", false):
		load_failed.emit(slot_id, int(pr.get("error", ERR_FILE_CORRUPT)))
		return

	var inner: Dictionary = pr["data"] as Dictionary
	slot.file_schema_version = int(pr.get("schema_version", 0))
	load_completed.emit(slot_id, inner)


func _emit_load_failed(slot_id: StringName, err: int) -> void:
	load_failed.emit(slot_id, err)


func _pre_write_transform(file_bytes: PackedByteArray) -> PackedByteArray:
	if not encryption_enabled:
		return super._pre_write_transform(file_bytes)
	var aes := _get_aes_key()
	var hmac := _get_hmac_key()
	if aes.size() != SaveSecurity.AES_KEY_SIZE or hmac.is_empty():
		push_warning("SaveState Pro: encryption enabled but keys invalid; writing plain.")
		return file_bytes
	return SaveSecurity.seal_inner_save_file(file_bytes, aes, hmac)


func _post_read_transform(raw: PackedByteArray) -> PackedByteArray:
	if raw.is_empty():
		return raw
	var h := SaveFormat.parse_header(raw)
	if int(h.get("error", OK)) != OK:
		return super._post_read_transform(raw)
	if int(h.get("format_version", 0)) != SaveSecurity.OUTER_FORMAT_VERSION:
		return super._post_read_transform(raw)
	if not encryption_enabled:
		return raw
	var aes := _get_aes_key()
	var hmac := _get_hmac_key()
	if aes.size() != SaveSecurity.AES_KEY_SIZE or hmac.is_empty():
		return super._post_read_transform(raw)
	var opened := SaveSecurity.open_outer_save_file(raw, aes, hmac)
	if int(opened.get("error", ERR_FILE_CORRUPT)) != OK:
		return raw
	return opened.get("inner", PackedByteArray()) as PackedByteArray


func _get_aes_key() -> PackedByteArray:
	var s: String = str(ProjectSettings.get_setting("savestate_pro/aes_key_hex", ""))
	return SaveSecurity.key_from_hex(s)


func _get_hmac_key() -> PackedByteArray:
	var s: String = str(ProjectSettings.get_setting("savestate_pro/hmac_key_hex", ""))
	return SaveSecurity.key_from_hex(s)


func _get_debug_crypto_keys() -> Dictionary:
	return {"aes": _get_aes_key(), "hmac": _get_hmac_key()}
