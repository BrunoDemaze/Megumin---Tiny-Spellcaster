
extends Area2D

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var smoke: AnimatedSprite2D = $smoke

const SPEED = 150.0

var direction = 1
var has_hit = false


func _ready() -> void:

	anim.play("throw")
	smoke.play("cloud")

	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)


func _physics_process(delta: float) -> void:

	if has_hit:
		return

	global_position.x += SPEED * direction * delta


func set_direction(new_direction: int) -> void:

	direction = new_direction
	anim.flip_h = direction > 0
	smoke.flip_h = direction > 0


func _on_body_entered(body: Node2D) -> void:

	if has_hit:
		return

	if body.is_in_group("Player"):

		has_hit = true

		if body.has_method("take_damage"):
			body.take_damage()

		queue_free()
		return

	if body is PhysicsBody2D or body is TileMapLayer:

		has_hit = true
		queue_free()


func _on_area_entered(area: Area2D) -> void:

	if has_hit:
		return

	# Layer 5 = lethal_area
	if area.collision_layer & (1 << 4):

		has_hit = true
		queue_free()
