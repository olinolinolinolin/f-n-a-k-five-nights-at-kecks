extends Node3D
@export var Camera : Camera3D
@export var GameToPlay: PackedScene

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
	
func _input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("ui_cancel"):
		quit()


func _on_interact_interact_function() -> void:
	var Player = get_tree().get_first_node_in_group("PlayerUI")
	Player.PlayingCabinet = true
	print("lmao Im playing with myself so quirky ahah!!!")
	Camera.make_current()
	$AnimationPlayer.play("Start Playing")
	

func quit():
	var Player = get_tree().get_first_node_in_group("PlayerUI")
	Player.PlayerCam.make_current()
	Player.PlayingCabinet = false
	
