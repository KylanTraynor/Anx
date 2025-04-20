extends Node

@export var dialogue_data: DialogueData

var processor: DialogueParser = DialogueParser.new()

func trigger() -> void:
	processor.data = dialogue_data
	processor.dialogue_processed.connect(show_dialogue)
	processor.start("0")
	_process_dialog()

func _process_dialog() -> void:
	while(processor.is_running()):
		await Chat.instance.message_ended
		processor.select_option(0)
	
func show_dialogue(speaker: Variant, dialogue: String, options: Array[String]) -> void:
	print(dialogue)
	Chat.show_message(dialogue)
