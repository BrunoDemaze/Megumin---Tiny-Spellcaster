extends Control

@onready var main_wav: AudioStreamPlayer = $main_wav

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	main_wav.play()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_start_pressed() -> void:
	GameManager.start_new_run()
	get_tree().change_scene_to_file("res://scene/game.tscn")


func _on_credits_pressed() -> void:
	pass 


func _on_quit_pressed() -> void:
	get_tree().quit()
