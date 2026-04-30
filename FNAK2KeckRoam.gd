extends CharacterBody3D

@export var NavMap : NavigationRegion3D

const SPEED = 5.0
const JUMP_VELOCITY = 4.5

func stun():
	print("ooof")

func get_random_point() -> Vector3:
	var randompoint = NavigationServer3D.map_get_random_point(NavMap.get_navigation_map(), 1, true)
	print(randompoint)
	return randompoint

func move(target_pos: Vector3, delta: float):
	var direction = Vector3(
		target_pos.x - global_transform.origin.x,
		0,
		target_pos.z - global_transform.origin.z
	).normalized()
	
	velocity.x = direction.x * SPEED
	velocity.z = direction.z * SPEED


func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta



	move_and_slide()
