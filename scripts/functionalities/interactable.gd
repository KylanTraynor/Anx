extends Node

signal interacted

func interact() -> void:
	interacted.emit()
