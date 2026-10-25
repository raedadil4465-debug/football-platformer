extends CanvasLayer
@onready var score_label: Label = $ScoreLabel
@onready var time_label: Label = $TimeLabel
@onready var message_label: Label = $MessageLabel
 
func _ready() -> void:
	GameManager.score_changed.connect(_on_score_changed)
	GameManager.time_changed.connect(_on_time_changed)
	GameManager.round_won.connect(_on_round_won)
	GameManager.round_lost.connect(_on_round_lost)
	_on_score_changed(GameManager.score)
	_on_time_changed(GameManager.time_left)
	message_label.text = ""
 
 
func _on_score_changed(new_score: int) -> void:
	score_label.text = "Score: %d" % new_score
 
 
func _on_time_changed(seconds_left: float) -> void:
	time_label.text = "Time: %d" % int(ceil(seconds_left))
 
 
func _on_round_won() -> void:
	message_label.text = "GOAL!"
 
 
func _on_round_lost() -> void:
	message_label.text = "gg!"
