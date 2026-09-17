class_name V02Arrow
extends Node2D

var direction := Vector2.RIGHT
var speed := 320.0
var level_controller: Node
var target_player: PlayerController
var active := true


func setup(level: Node, player: PlayerController, start: Vector2, travel_direction: Vector2, travel_speed: float) -> void:
	level_controller = level
	target_player = player
	global_position = start
	direction = travel_direction.normalized()
	speed = travel_speed
	rotation = direction.angle()


func _physics_process(delta: float) -> void:
	if not active:
		return
	global_position += direction * speed * delta
	if target_player != null and global_position.distance_to(target_player.global_position) <= 20.0:
		active = false
		level_controller.call("request_player_damage", self)
		queue_free()
	elif global_position.x < -80.0 or global_position.x > 1040.0 or global_position.y < -80.0 or global_position.y > 620.0:
		queue_free()
