class_name InfantryController
extends V02EnemyController


func _ready() -> void:
	super._ready()
	_state_label.text = "步兵"
	_visual.modulate = Color(1.0, 0.74, 0.56, 1.0)


func _physics_process(delta: float) -> void:
	if not _alive or target_player == null:
		return
	if not update_detection():
		velocity = Vector2.ZERO
		return
	_state_label.text = "追击"
	move_toward_target(delta, target_player.global_position)
	check_contact_damage()
