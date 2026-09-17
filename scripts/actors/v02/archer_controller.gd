class_name ArcherController
extends V02EnemyController

const ARROW_SCENE := preload("res://scenes/combat/v02/arrow.tscn")

@export_category("v0.2 Ranged Behavior")
@export_range(32.0, 600.0, 8.0) var preferred_min_distance: float = 180.0
@export_range(32.0, 700.0, 8.0) var preferred_max_distance: float = 300.0
@export_range(0.1, 3.0, 0.05) var windup_duration: float = 0.65
@export_range(0.2, 5.0, 0.1) var attack_interval: float = 1.8
@export_range(40.0, 900.0, 10.0) var arrow_speed: float = 320.0

var _attack_cooldown := 0.0
var _winding_up := false
var _locked_direction := Vector2.RIGHT

@onready var _windup_line: Line2D = $WindupLine


func _ready() -> void:
	super._ready()
	_state_label.text = "弓手"
	_visual.modulate = Color(0.72, 0.64, 1.0, 1.0)


func _physics_process(delta: float) -> void:
	if not _alive or target_player == null:
		return
	if not update_detection():
		velocity = Vector2.ZERO
		return
	if _winding_up:
		velocity = Vector2.ZERO
		check_contact_damage()
		return

	_attack_cooldown = maxf(_attack_cooldown - delta, 0.0)
	var distance := global_position.distance_to(target_player.global_position)
	if distance < preferred_min_distance:
		_state_label.text = "撤退"
		var retreat_available := move_away_from_target(delta)
		if not retreat_available and _attack_cooldown <= 0.0:
			_state_label.text = "无路可退·射击"
			begin_windup()
	elif distance > preferred_max_distance:
		_state_label.text = "接近"
		var path_available := move_toward_target(delta, target_player.global_position)
		if not path_available and _attack_cooldown <= 0.0:
			_state_label.text = "无法接近·射击"
			begin_windup()
	else:
		velocity = Vector2.ZERO
		_state_label.text = "瞄准"
		if _attack_cooldown <= 0.0:
			begin_windup()
	check_contact_damage()


func begin_windup() -> void:
	if _winding_up or target_player == null or not _alive:
		return
	_winding_up = true
	_locked_direction = global_position.direction_to(target_player.global_position)
	if _locked_direction == Vector2.ZERO:
		_locked_direction = Vector2.RIGHT
	_windup_line.points = PackedVector2Array([Vector2.ZERO, _locked_direction * 520.0])
	_windup_line.visible = true
	_state_label.text = "射击"
	await get_tree().create_timer(windup_duration).timeout
	if not is_inside_tree() or not _alive or level_controller == null:
		return
	var arrow := ARROW_SCENE.instantiate()
	level_controller.call("spawn_arrow", arrow, global_position, _locked_direction, arrow_speed)
	_windup_line.visible = false
	_winding_up = false
	_attack_cooldown = attack_interval


func get_locked_direction() -> Vector2:
	return _locked_direction


func is_winding_up() -> bool:
	return _winding_up
