extends Area2D
 
func _physics_process(_delta: float) -> void:
	for body in get_overlapping_bodies():
		if body.is_in_group("ball"):
			GameManager.score_goal()
			return  # score_goal() already ignores repeat calls (round_active guard)
