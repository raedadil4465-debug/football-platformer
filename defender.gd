extends CharacterBody2D

## Defender: chases whoever's closest holding the ball...

@export var chase_speed: float = 260.0
@export var acceleration: float = 1400.0
@export var stumble_duration: float = 0.9
@export var feint_beat_radius: float = 70.0

# Allow assigning a target directly in the Inspector, or leave blank to auto-find
@export var target_node: NodePath

var _target: Node2D = null
var _stumbling: bool = false
var _stumble_timer: float = 0.0

@onready var sprite: Node2D = $AnimatedSprite2D if has_node("AnimatedSprite2D") else null

func _ready() -> void:
	# 1. If a target node was assigned in the Inspector, use it
	if not target_node.is_empty():
		_target = get_node(target_node)
	else:
		# 2. Otherwise, automatically look for a node in the "player" group
		_target = get_tree().get_first_node_in_group("player")
		
		# Fallback: If no group found, look for a node named "Ball" or similar
		if _target == null and get_parent().has_node("Ball"):
			_target = get_parent().get_node("Ball")

func _physics_process(delta: float) -> void:
	if _stumbling:
		_stumble_timer -= delta
		velocity = velocity.move_toward(Vector2.ZERO, acceleration * delta)
		if _stumble_timer <= 0.0:
			_stumbling = false
		move_and_slide()
		return

	if _target:
		var dir := (_target.global_position - global_position).normalized()
		velocity = velocity.move_toward(dir * chase_speed, acceleration * delta)
	
	move_and_slide()
	_flip_sprite()

func set_target(t: Node2D) -> void:
	_target = t

func try_get_beaten_by_feint(feint_position: Vector2) -> bool:
	# Call this on nearby defenders when the player performs a feint.
	if global_position.distance_to(feint_position) <= feint_beat_radius:
		stumble()
		return true
	return false


func stumble() -> void:
	_stumbling = true
	_stumble_timer = stumble_duration
	# Sell it: lurch the wrong way briefly before freezing.
	if _target:
		var wrong_way := -(_target.global_position - global_position).normalized()
		velocity = wrong_way * chase_speed * 0.6


func _flip_sprite() -> void:
	if sprite == null:
		return
	sprite.flip_h = velocity.x < 0.0
