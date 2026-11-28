
extends Area2D

const LOADING_SCREEN = preload("res://scene/loading.tscn")

@export var next_level = ""
@export var final_portal := false

var activated = false


func _on_body_entered(body: Node2D) -> void:

	if activated:
		return

	if not body.is_in_group("Player"):
		return

	activated = true
	call_deferred("load_next_scene")


func load_next_scene() -> void:

	var old_scene = get_tree().current_scene

	var loading = LOADING_SCREEN.instantiate()
	get_tree().root.add_child(loading)

	get_tree().current_scene = loading
	old_scene.queue_free()

	if final_portal:
		GameManager.finish_run()
		loading.start_loading("res://scene/victory.tscn")
	else:
		loading.start_loading("res://scene/" + next_level + ".tscn")
