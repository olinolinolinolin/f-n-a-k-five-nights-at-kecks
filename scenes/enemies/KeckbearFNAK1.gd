extends Node3D
var forward = true
var canbeseen =  false
var rng = RandomNumberGenerator.new()
signal attackplayer
@export_category("attacktimes")
@export var attacktime1: float
@export var attacktime2: float

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	determinetimetoscare()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if $Path3D/PathFollow3D.progress_ratio == 1.0:
		forward = false
	if $Path3D/PathFollow3D.progress_ratio == 0.0:
		forward = true
	if forward == true and canbeseen == false:
		$Path3D/PathFollow3D.progress_ratio += .1 * delta
	if forward == false and canbeseen == false:
		$Path3D/PathFollow3D.progress_ratio -= .1 * delta

func determinetimetoscare():
	$visibletime.wait_time = rng.randi_range(attacktime1,attacktime2)
	$visibletime.start()

func _on_visibletime_timeout() -> void:
	canbeseen = true
	$Path3D/PathFollow3D/Sprite3D/SoundFX.play()
	$Path3D/PathFollow3D/Sprite3D.show()
	await get_tree().create_timer(5).timeout
	attackplayer.emit()
	


func _on_player_dead(hiding) -> void:
	if hiding == true:
		$Path3D/PathFollow3D/Sprite3D.hide()
		determinetimetoscare()
		canbeseen = false
	else:
		pass
