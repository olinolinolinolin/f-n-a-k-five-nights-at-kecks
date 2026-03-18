extends Node3D

var KeckbearFlashed = false
signal lightonshadow


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


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
