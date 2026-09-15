extends Control

var testlvl = ("res://testhub1.tscn")


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	print(Playerstats.Checkpoint)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_button_pressed() -> void:
	get_tree().change_scene_to_file(testlvl)


func _on_button_2_pressed() -> void:
	var Checkpoint = Playerstats.Checkpoint
	match Checkpoint:
		0:
			get_tree().change_scene_to_file("res://testhub1.tscn")
		1:
			get_tree().change_scene_to_file("res://scenes/FNAK2CAMPAIGN/fnak_2l_1prod.tscn")
