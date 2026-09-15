extends Node3D
var thunderstruk = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass



func nicklightningtrigger():
	
	if thunderstruk == false:
		$TheLightning/AnimationPlayer.play("LightningStrike")
		thunderstruk = true
	else:
		pass

func thundersound():
	$TheLightning/AudioStreamPlayer3D.play()
