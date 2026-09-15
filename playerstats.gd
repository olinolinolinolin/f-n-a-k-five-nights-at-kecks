extends Node
var coinscollected = {"Coin 1": false,"Coin 2": false}
var Checkpoint : int

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	SaveManager.register_key(&"CoinsCollected", TYPE_DICTIONARY, {"Coin 1": false,"Coin 2": false})
	SaveManager.register_key(&"NumOfCoinsCollected", TYPE_INT, 0)
	SaveManager.register_key(&"checkpoint", TYPE_INT, 0)
	
	coinscollected = SaveManager.get_value(&"CoinsCollected").duplicate()
	Checkpoint = SaveManager.get_value(&"checkpoint")
	
	




# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func addcointocollection(coinname):
	coinscollected[coinname] = true
	SaveManager.set_value(&"CoinsCollected", coinscollected.duplicate())
	SaveManager.set_value(&"NumOfCoinsCollected",(SaveManager.get_value(&"NumOfCoinsCollected") + 1))
	SaveManager.mark_dirty()

func addcheckpoint():
	SaveManager.set_value(&"checkpoint",(SaveManager.get_value(&"checkpoint") + 1))
	SaveManager.mark_dirty()
