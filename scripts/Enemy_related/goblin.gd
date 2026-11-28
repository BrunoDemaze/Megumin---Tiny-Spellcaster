
extends CharacterBody2D

enum GoblinState {
	walk,
	chase,
	attack,
	ranged_attack,
	hurt,
	dead
}

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var hitbox: Area2D = $hitbox
@onready var wall_detector: RayCast2D = $WallDetector
@onready var ground_detector: RayCast2D = $GroundDetector
@onready var player_detector: RayCast2D = $PlayerDetector
@onready var attack_range: Area2D = $AttackRange
@onready var lance_start_position: Node2D = $LanceStartPosition
@onready var dead_wav: AudioStreamPlayer = $gob_dead_wav
@onready var attack_wav: AudioStreamPlayer = $gob_attack_wav

const SPEED = 32.0
const LANCE = preload("res://entities/lance.tscn")

@export var lance_min_distance = 100.0
@export var lance_max_distance = 200.0
@export var lance_cooldown = 2.0

var status: GoblinState
var direction = 1

var health = 2
var target: Node2D = null

var can_attack = false
var attack_hit_done = false
var can_throw_lance = true

var lance_start_offset: Vector2


func _ready() -> void:
	lance_start_offset = Vector2(
		abs(lance_start_position.position.x),
		lance_start_position.position.y
	)

	go_to_walk_state()

	if not anim.animation_finished.is_connected(_on_animation_finished):
		anim.animation_finished.connect(_on_animation_finished)

	if not attack_range.body_entered.is_connected(_on_attack_range_body_entered):
		attack_range.body_entered.connect(_on_attack_range_body_entered)

	if not attack_range.body_exited.is_connected(_on_attack_range_body_exited):
		attack_range.body_exited.connect(_on_attack_range_body_exited)


func _physics_process(delta: float) -> void:

	if not is_on_floor():
		velocity += get_gravity() * delta

	# Atualiza a detecção do jogador
	if player_detector.is_colliding():
		var detected = player_detector.get_collider()

		if detected is Node2D and detected.is_in_group("Player"):
			target = detected
		else:
			target = null
	else:
		target = null

	# Se perdeu a detecção durante a perseguição,
	# volta a patrulhar
	if status == GoblinState.chase or status == GoblinState.ranged_attack:
		if target == null or not is_instance_valid(target):
			target = null
			go_to_walk_state()

	match status:
		GoblinState.walk:
			walk_state()

		GoblinState.chase:
			chase_state()

		GoblinState.attack:
			attack_state()

		GoblinState.ranged_attack:
			ranged_attack_state()

		GoblinState.hurt:
			hurt_state()

		GoblinState.dead:
			dead_state()

	move_and_slide()


# =========================
# VERIFICAÇÃO DE ALCANCE
# =========================

func is_player_in_attack_range() -> bool:

	if not is_instance_valid(target):
		return false

	return attack_range.overlaps_body(target)


# =========================
# WALK
# =========================

func go_to_walk_state() -> void:
	status = GoblinState.walk
	can_attack = false
	velocity.x = 0
	anim.play("walk")


func walk_state() -> void:

	velocity.x = SPEED * direction

	if wall_detector.is_colliding() or not ground_detector.is_colliding():
		turn_around()

	if target != null and is_instance_valid(target):
		go_to_chase_state()


# =========================
# CHASE
# =========================

func go_to_chase_state() -> void:
	status = GoblinState.chase
	can_attack = false
	anim.play("walk")


func chase_state() -> void:

	if target == null or not is_instance_valid(target):
		target = null
		go_to_walk_state()
		return

	var distance = target.global_position.x - global_position.x
	var absolute_distance = abs(distance)

	if distance != 0:
		direction = 1 if distance > 0 else -1
		update_facing()

	# Corpo a corpo somente dentro do AttackRange
	if is_player_in_attack_range():
		go_to_attack_state()
		return

	# Lança quando estiver na distância configurada
	if absolute_distance >= lance_min_distance \
	and absolute_distance <= lance_max_distance \
	and can_throw_lance:
		go_to_ranged_attack_state()
		return

	velocity.x = SPEED * direction


# =========================
# ATAQUE COM LANÇA
# =========================

func go_to_ranged_attack_state() -> void:

	status = GoblinState.ranged_attack
	velocity.x = 0

	if anim.sprite_frames.has_animation("throw"):
		anim.play("throw")
	else:
		anim.play("walk")

	launch_lance()


func ranged_attack_state() -> void:
	velocity.x = 0


func launch_lance() -> void:

	can_throw_lance = false

	# Atualiza a posição de lançamento antes de criar a lança
	update_facing()

	var new_lance = LANCE.instantiate()
	get_parent().add_child(new_lance)

	new_lance.set_direction(direction)
	new_lance.global_position = lance_start_position.global_position

	await get_tree().create_timer(lance_cooldown).timeout

	if not is_inside_tree():
		return

	if status == GoblinState.dead:
		return

	can_throw_lance = true

	if target != null and is_instance_valid(target):
		if is_player_in_attack_range():
			go_to_attack_state()
		else:
			go_to_chase_state()
	else:
		go_to_walk_state()


# =========================
# ATTACK
# =========================

func go_to_attack_state() -> void:

	if status == GoblinState.dead or status == GoblinState.hurt:
		return

	# Não inicia ataque se o jogador estiver longe
	if not is_player_in_attack_range():
		go_to_chase_state()
		return

	status = GoblinState.attack

	velocity.x = 0
	can_attack = true
	attack_hit_done = false

	anim.play("attack")
	attack_wav.play()


func attack_state() -> void:

	velocity.x = 0

	if anim.animation != "attack":
		return

	# Confere no quadro do golpe
	if anim.frame == 2 and can_attack and not attack_hit_done:

		attack_hit_done = true
		can_attack = false

		# Confere novamente se a Megumin ainda está perto
		if is_player_in_attack_range():
			if target.has_method("take_damage"):
				target.take_damage()


# =========================
# DAMAGE
# =========================

func take_damage() -> void:

	if status == GoblinState.dead:
		return

	if status == GoblinState.hurt:
		return

	health -= 1

	status = GoblinState.hurt

	velocity.x = 0
	can_attack = false

	anim.play("hurt")


func hurt_state() -> void:
	velocity.x = 0


# =========================
# DEATH
# =========================

func go_to_dead_state() -> void:

	if status == GoblinState.dead:
		return

	status = GoblinState.dead

	GameManager.enemy_defeated(50)

	velocity = Vector2.ZERO

	hitbox.process_mode = Node.PROCESS_MODE_DISABLED
	attack_range.monitoring = false

	can_attack = false

	anim.play("dead")

	play_death_sound()


func play_death_sound() -> void:

	dead_wav.play(0.47)

	await get_tree().create_timer(0.68).timeout

	if is_instance_valid(dead_wav):
		dead_wav.stop()


func dead_state() -> void:
	velocity.x = 0


# =========================
# DETECTION
# =========================

func _on_attack_range_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		if status == GoblinState.chase:
			player_in_range_check()


func _on_attack_range_body_exited(body: Node2D) -> void:

	if body.is_in_group("Player") and status == GoblinState.attack:
		can_attack = false

		if target != null and is_instance_valid(target):
			go_to_chase_state()
		else:
			go_to_walk_state()


func player_in_range_check() -> void:

	if is_player_in_attack_range():
		go_to_attack_state()


# =========================
# DIRECTION
# =========================

func turn_around() -> void:

	direction *= -1
	update_facing()


func update_facing() -> void:

	anim.flip_h = direction > 0

	lance_start_position.position = Vector2(
		lance_start_offset.x * direction,
		lance_start_offset.y
	)

	wall_detector.target_position.x = abs(wall_detector.target_position.x) * direction
	ground_detector.target_position.x = 8.0 * direction
	player_detector.target_position.x = abs(player_detector.target_position.x) * direction

	wall_detector.force_raycast_update()
	ground_detector.force_raycast_update()
	player_detector.force_raycast_update()


# =========================
# ANIMATION FINISHED
# =========================

func _on_animation_finished() -> void:

	if anim.animation == "hurt":

		if health <= 0:
			go_to_dead_state()
		elif target != null and is_instance_valid(target):
			go_to_chase_state()
		else:
			go_to_walk_state()

		return

	if anim.animation == "attack":

		can_attack = false

		if target != null and is_instance_valid(target):
			if is_player_in_attack_range():
				go_to_attack_state()
			else:
				go_to_chase_state()
		else:
			go_to_walk_state()

		return

	if anim.animation == "dead":
		queue_free()
		return
