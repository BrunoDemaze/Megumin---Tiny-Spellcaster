
extends AnimatedSprite2D

const HEART_DROP = preload("res://entities/heart_drop.tscn")
const COIN_DROP = preload("res://entities/coin.tscn")

var player_nearby = false
var opened = false


func _ready() -> void:
	play("closed")


func _process(_delta: float) -> void:
	if player_nearby and not opened:
		if Input.is_action_just_pressed("interact"):
			open_chest()


func open_chest() -> void:
	opened = true
	play("open")

	var chance = randf()

	if chance <= 0.25:
		drop_heart()

	elif chance <= 0.50:
		drop_coin()

	else:
		pass


func drop_heart() -> void:
	var heart_instance = HEART_DROP.instantiate()
	get_parent().add_child(heart_instance)
	heart_instance.global_position = global_position + Vector2(0, -20)

func drop_coin() -> void:
	var coin_instance = COIN_DROP.instantiate()
	get_parent().add_child(coin_instance)
	coin_instance.global_position = global_position + Vector2(0, -20)


func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		player_nearby = true


func _on_area_2d_body_exited(body: Node2D) -> void:
	if body.is_in_group("Player"):
		player_nearby = false
