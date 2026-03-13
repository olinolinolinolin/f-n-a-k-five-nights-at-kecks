extends Node3D
@onready var camera = $"Player Camera"
@onready var phone = $"Player Camera/Phone"
var phoneinface = false



var phonelocations = [Vector3(0.678,0.042,-1.01),Vector3(0,0,-.50)]

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
	


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if Input.is_action_just_pressed("ui_accept"):
		if phoneinface == false:
			var tween = create_tween()
			tween.tween_property(phone, "position",phonelocations[1],.25)
			await tween.finished
			phoneinface = true
			Input.mouse_mode = Input.MOUSE_MODE_CONFINED
			
		else:
			var tween = create_tween()
			tween.tween_property(phone, "position",phonelocations[0],.5)
			phoneinface = false
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
			
func _unhandled_input(event: InputEvent):
	camera_rotation(event)

func camera_rotation(event: InputEvent):
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		camera.rotate_y(-event.relative.x * .001)
		
		camera.rotate_x(event.relative.y * .001)
		camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-30), deg_to_rad(30))
		camera.rotation.z = clamp(camera.rotation.z,0,0)
