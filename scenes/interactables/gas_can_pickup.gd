extends Node3D
@export var keyname : String
var can = preload("res://assets/items/GasCan.tres")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass



func _on_interact_interact_function() -> void:
	var Player = get_tree().get_first_node_in_group("PlayerUI")
	var newkey = can.duplicate()
	newkey.key = keyname
	Player.AddItem(newkey)
	queue_free()
