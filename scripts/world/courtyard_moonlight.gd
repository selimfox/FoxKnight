extends Node2D

## Purely visual light motion. The TileMap remains the collision authority.
const MOON_WASH := preload("res://assets/art/production/environment/courtyard_moon_pool.png")
const FIRE_WASH := preload("res://assets/art/production/environment/courtyard_fire_pool.png")
const TORCH_FRAMES := preload("res://assets/art/production/environment_20260930/torch_world2x.png")


class TorchFlameLayer extends Node2D:
	var anchors: Array[Vector2] = []
	var atlas: Texture2D
	var elapsed := 0.0

	func _ready() -> void:
		texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

	func _process(delta: float) -> void:
		elapsed += delta
		queue_redraw()

	func _draw() -> void:
		for index in anchors.size():
			var frame := (int(elapsed * 8.0) + index) % 6
			draw_texture_rect_region(atlas,
				Rect2(anchors[index] + Vector2(-16.0, -38.0), Vector2(32.0, 48.0)),
				Rect2(float(frame * 32), 0.0, 32.0, 48.0))

@export_range(0.0, 0.25, 0.005) var moon_opacity := 0.20
@export_range(0.0, 0.25, 0.005) var fire_opacity := 0.18
@export_range(5.0, 30.0, 0.5) var moon_period := 17.0

var _fire_positions: Array[Vector2] = []
var _flame_layer: TorchFlameLayer
var _moon_center := Vector2(160.0, 144.0)
var _time := 0.0


func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var water := get_node_or_null("../WaterSurface") as TileMapLayer
	if water != null and not water.get_used_cells().is_empty():
		var center := Vector2.ZERO
		for cell: Vector2i in water.get_used_cells():
			center += water.map_to_local(cell)
		_moon_center = center / float(water.get_used_cells().size()) + Vector2(0.0, 24.0)
	var props := get_node_or_null("../Props") as TileMapLayer
	if props != null:
		for cell: Vector2i in props.get_used_cells():
			if props.get_cell_atlas_coords(cell).y == 0:
				_fire_positions.append(props.map_to_local(cell) + Vector2(0.0, 18.0))
	_flame_layer = TorchFlameLayer.new()
	_flame_layer.name = "TorchFlames"
	_flame_layer.z_index = 4
	_flame_layer.anchors = _fire_positions.duplicate()
	_flame_layer.atlas = TORCH_FRAMES
	get_parent().add_child.call_deferred(_flame_layer)


func _process(delta: float) -> void:
	_time += delta
	_sync_actor_shadows()
	queue_redraw()


func _sync_actor_shadows() -> void:
	var actors := get_node_or_null("../../Actors") as Node2D
	if actors == null:
		return
	for actor: Node in actors.get_children():
		if actor.name == "Enemies":
			for enemy: Node in actor.get_children():
				_sync_one_shadow(enemy)
		else:
			_sync_one_shadow(actor)


func _sync_one_shadow(actor: Node) -> void:
	var shadow := actor.get_node_or_null("GroundShadow") as DynamicActorShadow
	if shadow == null or not (actor is Node2D):
		return
	var actor_position := (actor as Node2D).global_position
	var moon_source := to_global(_moon_center + Vector2(-32.0, -110.0))
	var moon_distance := actor_position.distance_to(moon_source)
	var moon_weight := 1.0 / (1.0 + pow(moon_distance / 250.0, 2.0))
	var weighted_source := moon_source * moon_weight
	var total_weight := moon_weight
	for local_fire: Vector2 in _fire_positions:
		var fire_source := to_global(local_fire)
		var fire_distance := actor_position.distance_to(fire_source)
		var fire_weight := 0.55 / (1.0 + pow(fire_distance / 105.0, 2.0))
		weighted_source += fire_source * fire_weight
		total_weight += fire_weight
	var new_source := weighted_source / maxf(total_weight, 0.001)
	if shadow.main_light_world_position.distance_to(new_source) > 1.0:
		shadow.main_light_world_position = new_source
		shadow.queue_redraw()


func _draw() -> void:
	var cloud := sin(_time * TAU / moon_period)
	draw_texture_rect(MOON_WASH, Rect2(_moon_center - Vector2(128.0, 96.0), Vector2(256.0, 192.0)), false, Color(1.0, 1.0, 1.0, 0.82 + cloud * 0.10))
	_draw_soft_ellipse(_moon_center + Vector2(cloud * 5.0, cloud * 2.0), Vector2(130.0, 72.0), Color(0.57, 0.72, 1.0), moon_opacity * (0.78 + cloud * 0.22))
	for index in _fire_positions.size():
		var flicker := 0.84 + 0.11 * sin(_time * 9.1 + index * 2.4) + 0.05 * sin(_time * 16.7 + index)
		draw_texture_rect(FIRE_WASH, Rect2(_fire_positions[index] - Vector2(128.0, 96.0), Vector2(256.0, 192.0)), false, Color(1.0, 1.0, 1.0, 0.65 * flicker))
		_draw_soft_ellipse(_fire_positions[index], Vector2(55.0, 42.0), Color(1.0, 0.42, 0.11), fire_opacity * flicker)


func _draw_soft_ellipse(center: Vector2, radius: Vector2, tint: Color, strength: float) -> void:
	# Transparent rings avoid the old hard-edged, floating oval light patch.
	for ring in range(7, 0, -1):
		var fraction := float(ring) / 7.0
		var points := PackedVector2Array()
		for vertex in 32:
			var angle := TAU * float(vertex) / 32.0
			points.append(center + Vector2(cos(angle) * radius.x, sin(angle) * radius.y) * fraction)
		var color := tint
		color.a = strength * 0.13 * (1.0 - fraction * 0.72)
		draw_colored_polygon(points, color)
