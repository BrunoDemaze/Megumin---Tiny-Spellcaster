extends CharacterBody2D

enum PlayerState{
	idle,
	walk,
	jump,
	fall,
	duck,
	dead,
	spell
}

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

const SPEED = 65.0
const JUMP_VELOCITY = -300.0
const ORB = preload("res://itens/spell_orbs.tscn")

var jump_count = 0
@export var max_jump_count = 2
var direction = 0
var status: PlayerState
var spell_created = false
var previous_status: PlayerState

func _ready() -> void:
	go_to_idle_state()

	if not anim.animation_finished.is_connected(_on_animated_sprite_2d_animation_finished):
		anim.animation_finished.connect(_on_animated_sprite_2d_animation_finished)

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
	
func go_to_dead_state():
	status = PlayerState.dead
	anim.play("hurt")
	
func exit_from_duck_state():
	collision_shape.shape.radius = 7
	collision_shape.shape.height = 20
	collision_shape.position.y = 0


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

	if Input.is_action_just_pressed("magic"):
		go_to_spell_state()
		return

	if velocity.x == 0:
		go_to_idle_state()
		return

	if Input.is_action_just_pressed("jump"):
		go_to_jump_state()
		return

	if !is_on_floor():
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
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Handle jump.
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY
		
func dead_state():
	pass
	
	
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

func _on_hitbox_area_entered(area: Area2D) -> void:
	pass # Replace with function body.
