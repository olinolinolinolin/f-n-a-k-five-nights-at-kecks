extends Node3D
@export_category("attacktimes")
@export var attacktime1: float
@export var attacktime2: float
var rng = RandomNumberGenerator.new()
var creeping = false


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	determinetimetoscare()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if creeping == true:
		$Path3D/PathFollow3D.progress_ratio += .03 * delta
	
	if $Path3D/PathFollow3D.progress_ratio == 1:
		print("dead af homeboy")


func determinetimetoscare():
	$GnomeTime.wait_time = rng.randi_range(attacktime1,attacktime2)
	$GnomeTime.start()

func _on_gnome_time_timeout() -> void:
	$Path3D/PathFollow3D/Sprite3D.show()
	creeping = true
	$AudioStreamPlayer.play()


func resetgnome():
	$Path3D/PathFollow3D.progress_ratio = 0.0
	creeping = false
	determinetimetoscare()


func _on_phone_screen_texture_gnome_scare() -> void:
	resetgnome()
