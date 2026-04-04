@tool
extends EditorDebuggerPlugin

const LOG_PREFIX := "[SaveState Pro | Debugger]"

var _sessions: Dictionary = {} # int -> EditorDebuggerSession


func _has_capture(prefix: String) -> bool:
	return prefix == "savestate_pro"


func _setup_session(session_id: int) -> void:
	var s := get_session(session_id)
	if s != null:
		_sessions[session_id] = s


func _end_session(session_id: int) -> void:
	_sessions.erase(session_id)


func has_active_session() -> bool:
	return not _sessions.is_empty()


func send_kv_patch(patch: Dictionary) -> bool:
	if _sessions.is_empty():
		return false
	# Use the first active session.
	for sid in _sessions.keys():
		var s: EditorDebuggerSession = _sessions[sid]
		if s == null:
			continue
		# Prefix capture "savestate_pro" will receive "savestate_pro:apply_kv_patch".
		s.send_message("savestate_pro:apply_kv_patch", [patch])
		return true
	return false

