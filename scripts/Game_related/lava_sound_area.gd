extends Area2D

@onready var lava_wav: AudioStreamPlayer = $lava_wav

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		lava_wav.play()


func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("Player"):
		lava_wav.stop()
