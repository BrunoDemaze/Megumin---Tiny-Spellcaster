
extends Area2D

const SPEED = 100

var direction = 1

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D


func _ready() -> void:
	anim.play("magic")


func set_direction(dir):
	direction = dir

	if direction == 1:
		anim.flip_h = false
	else:
		anim.flip_h = true


func _physics_process(delta: float) -> void:
	position.x += SPEED * delta * direction


func _on_area_entered(area: Area2D) -> void:
	var enemy = area.get_parent()

	if enemy.has_method("take_damage"):
		enemy.take_damage()
		queue_free()


func _on_body_entered(body: Node2D) -> void:
	if is_queued_for_deletion():
		return

	var enemy = body

	while enemy != null and not enemy.has_method("take_damage"):
		enemy = enemy.get_parent()

	if enemy != null:
		enemy.take_damage()
		queue_free()
