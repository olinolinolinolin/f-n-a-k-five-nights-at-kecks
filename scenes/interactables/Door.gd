extends Node3D
@export var AnimPlayer: AnimationPlayer
var Open = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_interact_interact_function() -> void:
	if Open == false:
		AnimPlayer.play("OpenDoor")
		Open = true
	else:
		AnimPlayer.play_backwards("OpenDoor")
		Open = false
