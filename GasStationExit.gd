extends Node3D
@export_category("Bools")
@export var GasFull: bool = false
var player : Node



# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	player = get_tree().get_first_node_in_group("PlayerUI")


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_interact_interact_function() -> void:
	if GasFull == true:
		if player.HeldItem.key == "ExitCar":
			print("leave")
	else:
		print("Car Needs Gas still")
