
extends CharacterBody2D

enum FlyState {
	patrol,
	prepare,
	dash,
	recover,
	dead
}

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var hitbox: Area2D = $Hitbox
@onready var player_detector: Area2D = $PlayerDetector
@onready var attack_shape: CollisionShape2D = $AttackHitbox/CollisionShape2D
@onready var detector_shape: CollisionShape2D = $PlayerDetector/CollisionShape2D

# VELOCIDADES
@export var PATROL_SPEED = 18.0
@export var DASH_SPEED = 150.0
@export var PREPARE_BACK_DISTANCE = 12.0
@export var PREPARE_BACK_SPEED = 35.0

# DISTÂNCIA DA PATRULHA
@export var PATROL_DISTANCE = 100.0

# DISTÂNCIA DE DETECÇÃO
@export var DETECTION_DISTANCE = 140.0

# TEMPOS
@export var PREPARE_TIME = 0.35
@export var DASH_TIME = 0.64
@export var RECOVER_TIME = 0.7

var status: FlyState

var direction = 1
var start_position: Vector2

var player: Node2D = null

var state_timer = 0.0
var dash_direction = Vector2.ZERO

var prepare_position: Vector2
var prepare_direction: Vector2

func _ready() -> void:

	start_position = global_position

	attack_shape.set_deferred("disabled", true)

	# Configura o detector
	player_detector.body_entered.connect(
		_on_player_detector_body_entered
	)

	player_detector.body_exited.connect(
		_on_player_detector_body_exited
	)

	anim.play("fly")

	status = FlyState.patrol


func _physics_process(delta: float) -> void:

	if status == FlyState.dead:
		return

	match status:

		FlyState.patrol:
			patrol_state()

		FlyState.prepare:
			prepare_state(delta)

		FlyState.dash:
			dash_state(delta)

		FlyState.recover:
			recover_state(delta)

	move_and_slide()


# ==================================
# PATRULHA
# ==================================

func patrol_state() -> void:

	velocity.x = direction * PATROL_SPEED

	# Pequena movimentação vertical
	velocity.y = sin(Time.get_ticks_msec() * 0.004) * 10.0

	# Limite direito
	if global_position.x >= start_position.x + PATROL_DISTANCE:
		direction = -1

	# Limite esquerdo
	elif global_position.x <= start_position.x - PATROL_DISTANCE:
		direction = 1

	update_direction(direction)


# ==================================
# PREPARAÇÃO DO ATAQUE
# ==================================


func go_to_prepare_state() -> void:

	if status == FlyState.dead:
		return

	status = FlyState.prepare

	velocity = Vector2.ZERO

	state_timer = PREPARE_TIME

	if is_instance_valid(player):

		var difference = player.global_position - global_position

		prepare_direction = difference.normalized()

		update_direction(sign(difference.x))

		# Guarda a posição inicial da preparação
		prepare_position = global_position

	if anim.sprite_frames.has_animation("attack"):
		anim.play("attack")
	else:
		anim.play("fly")


func prepare_state(delta: float) -> void:

	if not is_instance_valid(player):
		go_to_patrol_state()
		return

	# Direção contrária ao jogador
	var backward_direction = -prepare_direction

	# Posição para onde a mosca vai recuar
	var target_position = (
		prepare_position +
		backward_direction * PREPARE_BACK_DISTANCE
	)

	# Movimenta suavemente para trás
	global_position = global_position.move_toward(
		target_position,
		PREPARE_BACK_SPEED * delta
	)

	state_timer -= delta

	if state_timer <= 0:

		if is_instance_valid(player):
			go_to_dash_state()
		else:
			go_to_patrol_state()


# ==================================
# ARRANCADA
# ==================================

func go_to_dash_state() -> void:

	if not is_instance_valid(player):
		go_to_patrol_state()
		return

	status = FlyState.dash

	# Guarda a direção do jogador no momento do ataque
	dash_direction = (
		player.global_position - global_position
	).normalized()

	# Evita direção nula
	if dash_direction == Vector2.ZERO:
		dash_direction = Vector2.RIGHT * direction

	velocity = dash_direction * DASH_SPEED

	state_timer = DASH_TIME

	update_direction(sign(dash_direction.x))

	attack_shape.set_deferred("disabled", false)

	anim.play("attack")

	print("Mosca iniciou a arrancada!")


func dash_state(delta: float) -> void:

	# Mantém a direção e a velocidade do ataque
	velocity = dash_direction * DASH_SPEED

	state_timer -= delta

	if state_timer <= 0:
		go_to_recover_state()


# ==================================
# RECUPERAÇÃO
# ==================================

func go_to_recover_state() -> void:

	status = FlyState.recover

	velocity = Vector2.ZERO

	state_timer = RECOVER_TIME

	attack_shape.set_deferred("disabled", true)

	anim.play("fly_slow")

	print("Mosca está se recuperando!")


func recover_state(delta: float) -> void:

	velocity = Vector2.ZERO

	state_timer -= delta

	if state_timer <= 0:

		if is_instance_valid(player):
			go_to_prepare_state()
		else:
			go_to_patrol_state()


# ==================================
# VOLTAR À PATRULHA
# ==================================

func go_to_patrol_state() -> void:

	status = FlyState.patrol

	velocity = Vector2.ZERO

	anim.play("fly")


# ==================================
# DETECTAR JOGADOR
# ==================================

func _on_player_detector_body_entered(body: Node2D) -> void:

	if body.is_in_group("Player"):
		player = body

		if status == FlyState.patrol:
			go_to_prepare_state()


func _on_player_detector_body_exited(body: Node2D) -> void:
	if body == player:
		player = null

		# Só interrompe a perseguição se ainda estiver patrulhando.
		# Se já começou a preparação, continua o ataque.
		if status == FlyState.patrol:
			return


# ==================================
# DIREÇÃO DO SPRITE
# ==================================

func update_direction(dir: float) -> void:

	if dir < 0:
		anim.flip_h = false

	elif dir > 0:
		anim.flip_h = true


# ==================================
# MORTE
# ==================================

func go_to_dead_state() -> void:

	if status == FlyState.dead:
		return

	status = FlyState.dead

	GameManager.enemy_defeated(50)

	velocity = Vector2.ZERO

	attack_shape.set_deferred("disabled", true)

	hitbox.set_deferred(
		"monitoring",
		false
	)
	hitbox.set_deferred(
		"monitorable",
		false
	)
	anim.play("dead")

	print("Mosca derrotada! +50 pontos")



func _on_animated_sprite_2d_animation_finished() -> void:

	print("Animação finalizada: ", anim.animation)

	if status != FlyState.dead:
		return

	if anim.animation == "dead":

		print("Iniciando poof!")
		anim.play("poof")

	elif anim.animation == "poof":

		print("Mosca desapareceu!")
		queue_free()


func take_damage() -> void:

	if status == FlyState.dead:
		return

	go_to_dead_state()


func _on_attack_hitbox_area_entered(area: Area2D) -> void:

	if status != FlyState.dash:
		return

	if is_queued_for_deletion():
		return

	var target = area.get_parent()

	if target and target.has_method("take_damage"):
		target.take_damage()
