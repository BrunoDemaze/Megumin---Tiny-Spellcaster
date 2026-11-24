extends Control

@onready var main_wav: AudioStreamPlayer = $main_wav

const LOADING_SCREEN = preload("res://scene/loading.tscn")

func _ready() -> void:
	main_wav.play()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_start_pressed() -> void:
	GameManager.start_new_run()

	var old_scene = get_tree().current_scene

	var loading = LOADING_SCREEN.instantiate()

	get_tree().root.add_child(loading)
	get_tree().current_scene = loading

	old_scene.queue_free()

	loading.start_loading("res://scene/game.tscn")


func _on_credits_pressed() -> void:
	pass 


func _on_quit_pressed() -> void:
	get_tree().quit()
