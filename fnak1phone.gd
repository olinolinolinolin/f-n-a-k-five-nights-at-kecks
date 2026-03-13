extends StaticBody3D
class_name fnak1phone

@onready var phone_body: fnak1phone = $"."
@onready var phone_screen: MeshInstance3D = $PhoneScreen
@onready var sub_viewport: SubViewport = $PhoneScreen/SubViewport





# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	input_event.connect(_on_input_event)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _on_input_event(camera: Node, event: InputEvent, event_position: Vector3, normal: Vector3, shape_idx: int) -> void:
	var mouse3D = phone_screen.global_transform.affine_inverse() * event_position
	var calculate2DPosition = Vector2(mouse3D.x, mouse3D.z)

	var planeSize = phone_screen.mesh.size
	calculate2DPosition += planeSize / 2
	calculate2DPosition /= planeSize
	
	var mouse2D = calculate2DPosition * Vector2(sub_viewport.size)
	
	event.position = mouse2D

	sub_viewport.push_input(event)
