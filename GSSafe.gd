extends Node3D
@export_category("Safe UI")
@export var SafeDial: TextureRect
# Called when the node enters the scene tree for the first time.
@export var SafeCombination = [05,25,50] 
var CurrentNumber = 0
var ComboEnter = []


func _ready() -> void:
	$SafeUI/Label.text = str(CurrentNumber)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _input(InputEvent):
	if $SafeUI.visible == false:
		return
	else:
		if Input.is_action_just_pressed("ui_cancel"):
			quit()
		if Input.is_action_just_pressed("move_left"):
			SafeDial.rotation_degrees += 18.0
			CurrentNumber -= 5
			CurrentNumber = wrapi(CurrentNumber, 0, 100)
			$SafeUI/Label.text = str(CurrentNumber)
		if Input.is_action_just_pressed("move_right"):
			CurrentNumber += 5
			CurrentNumber = wrapi(CurrentNumber, 0, 100)
			SafeDial.rotation_degrees += -18.0
			$SafeUI/Label.text = str(CurrentNumber)
		if Input.is_action_just_pressed("ui_accept"):
			ComboEnter.append(CurrentNumber)
			if ComboEnter.size() >= 3:
				if ComboEnter == SafeCombination:
					print_debug("YOU OPENED IT YAY")
					quit()
					$AnimationPlayer.play("SafeOpen")
				else:
					ComboEnter = []
					print_debug("WRONG")


func _on_interact_interact_function() -> void:
	print_debug("Open Safe UI")
	$SafeUI.show()
	var Player = get_tree().get_first_node_in_group("PlayerUI")
	Player.PlayingCabinet = true
	ComboEnter = []

func quit():
	var Player = get_tree().get_first_node_in_group("PlayerUI")
	$SafeUI.hide()
	Player.PlayingCabinet = false
	Player.StopArcade()
	ComboEnter = []


func getridofsafe():
	$"Safe Body/Interact".queue_free()
