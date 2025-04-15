extends PointLight2D

var destination: Vector2 = Vector2.ZERO
var blink_offset = randf_range(0, 500)
@export var speed = 40
@export var blink_speed = 1.0
var time_lit = 0.0
var next_state = 0
var turned_on = false
var max_energy = 5.5


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	speed = speed * randf_range(0.5, 1)
	texture_scale = texture_scale * randf_range(0.25, 1.25)
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if(destination.distance_squared_to(position) < 1):
		destination = Vector2(randf_range(-1000,1000), randf_range(0,400))
	
	if(Time.get_ticks_msec() > next_state):
		turned_on = not turned_on
		if(turned_on):
			next_state = Time.get_ticks_msec() + randf_range(250,750)
		else:
			next_state = Time.get_ticks_msec() + randf_range(250, 5000)
	
	position = position.move_toward(destination, speed * delta)
	var target_energy = max_energy if turned_on else 0
	energy = lerpf(energy, target_energy, clampf(delta*10, 0, 1))
	modulate.a = lerpf(modulate.a, 1 if target_energy > 0 else 0, clampf(delta*10, 0, 1))
	pass
