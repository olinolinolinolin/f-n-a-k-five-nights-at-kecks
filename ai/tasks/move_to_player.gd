extends BTAction

@export var speed: float = 4.0
@export var target_var: StringName = &"player"

var _nav: NavigationAgent3D

func _setup() -> void:
	_nav = agent.get_node("NavigationAgent3D")

func _tick(delta: float) -> Status:
	var target = blackboard.get_var("player", null)
	
	if not is_instance_valid(target):
		return FAILURE
	
	_nav.target_position = target.global_position
	
	if _nav.target_position.distance_to(agent.global_transform.origin) < 1.5:
		agent.velocity = Vector3.ZERO
		return SUCCESS
	
	
	
	
	var next_pos = _nav.get_next_path_position()
	var direction = (next_pos - agent.global_position).normalized()
	direction.y = 0.0
	
	var enemy = agent as CharacterBody3D
	enemy.velocity = direction * speed
	enemy.move_and_slide()
	
	return RUNNING
