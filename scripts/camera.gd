extends Camera2D

var target: Node2D	

func _ready() -> void:
	get_target()

func _process(_delta: float) -> void:
	position = target.position

func get_target():
	var nodes = get_tree().get_nodes_in_group("Player")
	target = nodes[0]
	
	#puramente visual essa porra de baixo, se colocar primeiro que o target, a camera não se move, sei lá o porque.
	if nodes.size() == 0:
		push_error("Player não encontrado")
		return
