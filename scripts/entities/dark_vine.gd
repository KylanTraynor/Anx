@tool
extends Path2D

class_name Vine

@export var growth_pixel := 0
@export var is_growing := false
@export var max_width_offset := -1
@export var growth_rate := 100.0
@export var adaptative_growth_rate := 0
@export var adaptative_growth_distance := 1

var tip : PathFollow2D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$Display.width_curve = Curve.new()
	tip = $Tip


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	$Display.points = self.curve.get_baked_points()
	var max_length : float = self.curve.get_baked_length()
	var width_curve : Curve = $Display.width_curve
	width_curve.clear_points()
	if not max_width_offset == -1 :
		width_curve.add_point(Vector2(0, 1))
		width_curve.add_point(Vector2(max(0,growth_pixel - max_width_offset) / max(max_length, 1), 1))
	else:
		width_curve.add_point(Vector2(0, 1))
	width_curve.add_point(Vector2(growth_pixel / max(max_length, 1), 0))
	if tip:
		tip.progress = growth_pixel
	if not Engine.is_editor_hint() and is_growing:
		growth_pixel = min(growth_pixel + growth_rate * delta, max_length)

func set_growth_rate(rate : float) -> void:
	growth_rate = rate
	
func set_growth(amount : float) -> void:
	growth_pixel = amount
