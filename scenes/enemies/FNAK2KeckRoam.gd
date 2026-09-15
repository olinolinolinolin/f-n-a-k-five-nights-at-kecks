extends CharacterBody3D

@export var NavMap : NavigationRegion3D
@export var playerdetected: bool = false
@onready var bt_player: BTPlayer = $BTPlayer
@onready var HuntAlertCD = $Hunt_Alert
var playerpos : Vector3
const SPEED = 5.0
const JUMP_VELOCITY = 4.5
enum AlertState {Passive,Alert,Hunting,Chase}
@export var CurrentState : AlertState
@export var Keckeyes: RayCast3D
var playerinrange: bool = false
var stunned = false
var waited = false
var waittime = 0



func _ready() -> void:
	bt_player.active = false
	
	var player = get_tree().get_first_node_in_group("Player")
	
	bt_player.blackboard.set_var("player", player)
	
	bt_player.active = true
	
	$keckbearrunning/AnimationPlayer.play("mixamo_com")
	
	
	
func attack():
	print("get attacked")
	bt_player.active = false
	var player = get_tree().get_first_node_in_group("PlayerUI")
	player.GetScared()
	hide()

func stun():
	bt_player.active = false
	stunned = true
	print("stunned")
	velocity = Vector3(0,0,0)
	await get_tree().create_timer(3).timeout
	stunned = false
	bt_player.blackboard.set_var("pos", bt_player.blackboard.get_var("player").global_position)
	CurrentState = AlertState.Chase
	bt_player.active = true

func get_random_point() -> Vector3:
	var randompoint = NavigationServer3D.map_get_random_point(NavMap.get_navigation_map(), 1, false)
	bt_player.blackboard.set_var("pos",randompoint)
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
	
	waittime += 1 * delta
	if waittime >= 1.0:
		waited =  true
	
	if stunned == true:
		velocity = Vector3.ZERO
	
	if not is_on_floor():
		velocity += get_gravity() * delta
	if stunned == false:
		CanSeePlayer()
		
		if playerinrange:
			if CanSeePlayer():
				CurrentState = AlertState.Chase
				bt_player.blackboard.set_var("pos",bt_player.blackboard.get_var("player").global_position)
			else:
				if CurrentState == AlertState.Chase:
					CurrentState = AlertState.Hunting
		else:
			if CurrentState != AlertState.Hunting and CurrentState != AlertState.Chase:
				CurrentState = AlertState.Passive

		move_and_slide()

func CanSeePlayer():
	var player = bt_player.blackboard.get_var("player")
	Keckeyes.target_position = to_local(player.global_position)
	Keckeyes.force_raycast_update()
	
	if Keckeyes.is_colliding():
		if Keckeyes.get_collider().has_method("is_in_group"):
			return Keckeyes.get_collider().is_in_group("Player")
	return false

func Alert(pos):
	if CurrentState != AlertState.Chase:
		CurrentState = AlertState.Alert
		bt_player.blackboard.set_var("pos",pos)

func Hunt(pos):
	if CurrentState != AlertState.Chase:
		CurrentState = AlertState.Hunting
		bt_player.blackboard.set_var("pos",pos)


func _on_hunt_alert_timeout() -> void:
	CurrentState = AlertState.Passive

func cooldown():
	HuntAlertCD.start()


func _on_detection_area_body_entered(body: Node3D) -> void:
	if body.is_in_group("Player"):
		playerinrange = true



func _on_detection_area_body_exited(body: Node3D) -> void:
	if body.is_in_group("Player"):
		playerinrange = false
		CurrentState = AlertState.Hunting
		bt_player.blackboard.set_var("pos",body.global_position)
