
extends Area2D

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D

var speed = 70
var direction = 1

func _process(delta: float) -> void:
	position.x += speed * delta * direction


func set_direction(skeleton_direction):
	direction = skeleton_direction
	anim.flip_h = direction < 0


func _on_self_destruct_timer_timeout() -> void:
	queue_free()


func _on_area_entered(area: Area2D) -> void:
	if is_queued_for_deletion():
		return

	# Verifica se a área pertence ao jogador.
	var target = area.get_parent()

	if target and target.has_method("take_damage"):
		target.take_damage()

	queue_free()


func _on_body_entered(body: Node2D) -> void:
	if is_queued_for_deletion():
		return

	# Verifica se o corpo atingido é o jogador.
	if body.has_method("take_damage"):
		body.take_damage()

	queue_free()
