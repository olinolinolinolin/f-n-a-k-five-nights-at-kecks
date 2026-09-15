extends Node3D
@export var coinname: String

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var CoinDict = SaveManager.get_value(&"CoinsCollected", coinname)
	print(CoinDict[coinname])
	if CoinDict[coinname] == true:
		queue_free()



# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_interact_interact_function() -> void:
	Playerstats.addcointocollection(coinname)
	queue_free()
