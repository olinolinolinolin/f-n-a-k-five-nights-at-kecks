extends BTAction

func _tick(_delta: float) -> Status:
	var target_pos: Vector3 = blackboard.get_var("pos")
	var current_pos: Vector3 = agent.global_transform.origin
	
	agent.move(target_pos, _delta)
	
	if Vector3(current_pos.x, 0, current_pos.z).distance_to(Vector3(target_pos.x, 0, target_pos.z)) <0.1:
		agent.velocity = Vector3.ZERO
		return SUCCESS
	
	return RUNNING
