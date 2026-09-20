extends CharacterBody2D

@export var dribble_offset: float = 24.0      # X distance in front of player
@export var dribble_y_offset: float = 12.0     # Y distance (Positive = DOWN towards feet)
@export var follow_speed: float = 25.0
@export var friction: float = 600.0
var _owner_player: Node2D = null

@onready var dribble_area: Area2D = $DribbleArea if has_node("DribbleArea") else null
@onready var main_collision: CollisionShape2D = %CollisionShape2D if has_node("%CollisionShape2D") else null

func _ready() -> void:
	add_to_group("ball")
	if dribble_area and not dribble_area.body_entered.is_connected(_on_dribble_area_body_entered):
		dribble_area.body_entered.connect(_on_dribble_area_body_entered)
func _physics_process(delta: float) -> void:
	if _owner_player:
		# --- DRIBBLING STATE ---
		var facing := 1.0
		if _owner_player.has_method("get_facing"):
			facing = _owner_player.get_facing()

		# +dribble_y_offset pushes the ball down towards the feet
		var target_pos := _owner_player.global_position + Vector2(dribble_offset * facing, dribble_y_offset)
		global_position = global_position.lerp(target_pos, follow_speed * delta)
		velocity = Vector2.ZERO
	else:
		# --- LOOSE BALL STATE ---
		if main_collision and main_collision.disabled:
			main_collision.set_deferred("disabled", false)

		if not is_on_floor():
			velocity.y += ProjectSettings.get_setting("physics/2d/default_gravity") * delta
		else:
			velocity.x = move_toward(velocity.x, 0.0, friction * delta)

		move_and_slide()


func _on_dribble_area_body_entered(body: Node2D) -> void:
	# Ignore the ball itself or ground collisions
	if body == self or body is StaticBody2D or body is TileMap:
		return

	# Player picks up the ball
	if body.is_in_group("player") and _owner_player == null:
		_owner_player = body

	# Defender touches the ball while held -> Lose condition!
	elif body.is_in_group("defenders") and _owner_player != null:
		_game_over()


func _game_over() -> void:
	GameManager.lose_round()
