extends Control
var usingphone = false
signal LightOff
@onready var apps = [$GridContainer/Button, $GridContainer/Button2, $GridContainer/Button3, $GridContainer/Button4, $GridContainer/Button5]
var appnumber = 0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	apps[appnumber].grab_focus()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if usingphone == true and Input.is_action_just_pressed("ui_left"):
		appnumber -= 1
		appnumber = clamp(appnumber,0,4)
		keepfocusing(appnumber)
	if usingphone == true and Input.is_action_just_pressed("ui_right"):
		appnumber += 1
		appnumber = clamp(appnumber,0,4)
		keepfocusing(appnumber)
	if usingphone == true and Input.is_action_just_pressed("ui_accept"):
		appfunction()


func _on_button_pressed() -> void:
	print("holy moly this works")


func _on_button_3_pressed() -> void:
	LightOff.emit()


func _on_player_usingphone(phone) -> void:
	if phone == true:
		apps[appnumber].grab_focus()
		usingphone = true
	else:
		get_viewport().gui_release_focus()
		usingphone = false


func keepfocusing(appnumber):
	clamp(appnumber,0,4)
	apps[appnumber].grab_focus()
	
	
func appfunction():
	
	match appnumber:
		0:
			print("Holy moly this works")
		2:
			LightOff.emit()
