extends Node3D
@onready var camera = $"Player Camera"
@onready var phone = $"Player Camera/Phone"
var phoneinface = false
var phonelighton = true
var hiding = false
signal dead
signal usingphone



var phonelocations = [Vector3(0.678,0.042,-1.01),Vector3(0,0,-.50)]

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
	


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	
	if Input.get_connected_joypads().size() > 0 and hiding == false:
		if Input.is_action_pressed("joystickleft"):
			camera.rotate_y(1 * delta) 
		if Input.is_action_pressed("joystickright"):
			camera.rotate_y(-1 * delta) 
		if Input.is_action_pressed("joystickup"):
			camera.rotate_x(-1* delta)
		if Input.is_action_pressed("joystickdown"):
			camera.rotate_x(1 * delta)
			
	camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-30), deg_to_rad(30))
	camera.rotation.z = clamp(camera.rotation.z,deg_to_rad(0),deg_to_rad(0))
	
	
	if Input.is_action_just_pressed("phone") and hiding == false:
		if phoneinface == false:
			var tween = create_tween()
			tween.tween_property(phone, "position",phonelocations[1],.25)
			await tween.finished
			phoneinface = true
			Input.mouse_mode = Input.MOUSE_MODE_CONFINED
			usingphone.emit(true)
			
		else:
			var tween = create_tween()
			tween.tween_property(phone, "position",phonelocations[0],.5)
			phoneinface = false
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
			usingphone.emit(false)
	if Input.is_action_just_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		
	if Input.is_action_just_pressed("hide"):
		if hiding == true:
			$"../HideBasic".hide()
			hiding = false
			usingphone.emit(true)
		else:
			$"../HideBasic".show()
			hiding = true
			usingphone.emit(false)
func _unhandled_input(event: InputEvent):
	camera_rotation(event)

func camera_rotation(event: InputEvent):
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		camera.rotate_y(-event.relative.x * .001)
		
		camera.rotate_x(event.relative.y * .001)
		camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-30), deg_to_rad(30))
		camera.rotation.z = clamp(camera.rotation.z,deg_to_rad(0),deg_to_rad(0))



func _on_phone_screen_texture_light_off() -> void:
	if phonelighton == true:
		$"Player Camera/Phone/PhoneLight".hide()
		phonelighton = false
	else:
		$"Player Camera/Phone/PhoneLight".show()
		phonelighton = true
	


func _on_keckbear_attackplayer() -> void:
	if hiding == true:
		print("living")
	else:
		print("dead af")
	dead.emit(hiding)
