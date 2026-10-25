extends CharacterBody2D

# --- Tunables ---
@export var max_speed: float = 900.0
@export var acceleration: float = 3200.0
@export var friction: float = 2600.0
@export var air_acceleration: float = 2000.0
@export var jump_velocity: float = -1000.0
@export var gravity_mult: float = 1.0
@export var fall_gravity_mult: float = 1.6
@export var coyote_time: float = 0.12
@export var jump_buffer_time: float = 0.12

# --- Dash ---
@export var dash_speed: float = 900.0
@export var dash_duration: float = 0.3
@export var dash_cooldown: float = 0.5

# --- Death ---
@export var hit_radius: float = 45.0   # bigger = easier to die

var _gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")
var _coyote_timer: float = 0.0
var _jump_buffer_timer: float = 0.0
var _is_dashing: bool = false
var _dash_timer: float = 0.0
var _dash_cooldown_timer: float = 0.0
var _dash_direction: float = 1.0

@onready var sprite: Node2D = $AnimatedSprite2D if has_node("AnimatedSprite2D") else null

const DEFENDER_LAYER: int = 2   # change to whatever layer your Defenders are on
var _phasing: bool = false

func _ready() -> void:
	add_to_group("player")

func get_facing() -> float:
	return _dash_direction

func _physics_process(delta: float) -> void:
	_handle_timers(delta)
	_handle_dash(delta)

	if not _is_dashing:
		_apply_gravity(delta)
		_handle_horizontal_movement(delta)
		_handle_jump()

	_handle_feint()
	_handle_phase()

	move_and_slide()
	_check_defender_hit()
	_flip_sprite()
	_update_animations()

func _check_defender_hit() -> void:
	var defenders := get_tree().get_nodes_in_group("defender")
	print("defenders found: ", defenders.size())
	if _phasing:
		return
	for defender in defenders:
		var d := global_position.distance_to(defender.global_position)
		print("distance: ", d)
		if d < 60:
			print("hit")
			GameManager.lose_round()
			return

func _update_animations() -> void:
	if sprite == null:
		return

	if abs(velocity.x) > 10.0:
		sprite.play("run")
	else:
		sprite.play("idle")

func _handle_feint() -> void:
	if Input.is_action_just_pressed("feint"):
		for defender in get_tree().get_nodes_in_group("defender"):
			if defender.has_method("try_get_beaten_by_feint"):
				defender.try_get_beaten_by_feint(global_position)

func _handle_phase() -> void:
	if Input.is_action_just_pressed("phase"):
		_phasing = true
		set_collision_mask_value(DEFENDER_LAYER, false)
	elif Input.is_action_just_released("phase"):
		_phasing = false
		set_collision_mask_value(DEFENDER_LAYER, true)

func _handle_timers(delta: float) -> void:
	if is_on_floor():
		_coyote_timer = coyote_time
	else:
		_coyote_timer = max(_coyote_timer - delta, 0.0)

	if Input.is_action_just_pressed("jump"):
		_jump_buffer_timer = jump_buffer_time
	else:
		_jump_buffer_timer = max(_jump_buffer_timer - delta, 0.0)

	_dash_cooldown_timer = max(_dash_cooldown_timer - delta, 0.0)

func _apply_gravity(delta: float) -> void:
	if not is_on_floor():
		var mult := fall_gravity_mult if velocity.y > 0 else gravity_mult
		velocity.y += _gravity * mult * delta

func _handle_horizontal_movement(delta: float) -> void:
	var input_dir := Input.get_axis("left", "right")
	var accel := acceleration if is_on_floor() else air_acceleration

	if input_dir != 0:
		velocity.x = move_toward(velocity.x, input_dir * max_speed, accel * delta)
		_dash_direction = sign(input_dir)
	else:
		var fric := friction if is_on_floor() else air_acceleration * 0.5
		velocity.x = move_toward(velocity.x, 0.0, fric * delta)

func _handle_jump() -> void:
	if _jump_buffer_timer > 0.0 and _coyote_timer > 0.0:
		velocity.y = jump_velocity
		_jump_buffer_timer = 0.0
		_coyote_timer = 0.0
	if Input.is_action_just_released("jump") and velocity.y < 0.0:
		velocity.y *= 0.5

func _handle_dash(delta: float) -> void:
	if Input.is_action_just_pressed("dash") and _dash_cooldown_timer <= 0.0 and not _is_dashing:
		_is_dashing = true
		_dash_timer = dash_duration
		_dash_cooldown_timer = dash_cooldown
		velocity.y = 0.0
		velocity.x = dash_speed * _dash_direction

	if _is_dashing:
		_dash_timer -= delta
		if _dash_timer <= 0.0:
			_is_dashing = false
			velocity.x = clamp(velocity.x, -max_speed, max_speed)

func _flip_sprite() -> void:
	if sprite == null:
		return
	if velocity.x < -10.0:
		sprite.flip_h = true
	elif velocity.x > 10.0:
		sprite.flip_h = false
