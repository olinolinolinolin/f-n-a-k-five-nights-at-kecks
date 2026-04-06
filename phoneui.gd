extends Control
var usingphone = false
signal LightOff
signal GnomeScare
@onready var apps = [$GridContainer/Button, $GridContainer/Button2, $GridContainer/Button3, $GridContainer/Button4, $GridContainer/Button5]
var appnumber = 0
var gnomeview = false
var qtebeingdone = false
var allqtesymbosl = ["1","2","3","4"]
var enteredqtesequence = []

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$GridContainer/Button.grab_focus()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if qtebeingdone == true:
		if Input.is_action_just_pressed("qte1"):
			enteredqtesequence.append("1")
		if Input.is_action_just_pressed("qte2"):
			enteredqtesequence.append("2")
		if Input.is_action_just_pressed("qte3"):
			enteredqtesequence.append("3")
		if Input.is_action_just_pressed("qte4"):
			enteredqtesequence.append("4")
	if qtebeingdone == true and enteredqtesequence.size() == 4:
		qtebeingdone = false
		if enteredqtesequence == allqtesymbosl:
			print("you did it")
			enteredqtesequence.clear()
		else:
			print("you fucked up")
			enteredqtesequence.clear()

func _on_button_pressed() -> void:
	discordqtecheck()


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
	
	
func discordqtecheck():
	allqtesymbosl.shuffle()
	print(allqtesymbosl)
	qtebeingdone = true
