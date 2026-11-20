
extends CanvasLayer

@onready var score_label: Label = $ScoreLabel
@onready var coins_label: Label = $CoinsLabel


func _ready() -> void:

	# Conecta a pontuação
	if not GameManager.score_changed.is_connected(update_score):
		GameManager.score_changed.connect(update_score)

	# Conecta as moedas
	if not GameManager.coins_changed.is_connected(update_coins):
		GameManager.coins_changed.connect(update_coins)

	# Atualiza os valores iniciais
	update_score(GameManager.score)
	update_coins(GameManager.coins)


func update_score(new_score: int) -> void:
	score_label.text = "Pontos: " + str(new_score)


func update_coins(new_coins: int) -> void:
	coins_label.text = "Moedas: " + str(new_coins)
