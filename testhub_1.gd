extends Node3D

@onready var your_subviewport: SubViewport = $"Player/Player Camera/Phone/PhoneBody/PhoneScreen/SubViewport"
@export var CompProgressBar : ProgressBar
@export var PatienceTimer : Timer
@export var MultiLabel : Label
var annoyance = 0.0
var annoyancemulti = 1
var annoyancepatience = 1.0
var annoyancepatiencebool = false



var KeckbearFlashed = false
signal lightonshadow


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass



# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	CompProgressBar.value = annoyance
	if annoyancepatiencebool == true:
		annoyancemulti =  clamp(annoyancemulti -.05 * delta ,.5,1.75)
	MultiLabel.text = "Multi" + ":" + " " + str(snapped(annoyancemulti,.01))
	
	if annoyance >= 100.0:
		print("you win")

func _on_flash_light_area_body_entered(body: Node3D) -> void:
	if body.is_in_group("Shadow") == true:
		KeckbearFlashed = true
		print("flashing")
		lightonshadow.emit(KeckbearFlashed)


func _on_flash_light_area_body_exited(body: Node3D) -> void:
	if body.is_in_group("Shadow") == true:
		KeckbearFlashed = false
		print("no flashing")
		lightonshadow.emit(KeckbearFlashed)

func _unhandled_input(event):
	your_subviewport.push_input(event)





func _on_phone_screen_texture_qteresult(result) -> void:
	annoyancepatiencebool = false
	annoyancemulti = clamp(annoyancemulti + result,.5,1.75)
	print(annoyancemulti)
	PatienceTimer.stop()
	await get_tree().create_timer(15)
	PatienceTimer.start()


func _on_annoy_timer_timeout() -> void:
	annoyance += .125 * annoyancemulti


func _on_patience_timeout() -> void:
	annoyancepatiencebool = true
