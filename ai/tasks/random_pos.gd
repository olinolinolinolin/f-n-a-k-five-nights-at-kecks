extends BTAction

func _tick(delta: float) -> Status:	
	
	var pos: Vector3 = agent.global_transform.origin
	if agent.waited == true:
		pos = agent.get_random_point()
		blackboard.set_var("pos", pos)
	else:
		return FAILURE
	
	return SUCCESS
