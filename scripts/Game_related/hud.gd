
extends CanvasLayer

@onready var score_label: Label = $ScoreShow
@onready var time_label: Label = $TimeLabel


func _ready() -> void:

	# Conecta a pontuação
	if not GameManager.score_changed.is_connected(update_score):
		GameManager.score_changed.connect(update_score)

	# Atualiza os valores iniciais
	update_score(GameManager.score)
	update_timer()


func _process(_delta: float) -> void:
	update_timer()


func update_score(new_score: int) -> void:
	score_label.text = "Pontos: " + str(new_score)


func update_timer() -> void:

	var total_seconds = int(GameManager.total_time)

	var minutes = int(total_seconds / 60)
	var seconds = total_seconds % 60

	time_label.text = "%02d:%02d" % [minutes, seconds]
