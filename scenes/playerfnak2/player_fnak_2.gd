extends Node3D
@export var InteractionRay: RayCast3D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _input(event: InputEvent) -> void:
	if Input.is_key_pressed(KEY_E):
		if InteractionRay.get_collider() != null:
			var InteractedObject = InteractionRay.get_collider()
			print(InteractedObject)
			if InteractedObject.get_children() != null:
				for child in InteractedObject.get_children():
					if child.has_method("Interact"):
						child.Interact()


func trytointeract():
	pass
