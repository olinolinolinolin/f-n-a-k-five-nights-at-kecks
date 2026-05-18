extends Node3D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_interact_interact_function() -> void:
	var player = get_tree().get_first_node_in_group("PlayerUI")
	if player.has_method("GetNick"):
		player.GetNick()
		queue_free()
