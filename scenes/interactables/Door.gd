extends Node3D
@export var AnimPlayer: AnimationPlayer
@export_category("Door Lock Settings")
@export var Locked : bool
@export var LockName : String
var player : Node

var Open = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	player = get_tree().get_first_node_in_group("PlayerUI")


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_interact_interact_function() -> void:
	if Locked == true:
		if player.HeldItem.key == LockName:
			opendoor()
			player.ConsumeItem()
			Locked = false
		else:
			print("Door Locked")
	else:
		opendoor()


func opendoor():
	if Open == false:
		AnimPlayer.play("OpenDoor")
		Open = true
	else:
		AnimPlayer.play_backwards("OpenDoor")
		Open = false
