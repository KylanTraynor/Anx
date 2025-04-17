extends Area2D

class_name Interactable

signal interacted

@export var dialogue_data: DialogueData

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node2D) -> void:
	if(body == Main.instance.player):
		Main.set_interactable(self)

func _on_body_exited(body: Node2D) -> void:
	if(body == Main.instance.player):
		Main.unset_interactable(self)

func interact() -> void:
	interacted.emit()
