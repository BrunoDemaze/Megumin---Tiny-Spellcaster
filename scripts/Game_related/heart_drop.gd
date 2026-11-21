
extends Area2D

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D


func _ready() -> void:
	anim.play("heart_spin")
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("Player"):
		return

	if body.health >= body.max_health:
		return

	# Recupera uma vida
	body.health += 1

	# Atualiza o coração visualmente
	var heart = body.hearts_list[body.health - 1]

	heart.stop()
	heart.animation = "hurt"
	heart.set_frame(0)

	print("Coração coletado!")
	print("Vida atual: ", body.health)

	# Remove o coração coletável
	queue_free()
