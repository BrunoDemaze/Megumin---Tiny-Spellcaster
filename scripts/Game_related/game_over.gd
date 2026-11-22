extends Control

@onready var final_score_label: Label = $VBoxContainer/FinalScore
@onready var highscores_label: Label = $VBoxContainer/Highscores
@onready var over_wav: AudioStreamPlayer = $over_wav

func _ready() -> void:
	over_wav.play()
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


func _on_restart_pressed() -> void:
	get_tree().change_scene_to_file("res://scene/title_screen.tscn")


func _on_quit_pressed() -> void:
	get_tree().quit()
