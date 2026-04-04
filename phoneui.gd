extends Control
var usingphone = false
signal LightOff
signal GnomeScare
@onready var apps = [$GridContainer/Button, $GridContainer/Button2, $GridContainer/Button3, $GridContainer/Button4, $GridContainer/Button5]
var appnumber = 0
var gnomeview = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$GridContainer/Button.grab_focus()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


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
		1:
			$GridContainer.hide()
			$GnomeRingView.show()
			$GnomeRingView/Back.grab_focus()
			gnomeview = true
		2:
			LightOff.emit()


func _on_back_pressed() -> void:
	$GnomeRingView.hide()
	$GnomeButtons.hide()
	$GridContainer.show()


func _on_button_2_pressed() -> void:
	$GridContainer.hide()
	$GnomeButtons.show()
	$GnomeRingView.show()
	$GnomeButtons/Back.grab_focus()


func _on_scare_gnome_pressed() -> void:
	GnomeScare.emit()
	
