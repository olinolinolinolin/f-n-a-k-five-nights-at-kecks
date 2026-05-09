extends CharacterBody3D

@export var NavMap : NavigationRegion3D
@export var playerdetected: bool = false
@onready var bt_player: BTPlayer = $BTPlayer
var playerpos : Vector3
const SPEED = 5.0
const JUMP_VELOCITY = 4.5
enum AlertState {Passive,Alert,Hunting,Chase}
@export var CurrentState : AlertState



func _ready() -> void:
	bt_player.active = false
	
	var player = get_tree().get_first_node_in_group("Player")
	
	bt_player.blackboard.set_var("player", player)
	
	bt_player.active = true
	
	
func attack():
	print("get attacked")

func stun():
	print("ooof")

func get_random_point() -> Vector3:
	var randompoint = NavigationServer3D.map_get_random_point(NavMap.get_navigation_map(), 1, true)
	return randompoint
	bt_player.blackboard.set_var("pos",randompoint)

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

func Alert():
	CurrentState = AlertState.Alert

func Hunt():
	CurrentState = AlertState.Hunting
