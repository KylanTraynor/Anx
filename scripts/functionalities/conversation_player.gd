extends Node

@export var dialogue_data: DialogueData

var processor: DialogueParser = DialogueParser.new()

var waiting_for_choice: bool = false

func trigger() -> void:
	processor.data = dialogue_data
	processor.dialogue_processed.connect(show_dialogue)
	processor.dialogue_ended.connect(_on_conversation_ended)
	Chat.instance.choice_selected.connect(select_option)
	Chat.instance.message_ended.connect(_on_message_ended)
	print("Start")
	processor.start("0")

func _on_conversation_ended() -> void:
	print("End")
	pass

func select_option(option: int) -> void:
	await Chat.instance.message_ended
	processor.select_option(option)
	pass

func _on_message_ended(_text: String) -> void:
	if(waiting_for_choice):
		pass
	else:
		processor.select_option(0)
	
func show_dialogue(speaker: Variant, dialogue: String, options: Array[String]) -> void:
	if options[0] == "" and len(options) == 1:
		waiting_for_choice = false
	else:
		waiting_for_choice = true
	Chat.show_message(speaker, dialogue, options)
