extends CanvasLayer

@onready var panel: Panel = $Panel

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	panel.hide()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		if get_tree().paused:
			resume_game()
		else:
			pause_game()

		get_viewport().set_input_as_handled()


func pause_game() -> void:
	panel.show()
	get_tree().paused = true


func resume_game() -> void:
	panel.hide()
	get_tree().paused = false


func _on_resume_button_pressed() -> void:
	resume_game()


func _on_menu_button_pressed() -> void:
	get_tree().paused = false
	GameManager.pause_timer()

	get_tree().change_scene_to_file(
		"res://scene/pause_menu.tscn"
	)
