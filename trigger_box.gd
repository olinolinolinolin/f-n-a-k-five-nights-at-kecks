extends Node3D
signal playertrigger
@export_category("Trigger Options")
@export var TriggerName: String
var player : Node3D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	player = get_tree().get_first_node_in_group("Player")


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_area_3d_body_entered(body: Node3D) -> void:
	if body == player:
		playertrigger.emit()
