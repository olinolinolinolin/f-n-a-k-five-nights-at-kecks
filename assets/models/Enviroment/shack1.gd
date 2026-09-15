extends Node3D
var player: Node3D
var dooropen: bool = false
@export_category("Door")
@export var doorlocked: bool = false
@export var LockName : String
@export_category("Lever")
@export var LeverAnimPlayer: AnimationPlayer
var LeverDown =  true
signal shackpowertoggle

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	player = get_tree().get_first_node_in_group("PlayerUI")


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_interact_interact_function() -> void:
	if doorlocked == false:
		movedoor()
	else:
		if player.HeldItem.key == LockName:
			movedoor()
			player.ConsumeItem()
			doorlocked = false


func movedoor():
	if dooropen == false:
		$DoorAnimPlayer.play("DoorOpen")
		dooropen = true
	else:
		$DoorAnimPlayer.play_backwards("DoorOpen")
		dooropen = false

func powershacklever():
	shackpowertoggle.emit()
	if LeverDown == true:
		LeverAnimPlayer.play("LeverPull")
		LeverDown = false
	else:
		LeverAnimPlayer.play_backwards("LeverPull")
		LeverDown = true
