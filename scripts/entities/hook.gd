@tool
extends Node2D

class_name Hook

@export var range: float = 5000
@export var start_angle: float = - PI
@export var end_angle: float = PI

static var _time_vibrated = 0

var _player_in_range := false

signal player_enter
signal player_exit

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if not Engine.is_editor_hint():
		if _check_player_in_range():
			if not _player_in_range:
				_player_in_range = true
				Main.get_player().hook = self
				player_enter.emit()
		else :
			if _player_in_range:
				_player_in_range = false
				if Main.get_player().hook == self:
					Main.get_player().hook = null
				player_exit.emit()
		
		if _player_in_range and Time.get_ticks_msec() > _time_vibrated + 2000:
			Input.start_joy_vibration(0, 1, 0, 1)
			Main.shake_screen(5, 500, 1000)
			_time_vibrated = Time.get_ticks_msec()
		
	queue_redraw()

func _is_angle_between(angle, min, max) -> bool:
	while angle < min :
		angle += PI * 2
	while angle > max :
		angle -= PI * 2
	if angle < max and angle > min:
		return true
	return false

func _check_player_in_range() -> bool:
	var player = Main.get_player()
	if Geometry2D.is_point_in_circle(player.global_position, self.global_position, range):
		var angle = (player.global_position - self.global_position).angle()
		if _is_angle_between(angle, start_angle, end_angle):
			return true
	return false

func _draw() -> void:
	if Engine.is_editor_hint():
		draw_arc(Vector2.ZERO, range, start_angle, end_angle, 100, Color.BLUE, 10)
		for i in range(0, range, 100):
			draw_arc(Vector2.ZERO, i, start_angle, end_angle, 100, Color.BLUE, 1)
	else:
		if _player_in_range:
			draw_colored_polygon([Vector2.ZERO, Vector2(200, -200), Vector2(-200, -200)], Color.WHITE)
