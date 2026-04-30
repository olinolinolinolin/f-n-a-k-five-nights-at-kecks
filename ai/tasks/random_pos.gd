extends BTAction

func _tick(delta: float) -> Status:	
	
	var pos: Vector3 = agent.global_transform.origin
	pos = agent.get_random_point()
	blackboard.set_var("pos", pos)
	
	return SUCCESS
