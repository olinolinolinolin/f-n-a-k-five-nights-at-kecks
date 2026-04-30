extends RigidBody3D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass



func _on_rock_area_check_body_entered(body: Node3D) -> void:
	if body.is_in_group("Enemy"):
		var parent = body.get_parent()
		if parent.has_method("stun"):
			parent.stun()
			queue_free()
		if body.has_method("stun"):
			body.stun()
			queue_free()


func _on_timer_timeout() -> void:
	queue_free()
