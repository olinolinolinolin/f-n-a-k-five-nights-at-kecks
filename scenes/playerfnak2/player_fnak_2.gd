extends Node3D
const JumpVelocity = 4.5
var Speed = 5.0

var NothingItem = preload("res://assets/items/Nothing.tres")
var ThrownRock = preload("res://assets/models/thrown_rock.tscn")
var ItemShader = preload("res://shaders/HighlightInvShader.tres")
var PlayingCabinet = false

@export_category("Player Objects")
@export var PlayerCam: Camera3D
@export var InteractionRay: RayCast3D
@export var InteractText: Label
@export_category("Debug Tools")
@export var fpscounter: Label
@export_category("Inventory")
@export var InventoryArray: Array[Item] = []
@export var HeldItem : Item
@export var InventorySlots: Array[TextureRect] = []
@export_category("Player Vars")
@export var HaveNick: bool = false
var InventoryIndex := 0
var IsGameOver = false
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	showhelditem()
	UpdateInventory()
	if HaveNick == false :
		$PlayerBody/PlayerHead/PlayerCamera/HeadController/handholdingnick.hide()
		$PlayerBody/PlayerHead/PlayerCamera/HeadController/SpotLight3D.hide()
		$PlayerBody/PlayerHead/PlayerCamera/OmniLight3D.hide()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if InteractionRay.get_collider() != null:
		var HoveredObject = InteractionRay.get_collider()
		if HoveredObject != null:
			if HoveredObject.has_method("get_children"):
				for child in HoveredObject.get_children():
					if child.has_method("Interact"):
						child.SendInteractTextFunc()
	else:
		InteractText.text = " "
	if OS.is_debug_build():
		$PlayerUI/Debug/Label.show()
		var Keckbear = get_tree().get_nodes_in_group("Enemy")
		for i in Keckbear:
			if i.has_method("stun"):
				$PlayerUI/Debug/Label.text = "CURRENT STATE" + " " + str(i.CurrentState)
	fpscounter.text = ("FPS " +str(Engine.get_frames_per_second()))

func InvetoryScroll():
	if Input.is_action_just_released("InvDown"):
		InventoryIndex = wrap(InventoryIndex-1, 0, InventoryArray.size())
		showhelditem()
	if Input.is_action_just_released("InvUp"):
		InventoryIndex = wrap(InventoryIndex+1, 0, InventoryArray.size())
		showhelditem()
func setinteracttext(senttext):
	InteractText.text = senttext

func _input(event: InputEvent) -> void:
	if PlayingCabinet == false:
		if Input.is_action_just_pressed("Interact"):
			trytointeract()
		InvetoryScroll()
		if Input.is_action_just_pressed("UseHeldItem"):
			self.call(HeldItem.function)
		if Input.is_key_pressed(KEY_Q):
			GetScared()




func trytointeract():
	if InteractionRay.get_collider() != null:
		var InteractedObject = InteractionRay.get_collider()
		print("Interacting With ", InteractedObject)
		if InteractedObject.has_method("get_children"):
			if InteractedObject.get_children() != null:
				for child in InteractedObject.get_children():
					if child.has_method("Interact"):
						child.Interact()


func showhelditem():
	HeldItem = InventoryArray[InventoryIndex]
	
	if $PlayerBody/PlayerHead/PlayerCamera/HeadController/RightHand.get_children().size() > 0:
		for i in $PlayerBody/PlayerHead/PlayerCamera/HeadController/RightHand.get_children():
			$PlayerBody/PlayerHead/PlayerCamera/HeadController/RightHand.remove_child(i)
	
	var item_model = HeldItem.model.instantiate()
	$PlayerBody/PlayerHead/PlayerCamera/HeadController/RightHand.add_child(item_model)
	
	item_model.position = HeldItem.position
	item_model.rotation = HeldItem.rotation
	var InvIcons = InventorySlots
	var progress = 0
	for Icon in InvIcons:
		InvIcons[progress].material = null
		progress += 1
	InvIcons[InventoryIndex].material = ItemShader
	progress = 0



func UseRock():
	print("rockin it")
	var UsedRock = ThrownRock.instantiate()
	UsedRock.position = $PlayerBody/PlayerHead/PlayerCamera/HeadController/RightHand.global_position
	get_tree().current_scene.add_child(UsedRock)
	
	var force = -18
	var upDirection = 3.5
	
	var playerRotation = $PlayerBody/PlayerHead.global_transform.basis.z.normalized()
	
	UsedRock.apply_central_impulse(playerRotation * force + Vector3(0, upDirection, 0))
	ConsumeItem()
	
func UseFloppyDisk():
	print("floppin it" + " this is the " + HeldItem.key + " Key")
	ConsumeItem()
	showhelditem()
	
func UseNothing():
	print("nothing it")
	
func UseKey():
	print("keying it" + " this is the " + HeldItem.key + " Key")

func AddItem(item):
	for i in InventoryArray.size():
		if InventoryArray[i] == NothingItem:
			InventoryArray[i] = item
			UpdateInventory()
			showhelditem()
			return
	print("Inventory Full")

func DropItem():
	match  HeldItem:
		NothingItem:
			print("Cant Drop")

func ConsumeItem():
	InventoryArray[InventoryIndex] = NothingItem
	UpdateInventory()
	showhelditem()

func UpdateInventory():
	var InvIcons = InventorySlots 
	var progress = 0
	for Icon in InvIcons:
		Icon.texture = InventoryArray[progress].image
		progress += 1

func GetNick():
	$PlayerBody/PlayerHead/PlayerCamera/HeadController/handholdingnick.show()
	$PlayerBody/PlayerHead/PlayerCamera/HeadController/SpotLight3D.show()
	$PlayerBody/PlayerHead/PlayerCamera/OmniLight3D.show()
	HaveNick = true

func StartArcade():
	InteractionRay.enabled = false
	$PlayerUI.hide()
	$PlayerBody.hide()

func StopArcade():
	InteractionRay.enabled = true
	$PlayerUI.show()
	$PlayerBody.show()


func GetScared():
	PlayingCabinet = true
	$PlayerBody/PlayerHead/PlayerCamera/olinbearjumpscare.top_level = true
	$PlayerBody/PlayerHead/PlayerCamera/CameraAnimPlayer.play("Jumpscare#1")
	$PlayerUI.hide()
	$PlayerBody/PlayerHead/PlayerCamera/HeadController/Hand2/Hand.hide()
	$PlayerBody/PlayerHead/PlayerCamera/OmniLight3D.hide()
	$PlayerBody/PlayerHead/PlayerCamera/HeadController/SpotLight3D.hide()
	$PlayerBody/PlayerHead/PlayerCamera/olinbearjumpscare.show()
	$PlayerBody/PlayerHead/PlayerCamera/HeadController/handholdingnick.hide()
	$PlayerBody/PlayerHead/PlayerCamera/HeadController/RightHand.hide()
	$PlayerBody/PlayerHead/PlayerCamera/olinbearjumpscare/AnimationPlayer.play("Jumpscare#1")

func GameOver():
	$CanvasLayer/GameOver.show()
	IsGameOver = true
	$CanvasLayer/RestartButton.show()
	Input.mouse_mode = Input.MOUSE_MODE_CONFINED
	$CanvasLayer/RestartButton.grab_focus()

func _on_restart_button_pressed() -> void:
	get_tree().change_scene_to_file(get_tree().current_scene.scene_file_path)
