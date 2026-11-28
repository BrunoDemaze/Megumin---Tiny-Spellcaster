
extends Control

@onready var final_score_label: Label = $VBoxContainer/FinalScore
@onready var highscores_label: Label = $VBoxContainer/Highscores
@onready var won_wav: AudioStreamPlayer = $won_wav


func _ready() -> void:

	# Toca o som de vitória
	if won_wav and won_wav.stream:
		won_wav.play()

	# Mostra a pontuação final
	final_score_label.text = "Pontuação final: " + str(GameManager.score)

	# Atualiza o Top 5
	update_highscores()

	# Para o som após 1,3 segundos
	await get_tree().create_timer(1.30).timeout

	if is_instance_valid(won_wav) and won_wav.playing:
		won_wav.stop()


func update_highscores() -> void:

	var text_result := "TOP 5 RECORDES\n\n"
	var limit: int = min(GameManager.high_scores.size(), 5)

	for i in range(limit):

		var entry = GameManager.high_scores[i]

		var player_name := str(entry.get("name", "---"))
		var score_val := str(entry.get("score", 0))

		text_result += "%dº - %s : %s pontos\n" % [
			i + 1,
			player_name,
			score_val
		]

	highscores_label.text = text_result


func _on_restart_pressed() -> void:
	get_tree().change_scene_to_file("res://scene/title_screen.tscn")


func _on_quit_pressed() -> void:
	get_tree().quit()
