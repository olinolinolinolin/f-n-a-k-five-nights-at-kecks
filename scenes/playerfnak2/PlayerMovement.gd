extends CharacterBody3D
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
@export var PlayerHead: Node3D
@export var PlayerCam: Camera3D
@export var HeadAnimPlayer: AnimationPlayer
const Speed = 5.0
const JumpVelocity = 4.5



func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	elif event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	
	if Input.is_action_just_pressed("NickFlash"):
		HeadAnimPlayer.play("NickFlashAnim")
	
	if event is InputEventMouseMotion:
		rotate_y(-event.relative.x*0.005)
		PlayerCam.rotate_x(-event.relative.y*0.005)
		PlayerCam.rotation.x = clamp(PlayerCam.rotation.x, deg_to_rad(-60), deg_to_rad(60))

func _physics_process(delta: float) -> void:
	
	if not is_on_floor():
		velocity.y -= gravity * delta
	
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JumpVelocity
	
	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_backwards")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * Speed
		velocity.z = direction.z * Speed
	else:
		velocity.x = move_toward(velocity.x, 0, Speed)
		velocity.z = move_toward(velocity.z, 0, Speed)


	move_and_slide()
