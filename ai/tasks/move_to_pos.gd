extends BTAction

@export var speed: float = 4.0

var _nav: NavigationAgent3D

func _setup() -> void:
	_nav = agent.get_node("NavigationAgent3D")

func _tick(delta: float) -> Status:
	var target_pos: Vector3 = blackboard.get_var("pos")
	
	_nav.target_position = target_pos
	
	if _nav.is_navigation_finished():
		agent.velocity = Vector3.ZERO
		return SUCCESS
	
	var next_pos = _nav.get_next_path_position()
	var direction = (next_pos - agent.global_position).normalized()
	direction.y = 0.0
	
	var current_pos: Vector3 = agent.global_transform.origin
	var enemy = agent as CharacterBody3D
	enemy.velocity = direction * speed
	
	if agent.velocity.length_squared() > 0.01:
		var look_target := current_pos + Vector3(agent.velocity.x, 0, agent.velocity.z)
		agent.look_at(look_target, Vector3.UP)
	
	enemy.move_and_slide()
	
	return RUNNING
