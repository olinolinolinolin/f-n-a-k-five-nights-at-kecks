extends BTAction

@export var search_radius: float = 6.0
@export var speed: float = 5.0
@export var turn_speed: float = 8.0

var search_queue: Array[Vector3] = []
var rng = RandomNumberGenerator.new()
var _nav: NavigationAgent3D


func _setup() -> void:
	_nav = agent.get_node("NavigationAgent3D")


func _enter() -> void:
	search_queue.clear()
	
	var last_known_pos: Vector3 = blackboard.get_var("pos")
	var nav_map = agent.NavMap.get_navigation_map()
	
	# Generate 3 random snapped points around the last known position
	for i in range(3):
		var random_direction = Vector3(rng.randf_range(-1.0, 1.0), 0, rng.randf_range(-1.0, 1.0)).normalized()
		var random_distance = rng.randf_range(0.0, search_radius)
		var random_point = last_known_pos + random_direction * random_distance
		var snapped_point = NavigationServer3D.map_get_closest_point(nav_map, random_point)
		search_queue.append(snapped_point)
	
	# Sort by nearest to agent first
	var agent_pos = agent.global_transform.origin
	search_queue.sort_custom(func(a, b): return a.distance_to(agent_pos) < b.distance_to(agent_pos))
	
	# Set first target immediately
	if not search_queue.is_empty():
		_nav.target_position = search_queue[0]


func _tick(delta: float) -> Status:
	if search_queue.is_empty():
		return SUCCESS
	
	var current_pos: Vector3 = agent.global_transform.origin
	
	if _nav.is_navigation_finished():
		agent.velocity = Vector3.ZERO
		search_queue.pop_front()
		if not search_queue.is_empty():
			_nav.target_position = search_queue[0]
		return RUNNING
	
	var next_pos = _nav.get_next_path_position()
	var direction = (next_pos - agent.global_position).normalized()
	direction.y = 0.0
	agent.velocity = direction * speed
	
	if agent.velocity.length_squared() > 0.01:
		var target_angle = atan2(-direction.x, -direction.z)
		agent.rotation.y = rotate_toward(agent.rotation.y, target_angle, turn_speed * delta)
	
	agent.move_and_slide()
	
	return RUNNING
