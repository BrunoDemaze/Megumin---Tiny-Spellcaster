extends Node

signal score_changed(new_score: int)
signal coins_changed(new_coins: int)

# PONTUAÇÃO
var score: int = 0
var coins: int = 0

# CRONÔMETRO
var elapsed_time: float = 0.0
var total_time: float = 0.0
var penalty_interval: float = 1.0
var timer_running: bool = false

# PARTIDA
var run_finished: bool = false

# RECORDES
const MAX_HIGHSCORES = 5
const SAVE_PATH = "user://highscores.cfg"

var high_scores: Array = []


func _ready() -> void:
	load_highscores()


func _process(delta: float) -> void:
	if not timer_running:
		return

	if get_tree().paused:
		return

	if run_finished:
		return

	elapsed_time += delta
	total_time += delta
	
	while elapsed_time >= penalty_interval:
		elapsed_time -= penalty_interval
		remove_score(1)


# ==================================
# PONTUAÇÃO
# ==================================

func add_score(points: int) -> void:
	score += points
	score_changed.emit(score)


func remove_score(points: int) -> void:
	score = max(0, score - points)
	score_changed.emit(score)


func player_took_damage(points: int = 25) -> void:
	remove_score(points)
	print("Jogador recebeu dano! -", points, " pontos")


func add_coin(points: int = 10) -> void:
	coins += 1
	add_score(points)
	coins_changed.emit(coins)


func enemy_defeated(points: int = 50) -> void:
	add_score(points)


# ==================================
# CRONÔMETRO
# ==================================

func start_timer() -> void:
	timer_running = true


func pause_timer() -> void:
	timer_running = false


func resume_timer() -> void:
	if not run_finished:
		timer_running = true


# ==================================
# PARTIDA
# ==================================

func start_new_run() -> void:
	score = 0
	coins = 0
	elapsed_time = 0.0
	total_time = 0.0
	timer_running = true
	run_finished = false

	score_changed.emit(score)
	coins_changed.emit(coins)


func finish_run() -> void:
	if run_finished:
		return

	run_finished = true
	timer_running = false

	register_highscore()


# ==================================
# RECORDES
# ==================================

func load_highscores() -> void:
	var config = ConfigFile.new()

	var error = config.load(SAVE_PATH)

	if error == OK:
		high_scores = config.get_value(
			"highscores",
			"entries",
			[]
		)
	else:
		high_scores = []


func save_highscores() -> void:
	var config = ConfigFile.new()

	config.set_value(
		"highscores",
		"entries",
		high_scores
	)

	var error = config.save(SAVE_PATH)

	if error != OK:
		push_error("Erro ao salvar os recordes: " + str(error))


func register_highscore(player_name: String = "Jogador") -> void:
	var entry = {
		"name": player_name,
		"score": score
	}

	high_scores.append(entry)

	high_scores.sort_custom(
		func(a, b):
			return int(a["score"]) > int(b["score"])
	)

	if high_scores.size() > MAX_HIGHSCORES:
		high_scores.resize(MAX_HIGHSCORES)

	save_highscores()


func reset_run() -> void:
	start_new_run()
