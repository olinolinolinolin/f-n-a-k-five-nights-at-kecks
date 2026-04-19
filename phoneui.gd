extends Control
var usingphone = false
signal qteresult
signal LightOff
signal GnomeScare
@onready var apps = [$GridContainer/Button, $GridContainer/Button2, $GridContainer/Button3, $GridContainer/Button4, $GridContainer/Button5]
var appnumber = 0
var gnomeview = false
var qtebeingdone = false
var qtetextures = [preload("res://assets/sprites/test assets/1.png"),preload("res://assets/sprites/test assets/2.png"),preload("res://assets/sprites/test assets/3.png"),preload("res://assets/sprites/test assets/4.png")]
var allqtesymbosl = ["1","2","3","4"]
var enteredqtesequence = []
var qteprogresscheck = 0
@onready var qtetextrects = [$QteVContainer/QteHContainer/QTERect1, $QteVContainer/QteHContainer/QTERect2,
 $QteVContainer/QteHContainer/QTERect3, $QteVContainer/QteHContainer/QTERect4]

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$GridContainer/Button.grab_focus()




# Called every frame. 'delta' is the elapsed time since the previous frame.
func _input(event: InputEvent) -> void:
	if qtebeingdone == true:
		if Input.is_action_just_pressed("qte1"):
			enteredqtesequence.append("1")
			if enteredqtesequence[qteprogresscheck] == allqtesymbosl[qteprogresscheck]:
				print("yeah")
				qteprogresscheck += 1
			else:
				qtefail()
			
		if Input.is_action_just_pressed("qte2"):
			enteredqtesequence.append("2")
			if enteredqtesequence[qteprogresscheck] == allqtesymbosl[qteprogresscheck]:
				print("yeah")
				qteprogresscheck += 1
			else:
				qtefail()
			
		if Input.is_action_just_pressed("qte3"):
			enteredqtesequence.append("3")
			if enteredqtesequence[qteprogresscheck] == allqtesymbosl[qteprogresscheck]:
				print("yeah")
				qteprogresscheck += 1
			else:
				qtefail()
			
		if Input.is_action_just_pressed("qte4"):
			enteredqtesequence.append("4")
			if enteredqtesequence[qteprogresscheck] == allqtesymbosl[qteprogresscheck]:
				print("yeah")
				qteprogresscheck += 1
			else:
				qtefail()
			
	if qtebeingdone == true and enteredqtesequence.size() == 4:
		qtebeingdone = false
		if enteredqtesequence == allqtesymbosl:
			qtesuccess()
		else:
			qtefail()

func _on_button_pressed() -> void:
	$QteVContainer.show()
	$GridContainer.hide()
	$QteVContainer/QteStartButton.grab_focus()


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
	$VBoxContainer.hide()
	$GridContainer.show()
	$GridContainer/Button.grab_focus()


func _on_button_2_pressed() -> void:
	$GridContainer.hide()
	$VBoxContainer.show()
	$VBoxContainer/GnomeButtons/Back.grab_focus()


func _on_scare_gnome_pressed() -> void:
	GnomeScare.emit()
	
	
func discordqtecheck():
	allqtesymbosl.shuffle()
	print(allqtesymbosl)
	qtebeingdone = true
	var loop = 0
	for symbol in allqtesymbosl:
		match symbol:
			"1":
				qtetextrects[loop].texture = qtetextures[0]
			"2":
				qtetextrects[loop].texture = qtetextures[1]
			"3":
				qtetextrects[loop].texture = qtetextures[2]
			"4":
				qtetextrects[loop].texture = qtetextures[3]
		loop += 1


func qtesuccess():
	qtebeingdone = false
	qteprogresscheck = 0
	print("you did it")
	enteredqtesequence.clear()
	qteresult.emit(.3)


func qtefail():
	qtebeingdone = false
	qteprogresscheck = 0
	print("you fucked up")
	enteredqtesequence.clear()
	qteresult.emit(-.3)


func _on_qte_back_button_pressed() -> void:
	$QteVContainer.hide()
	$GridContainer.show()
	$GridContainer/Button.grab_focus()


func _on_qte_start_button_pressed() -> void:
	discordqtecheck()
