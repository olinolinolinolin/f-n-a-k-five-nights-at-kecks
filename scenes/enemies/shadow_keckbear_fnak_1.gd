extends Node3D
var lightbool = false
var agitation = 0.0
var scared = 1.0
var canbeseen = false
var rng = RandomNumberGenerator.new()
@export var spawnlocations : PackedVector3Array
@export_category("attacktimes")
@export var attacktime1: float
@export var attacktime2: float
signal ShadowKills
var aledead = false


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	determinetimetoscare()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if canbeseen == true and lightbool == false:
		agitation += .1 * delta
	if agitation >= 1:
		killale()
	if canbeseen == true and lightbool == true:
		scared -= .25 * delta
		if scared <= 0:
			canbeseen = false
			$KeckbearSprite.hide()
			agitation = 0
			determinetimetoscare()

func _on_node_3d_lightonshadow(flashlight) -> void:
	lightbool = flashlight

func determinetimetoscare():
	scared = 1.0
	$SpawnTimer.wait_time = rng.randi_range(attacktime1,attacktime2)
	$SpawnTimer.start()

func _on_spawn_timer_timeout() -> void:
	position = spawnlocations[rng.randi_range(0,2)]
	$KeckbearSprite.show()
	$ShadowSFX.play()
	canbeseen = true


func killale():
	if aledead == false:
		ShadowKills.emit()
		print("shadow kills")
		aledead = true
