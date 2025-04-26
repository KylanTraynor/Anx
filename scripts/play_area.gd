extends Area2D

@export var camera_area : CollisionShape2D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if(not camera_area):
		var nodes = find_children("CameraArea", "CollisionShape2D", true)
		if(nodes.is_empty()):
			camera_area = null
		else:
			camera_area = nodes[0]
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass

func get_rect():
	if(camera_area):
		return Rect2(camera_area.position - camera_area.shape.size/2, camera_area.shape.size)
	else:
		return null
