extends Control

@onready var final_score_label: Label = $CenterContainer/Panel/VBoxContainer/FinalScoreLabel

@onready var highscores_label: Label = $CenterContainer/Panel/VBoxContainer/HighscoresLabel


func _ready() -> void:
	GameManager.finish_run()

	final_score_label.text = "Pontuação final: " + str(GameManager.score)

	update_highscores()


func update_highscores() -> void:
	var text_result = "TOP 5 RECORDES\n\n"

	for i in range(GameManager.high_scores.size()):
		var entry = GameManager.high_scores[i]

		text_result += str(i + 1) + "º - "
		text_result += str(entry["name"])
		text_result += " : "
		text_result += str(entry["score"])
		text_result += " pontos\n"

	highscores_label.text = text_result


func _on_restart_button_pressed() -> void:
	GameManager.start_new_run()

	get_tree().change_scene_to_file(
		"res://cenas/level_1.tscn"
	)


func _on_menu_button_pressed() -> void:
	get_tree().change_scene_to_file(
		"res://cenas/main_menu.tscn"
	)
