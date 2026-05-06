extends Node3D
const JumpVelocity = 4.5
const Speed = 5.0

var NothingItem = preload("res://assets/items/Nothing.tres")
var ThrownRock = preload("res://assets/models/thrown_rock.tscn")

@export var InteractionRay: RayCast3D
@export var InteractText: Label
@export var InventoryArray: Array[Item] = []
@export var HeldItem : Item
var InventoryIndex := 0
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	showhelditem()
	UpdateInventory()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if InteractionRay.get_collider() != null:
		var HoveredObject = InteractionRay.get_collider()
		if HoveredObject != null:
			for child in HoveredObject.get_children():
				if child.has_method("Interact"):
					child.SendInteractTextFunc()
	else:
		InteractText.text = " "


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
	if Input.is_action_just_pressed("Interact"):
		trytointeract()
	InvetoryScroll()
	if Input.is_action_just_pressed("UseHeldItem"):
		self.call(HeldItem.function)
	if Input.is_key_pressed(KEY_Q):
		DropItem()

func trytointeract():
	if InteractionRay.get_collider() != null:
		var InteractedObject = InteractionRay.get_collider()
		print("Interacting With ", InteractedObject)
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



func UseRock():
	print("rockin it")
	var UsedRock = ThrownRock.instantiate()
	UsedRock.position = $PlayerBody/PlayerHead/PlayerCamera/HeadController/RightHand.global_position
	get_tree().current_scene.add_child(UsedRock)
	
	var force = -18
	var upDirection = 3.5
	
	var playerRotation = $PlayerBody/PlayerHead.global_transform.basis.z.normalized()
	
	UsedRock.apply_central_impulse(playerRotation * force + Vector3(0, upDirection, 0))
	
func UseFloppyDisk():
	print("floppin it")
	ConsumeItem()
	showhelditem()
	
func UseNothing():
	print("nothing it")

func AddItem(Item):
	InventoryArray[InventoryIndex] = Item
	showhelditem()
	UpdateInventory()

func DropItem():
	match  HeldItem:
		NothingItem:
			print("Cant Drop")

func ConsumeItem():
	InventoryArray[InventoryIndex] = NothingItem
	UpdateInventory()

func UpdateInventory():
	var InvIcons = [$PlayerUI/HBoxContainer/TextureRect, $PlayerUI/HBoxContainer/TextureRect2, $PlayerUI/HBoxContainer/TextureRect3]
	var progress = 0
	for Icon in InvIcons:
		Icon.texture = InventoryArray[progress].image
		progress += 1
