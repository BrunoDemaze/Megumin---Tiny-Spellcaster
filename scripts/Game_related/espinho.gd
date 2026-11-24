extends Area2D

func _ready() -> void:
	add_to_group("LethalArea")

	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if body.has_method("hit_lethal_area"):
		body.hit_lethal_area()
