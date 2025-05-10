extends Control

class_name BossBar

@export var _delayed_bar : ProgressBar
@export var _main_bar : ProgressBar
@export var _delay := 1000

static var _instance : BossBar
static var _last_health_changed_time : int
static var _max : int
static var _current : int

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_instance = self

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if(Time.get_ticks_msec() > _last_health_changed_time + _delay):
		_delayed_bar.value = move_toward(_delayed_bar.value, 100.0 * _current / _max, delta * 200)

static func set_max(amount : int) -> void:
	_max = amount

static func set_health(health: int) -> void:
	#var is_damage = false
	#if(health < _current):
	#	is_damage = true
	_current = health
	_last_health_changed_time = Time.get_ticks_msec()
	_instance._main_bar.value = 100.0 * _current / _max
