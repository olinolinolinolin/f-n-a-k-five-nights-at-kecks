extends Node3D
var GasCan = preload("res://assets/items/GasCan.tres")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_interact_interact_function() -> void:
	var Player = get_tree().get_first_node_in_group("PlayerUI")
	if Player.HeldItem.key == "GasFill":
		GasCan.key = "GasCanCar"
		print_debug("Doing it")
