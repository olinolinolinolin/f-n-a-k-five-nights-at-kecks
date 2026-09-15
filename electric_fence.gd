extends Node3D
var player: Node3D
var PowerOn: bool = true
var lampoffmat = preload("res://assets/material/lampoff.tres")
var lamponmat = preload("res://assets/material/lampon.tres")
var fencemat = preload("res://assets/material/metalbar.tres")
var fencematelec = preload("res://assets/material/metalbarelectric.tres")
@export var lampmodel: MeshInstance3D
var fencemodels: Array = []

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	player = get_tree().get_first_node_in_group("Player")
	fencemodels = get_tree().get_nodes_in_group("Fences")


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func shockplayer():
	pass
	

func _on_area_3d_body_entered(body: Node3D) -> void:
	if body == player and PowerOn == true:
		print_debug("Shock em john")

func powertoggle():
	if PowerOn == true:
		PowerOn = false
		$AnimationPlayer.play("OpenDoor")
		lampmodel.set_surface_override_material(1, lampoffmat)
		$lamp_5_1_on2/lamp_5_1_on/OmniLight3D.light_color = Color(0.788, 0.09, 0.188, 1.0)
		for i in fencemodels:
			i.set_surface_override_material(0,fencemat)
	else:
		PowerOn = true
		$AnimationPlayer.play_backwards("OpenDoor")
		lampmodel.set_surface_override_material(1, lamponmat)
		$lamp_5_1_on2/lamp_5_1_on/OmniLight3D.light_color = Color(0.255, 0.49, 0.294, 1.0)
		for i in fencemodels:
			i.set_surface_override_material(0,fencematelec)
