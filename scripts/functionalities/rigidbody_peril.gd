extends RigidBody2D

@export var damage_amount: int = 1
@export var animation_name: String = "crushed"
@export var harmless_threshold = 10000

var _shape : Shape2D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_shape = $CollisionShape2D.shape
	pass

func _physics_process(_delta: float) -> void:
	if self.linear_velocity.length_squared() > harmless_threshold:
		self.collision_mask = 1
		self.collision_layer = 4
		if(is_in(Main.get_player().global_position)):
			PlayerData.damage(damage_amount)
			Main.get_player().play_animation(animation_name)
	else:
		self.collision_layer = 1
		self.collision_mask = 3

func is_in(point: Vector2):
	if _shape is CircleShape2D:
		return Geometry2D.is_point_in_circle(point, $CollisionShape2D.global_position, _shape.radius)
	elif _shape is ConvexPolygonShape2D:
		return Geometry2D.is_point_in_polygon(point, _shape.points)
	else:
		push_error("Not implemented yet! Shape is a ", typeof(_shape))
