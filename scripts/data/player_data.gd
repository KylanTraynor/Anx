extends Object

class_name PlayerData

@export var hit_points: int = 10

static var _instance : PlayerData

signal damaged(amount: int)
signal health_changed(new_health: int)

static func damage(amount: int) -> void:
	get_instance().hit_points -= amount
	_instance.health_changed.emit(_instance.hit_points)
	_instance.damaged.emit(amount)

static func set_health(new_health: int) -> void:
	get_instance().hit_points = new_health
	_instance.health_changed.emit(new_health)

static func get_health() -> int:
	return get_instance().hit_points

static func get_instance() -> PlayerData:
	if(_instance):
		return _instance
	else:
		_instance = PlayerData.new()
		return _instance
