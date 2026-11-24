extends Area2D

const LOADING_SCREEN = preload("res://scene/loading.tscn")

@export var next_level = ""

var activated = false


func _on_body_entered(_body: Node2D) -> void:
	if activated:
		return

	activated = true
	call_deferred("load_next_scene")


func load_next_scene() -> void:
	var old_scene = get_tree().current_scene

	var loading = LOADING_SCREEN.instantiate()
	get_tree().root.add_child(loading)

	get_tree().current_scene = loading
	old_scene.queue_free()

	loading.start_loading("res://scene/" + next_level + ".tscn")
