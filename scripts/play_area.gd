extends Area2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func get_rect() -> Rect2:
	var node = get_node("Shape")
	return Rect2(node.position - node.shape.size/2, node.shape.size)
