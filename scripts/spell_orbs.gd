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
