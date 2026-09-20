extends Node
 
## Autoload this as "GameManager" (Project Settings > Autoload).
## Because autoloads live outside the reloaded scene tree, score keeps
## counting across restarts instead of resetting to 0 every time.
 
signal score_changed(new_score: int)
signal time_changed(seconds_left: float)
signal round_won
signal round_lost
 
@export var round_time: float = 25.0
 
var score: int = 0
var time_left: float = round_time
var round_active: bool = true
 
func _process(delta: float) -> void:
	if round_active:
		time_left = max(time_left - delta, 0.0)
		time_changed.emit(time_left)
		if time_left <= 0.0:
			lose_round()
 
 
func score_goal() -> void:
	if not round_active:
		return
	score += 1
	round_active = false
	score_changed.emit(score)
	round_won.emit()
	_restart_after(1.5)
 
 
func lose_round() -> void:
	if not round_active:
		return
	round_active = false
	round_lost.emit()
	_restart_after(1.2)
 
 
func _restart_after(delay: float) -> void:
	await get_tree().create_timer(delay).timeout
	time_left = round_time
	round_active = true
	get_tree().reload_current_scene()
