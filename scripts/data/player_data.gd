extends Object

class_name PlayerData

@export var hit_points: int = 10
@export var mana_points: int = 10

static var _instance : PlayerData

signal damaged(amount: int)
signal health_changed(new_health: int)
signal mana_changed(new_mana: int)
signal die

static var saved_state : PlayerData

func duplicate() -> PlayerData:
	var duplicated = PlayerData.new()
	duplicated.hit_points = hit_points
	duplicated.mana_points = mana_points
	return duplicated

static func save_state():
	saved_state = get_instance().duplicate()
	
static func reset():
	_instance = PlayerData.new()
	
static func reload_state():
	_instance = saved_state

static func damage(amount: int) -> void:
	get_instance().hit_points -= amount
	_instance.health_changed.emit(_instance.hit_points)
	_instance.damaged.emit(amount)
	if(get_instance().hit_points <= 0):
		_instance.die.emit()

static func set_health(new_health: int) -> void:
	get_instance().hit_points = new_health
	_instance.health_changed.emit(new_health)
	if(get_instance().hit_points <= 0):
		_instance.die.emit()

static func get_health() -> int:
	return get_instance().hit_points
	
static func use_mana(amount: int) -> void:
	get_instance().mana_points -= amount
	_instance.mana_changed.emit(_instance.mana_points)

static func set_mana(new_mana: int) -> void:
	get_instance().mana_points = new_mana
	_instance.mana_changed.emit(new_mana)
	
static func get_mana() -> int:
	return get_instance().mana_points

static func get_instance() -> PlayerData:
	if(_instance):
		return _instance
	else:
		_instance = PlayerData.new()
		return _instance
