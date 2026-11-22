
extends CharacterBody2D

enum PlayerState{
	idle,
	walk,
	jump,
	fall,
	duck,
	damage,
	dead,
	spell
}

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var hitbox_collision_shape: CollisionShape2D = $Hitbox/CollisionShape2D
@onready var jump_wav: AudioStreamPlayer = $jump_wav as AudioStreamPlayer
@onready var walk_wav: AudioStreamPlayer = $walk_wav

const SPEED = 65.0
const JUMP_VELOCITY = -300.0
const ORB = preload("res://itens/spell_orbs.tscn")

var jump_count = 0
@export var max_jump_count = 2
var direction = 0
var status: PlayerState
var spell_created = false
var previous_status: PlayerState
var hearts_list: Array[AnimatedSprite2D]
var health = 3

# NOVO: SISTEMA DE VIDA
@export var max_health = 3
@export var invulnerability_time = 2.0

var invulnerable = false
var blink_tween: Tween
var coin_counter = 0



func _ready() -> void:
	health = max_health
	go_to_idle_state()

	if not anim.animation_finished.is_connected(_on_animated_sprite_2d_animation_finished):
		anim.animation_finished.connect(_on_animated_sprite_2d_animation_finished)

	var hearts_parent = $health_bar/HBoxContainer

	for child in hearts_parent.get_children():
		var heart = child.get_node("Heart")
		hearts_list.append(heart)

	print(hearts_list)


func _physics_process(delta: float) -> void:

	if not is_on_floor():
		velocity += get_gravity() * delta

	match status:
		PlayerState.idle:
			idle_state()
		PlayerState.walk:
			walk_state()
		PlayerState.jump:
			jump_state()
		PlayerState.fall:
			fall_state()
		PlayerState.duck:
			duck_state()
		PlayerState.damage:
			damage_state()    
		PlayerState.dead:
			dead_state()
		PlayerState.spell:
			spell_state()

	move_and_slide()


func go_to_idle_state():
	status = PlayerState.idle
	anim.play("idle")


func go_to_walk_state():
	status = PlayerState.walk
	anim.play("walk")


func go_to_spell_state():
	previous_status = status
	status = PlayerState.spell
	spell_created = false
	anim.play("spell")


func go_to_jump_state():
	status = PlayerState.jump
	anim.play("jump")
	jump_wav.play()
	velocity.y = JUMP_VELOCITY
	jump_count += 1


func go_to_fall_state():
	status = PlayerState.fall
	anim.play("fall")


func go_to_duck_state():
	status = PlayerState.duck
	anim.play("duck")
	collision_shape.shape.radius = 5
	collision_shape.shape.height = 10
	collision_shape.position.y = 5

	hitbox_collision_shape.shape.size.y = 10
	hitbox_collision_shape.position.y = 5
	
func go_to_damage_state():
	status = PlayerState.damage
	anim.play("damage")
	velocity.x = 0


func go_to_dead_state():
	if status == PlayerState.dead:
		return

	status = PlayerState.dead
	anim.play("dead")
	velocity.x = 0

	if blink_tween and blink_tween.is_running():
		blink_tween.kill()

	anim.modulate = Color.WHITE

	await get_tree().create_timer(1.0).timeout

	GameManager.finish_run()

	get_tree().change_scene_to_file(
		"res://scene/game_over.tscn"
)


func exit_from_duck_state():
	collision_shape.shape.radius = 7
	collision_shape.shape.height = 18
	collision_shape.position.y = 1

	hitbox_collision_shape.shape.size.y = 18
	hitbox_collision_shape.position.y = 1


func idle_state():
	move()

	if Input.is_action_just_pressed("magic"):
		go_to_spell_state()
		return

	if velocity.x != 0:
		go_to_walk_state()
		return

	if Input.is_action_just_pressed("jump"):
		go_to_jump_state()
		return

	if Input.is_action_pressed("duck"):
		go_to_duck_state()
		return


func walk_state():
	move()

	if not walk_wav.playing:
		walk_wav.play()

	if Input.is_action_just_pressed("magic"):
		walk_wav.stop()
		go_to_spell_state()
		return

	if velocity.x == 0:
		walk_wav.stop()
		go_to_idle_state()
		return

	if Input.is_action_just_pressed("jump"):
		walk_wav.stop()
		go_to_jump_state()
		return

	if !is_on_floor():
		walk_wav.stop()
		go_to_fall_state()
		return


func spell_state():
	move()

	if not spell_created:
		var spell_instance = ORB.instantiate()
		var dir = -1 if anim.flip_h else 1

		get_parent().add_child(spell_instance)

		spell_instance.set_direction(dir)
		spell_instance.global_position = global_position + Vector2(dir * 15, 0)

		spell_created = true


func _on_animated_sprite_2d_animation_finished():

	if status == PlayerState.damage:
		if not is_on_floor():
			if velocity.y < 0:
				status = PlayerState.jump
				anim.play("jump")
			else:
				go_to_fall_state()

		elif Input.is_action_pressed("duck"):
			go_to_duck_state()

		elif Input.get_axis("left", "right") != 0:
			go_to_walk_state()

		else:
			go_to_idle_state()

		return

	if status != PlayerState.spell:
		return

	if not is_on_floor():
		if velocity.y < 0:
			status = PlayerState.jump
			anim.play("jump")
		else:
			go_to_fall_state()

	elif Input.is_action_pressed("duck"):
		go_to_duck_state()

	elif velocity.x != 0:
		go_to_walk_state()

	else:
		go_to_idle_state()


func jump_state():
	move()
	

	if Input.is_action_just_pressed("magic"):
		go_to_spell_state()
		return

	if Input.is_action_just_pressed("jump") && can_jump():
		go_to_jump_state()
		return

	if velocity.y > 0:
		go_to_fall_state()
		return

	if Input.is_action_just_pressed("jump") && can_jump():
		go_to_jump_state()
		return

	if velocity.y > 0:
		go_to_fall_state()
		return


func fall_state():
	move()

	if Input.is_action_just_pressed("jump") && can_jump():
		go_to_jump_state()
		return

	if is_on_floor():
		jump_count = 0

		if velocity.x == 0:
			go_to_idle_state()
		else:
			go_to_walk_state()
			return


func duck_state():
	update_direction()

	if Input.is_action_just_released("duck"):
		exit_from_duck_state()
		go_to_idle_state()
		return


func temp(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta

	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY


func damage_state():
	velocity.x = 0

func dead_state():
	velocity.x = 0


func move():
	update_direction()

	if direction:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)


func update_direction():
	direction = Input.get_axis("left", "right")

	if direction < 0:
		anim.flip_h = true
	elif direction > 0:
		anim.flip_h = false


func can_jump() -> bool:
	return jump_count < max_jump_count


# NOVO: RECEBER DANO

# RECEBER DANO

func take_damage():
	if status == PlayerState.dead or invulnerable:
		return

	health -= 1

	# Remove 25 pontos ao receber dano
	GameManager.player_took_damage(25)

	print("Vida: ", health)
	print("Pontuação: ", GameManager.score)

	if health >= 0 and health < hearts_list.size():
		hearts_list[health].play("hurt")

	if health <= 0:
		go_to_dead_state()
		return

	go_to_damage_state()
	start_invulnerability()

# NOVO: INVULNERABILIDADE DE 2 SEGUNDOS

func start_invulnerability():
	invulnerable = true

	blink_tween = create_tween().set_loops()

	blink_tween.tween_property(
		anim,
		"modulate",
		Color(1, 0.3, 0.3, 0.25),
		0.1
	)

	blink_tween.tween_property(
		anim,
		"modulate",
		Color.WHITE,
		0.1
	)

	await get_tree().create_timer(invulnerability_time).timeout

	if status == PlayerState.dead:
		return

	if blink_tween and blink_tween.is_running():
		blink_tween.kill()

	anim.modulate = Color.WHITE
	invulnerable = false


# COLISÕES ORIGINAIS

func _on_hitbox_area_entered(area: Area2D) -> void:
	if area.is_in_group("coin"):
		GameManager.add_coin(10)

		var som = area.get_node("coin_wav")
		area.set_deferred("monitoring", false)
		area.hide()
		som.play()
		await som.finished

		print("Moedas: ", GameManager.coins)
		print("Pontuação: ", GameManager.score)

		area.queue_free()

	elif area.is_in_group("Enemies"):
		hit_enemy(area)

	elif area.is_in_group("lethalArea"):
		hit_lethal_area()


func _on_hitbox_body_entered(body: Node2D) -> void:
	if body.is_in_group("LethalArea"):
		go_to_dead_state()


func hit_enemy(area: Area2D):
	if status == PlayerState.dead:
		return

	# Não mata mais o jogador ao encostar no inimigo.
	# O dano será controlado pelo projétil do esqueleto.

func hit_lethal_area():
	go_to_dead_state()

func set_coin(new_coin_count: int) -> void:
	coin_counter = new_coin_count
