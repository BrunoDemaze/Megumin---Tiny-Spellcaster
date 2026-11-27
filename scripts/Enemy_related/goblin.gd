
extends CharacterBody2D

enum GoblinState {
	walk,
	chase,
	attack,
	hurt,
	dead
}

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var hitbox: Area2D = $hitbox
@onready var wall_detector: RayCast2D = $WallDetector
@onready var ground_detector: RayCast2D = $GroundDetector
@onready var player_detector: RayCast2D = $PlayerDetector
@onready var attack_range: Area2D = $AttackRange
@onready var dead_wav: AudioStreamPlayer = $gob_dead_wav
@onready var attack_wav: AudioStreamPlayer = $gob_attack_wav

const SPEED = 32.0

var status: GoblinState
var direction = 1

var health = 2
var target: Node2D = null

var player_in_range = false
var can_attack = false
var attack_hit_done = false


func _ready() -> void:
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

	if player_detector.is_colliding():
		var detected = player_detector.get_collider()

		if detected is Node2D and detected.is_in_group("Player"):
			target = detected

	match status:

		GoblinState.walk:
			walk_state()

		GoblinState.chase:
			chase_state()

		GoblinState.attack:
			attack_state()

		GoblinState.hurt:
			hurt_state()

		GoblinState.dead:
			dead_state()

	move_and_slide()


# =========================
# WALK
# =========================

func go_to_walk_state() -> void:
	status = GoblinState.walk
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
	anim.play("walk")


func chase_state() -> void:

	if target == null or not is_instance_valid(target):
		target = null
		player_in_range = false
		go_to_walk_state()
		return

	var distance = target.global_position.x - global_position.x

	if distance != 0:
		direction = 1 if distance > 0 else -1
		update_facing()

	if player_in_range:
		go_to_attack_state()
		return

	velocity.x = SPEED * direction


# =========================
# ATTACK
# =========================

func go_to_attack_state() -> void:

	status = GoblinState.attack
	anim.play("attack")

	velocity.x = 0
	can_attack = true
	attack_hit_done = false

	attack_wav.play()


func attack_state() -> void:

	velocity.x = 0

	if anim.animation == "attack" and anim.frame == 2 and can_attack and not attack_hit_done:

		attack_hit_done = true

		if player_in_range and target != null and is_instance_valid(target):

			if target.has_method("take_damage"):
				target.take_damage()

		can_attack = false


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
	player_in_range = false

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

		target = body
		player_in_range = true


func _on_attack_range_body_exited(body: Node2D) -> void:

	if body == target:

		player_in_range = false


# =========================
# DIRECTION
# =========================

func turn_around() -> void:

	direction *= -1

	update_facing()


func update_facing() -> void:

	anim.flip_h = direction > 0

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
		else:
			if target != null and is_instance_valid(target):
				go_to_chase_state()
			else:
				go_to_walk_state()

		return

	if anim.animation == "attack":

		if player_in_range and target != null and is_instance_valid(target):
			go_to_attack_state()
		elif target != null and is_instance_valid(target):
			go_to_chase_state()
		else:
			go_to_walk_state()

		return

	if anim.animation == "dead":
		queue_free()
		return
