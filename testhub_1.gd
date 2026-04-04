extends Node3D

@onready var your_subviewport: SubViewport = $"Player/Player Camera/Phone/PhoneBody/PhoneScreen/SubViewport"

var checkpoint := int(SaveManager.get_value(&"playercheckpoint", 0))

var KeckbearFlashed = false
signal lightonshadow


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	savecheckpoint()




# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if Input.is_action_just_pressed("ui_accept"):
		checkpoint += 1
		savecheckpoint()


func _on_flash_light_area_body_entered(body: Node3D) -> void:
	if body.is_in_group("Shadow") == true:
		KeckbearFlashed = true
		print("flashing")
		lightonshadow.emit(KeckbearFlashed)


func _on_flash_light_area_body_exited(body: Node3D) -> void:
	if body.is_in_group("Shadow") == true:
		KeckbearFlashed = false
		print("no flashing")
		lightonshadow.emit(KeckbearFlashed)

func _unhandled_input(event):
	your_subviewport.push_input(event)


func savecheckpoint():
	SaveManager.set_value(&"playercheckpoint", checkpoint)
	SaveManager.persist()
