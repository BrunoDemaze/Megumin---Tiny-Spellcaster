extends Area2D

const SPEED = 100

var velocity = Vector2.ZERO
var direction = 1

func _ready() -> void:
	pass 

func set_direction(dir):
	direction = dir
	if direction == 1:
		$anim.flip_h = false
	else:
		$anim.flip_h = true

func _physics_process(delta: float) -> void:
	velocity.x = SPEED * delta * direction
	translate(velocity)
