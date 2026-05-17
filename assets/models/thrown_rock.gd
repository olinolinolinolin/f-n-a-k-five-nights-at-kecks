extends RigidBody3D
@export var RockPlayer : AudioStreamPlayer3D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass



func _on_rock_area_check_body_entered(body: Node3D) -> void:
	if body.is_in_group("Enemy"):
		var parent = body.get_parent()
		if parent.has_method("stun"):
			pass
			makenoise(global_position)
			queue_free()
		if body.has_method("stun"):
			pass
			makenoise(global_position)
			queue_free()
	if body.is_in_group("Enviroment"):
		makenoise(global_position)
		queue_free()



func _on_timer_timeout() -> void:
	queue_free()


func makenoise(pos):
	RockPlayer.play()
	var Enemies = get_tree().get_nodes_in_group("Enemy")
	for i in Enemies:
		print(i.global_position.distance_to(pos))
		if i.global_position.distance_to(pos) < 5.0:
			if i.has_method("Hunt"):
				i.Hunt(pos)
		if i.global_position.distance_to(pos) < 15.0 and i.global_position.distance_to(pos) > 5:
			if i.has_method("Alert"):
				i.Alert(pos)


func _on_rock_area_check_area_entered(area: Area3D) -> void:
	if area.is_in_group("EnemyHead"):
		var parent = area.get_parent()
		if parent.has_method("stun"):
			parent.stun()
			queue_free()
		makenoise(global_position)
