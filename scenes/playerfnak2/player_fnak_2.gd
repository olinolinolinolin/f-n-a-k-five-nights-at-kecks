extends Node3D
const JumpVelocity = 4.5
const Speed = 5.0

@export var InteractionRay: RayCast3D
@export var InteractText: Label
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass


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


	
func setinteracttext(senttext):
	InteractText.text = senttext

func _input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("Interact"):
		trytointeract()

func trytointeract():
	if InteractionRay.get_collider() != null:
		var InteractedObject = InteractionRay.get_collider()
		print(InteractedObject)
		if InteractedObject.get_children() != null:
			for child in InteractedObject.get_children():
				if child.has_method("Interact"):
					child.Interact()
