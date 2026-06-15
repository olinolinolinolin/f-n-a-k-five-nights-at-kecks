extends Node
signal InteractFunction
signal SendInteractText
@onready var Player =  get_tree().get_nodes_in_group("PlayerUI")[0]
@export var InteractText: String

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	SendInteractText.connect(Player.setinteracttext)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func Interact():
	InteractFunction.emit()

func SendInteractTextFunc():
	SendInteractText.emit(InteractText)
