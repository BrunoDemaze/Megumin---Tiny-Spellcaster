extends Control

@onready var progress_bar: ProgressBar = $ProgressBar
@onready var percentage: Label = $Percentage

var next_scene_path: String = ""
var elapsed_time: float = 0.0
var transition_started: bool = false


func _ready() -> void:
	progress_bar.min_value = 0
	progress_bar.max_value = 100
	progress_bar.value = 0
	percentage.text = "0%"


func start_loading(path: String) -> void:
	next_scene_path = path
	elapsed_time = 0.0
	transition_started = false

	progress_bar.value = 0
	percentage.text = "0%"

	var error = ResourceLoader.load_threaded_request(next_scene_path)

	if error != OK:
		push_error("Erro ao iniciar o carregamento da fase: " + next_scene_path)


func _process(delta: float) -> void:
	if next_scene_path == "" or transition_started:
		return

	elapsed_time += delta

	if elapsed_time < 0.75:
		update_progress(0)

	elif elapsed_time < 1.5:
		update_progress(25)

	elif elapsed_time < 2.25:
		update_progress(50)

	else:
		update_progress(100)

		var status = ResourceLoader.load_threaded_get_status(next_scene_path)

		if status == ResourceLoader.THREAD_LOAD_LOADED:
			transition_started = true
			finish_loading()

		elif status == ResourceLoader.THREAD_LOAD_FAILED:
			push_error("Falha ao carregar a próxima fase.")


func update_progress(value: int) -> void:
	progress_bar.value = value
	percentage.text = str(value) + "%"


func finish_loading() -> void:
	var packed_scene = ResourceLoader.load_threaded_get(next_scene_path)

	if packed_scene:
		get_tree().change_scene_to_packed(packed_scene)
