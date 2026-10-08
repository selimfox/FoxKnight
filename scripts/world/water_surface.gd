extends Node2D

## Visual-only reflections. The authored Water TileMap determines the mask;
## no water cells participate in collision, pathfinding or slash queries.
@export var mask_atlas: Texture2D = preload("res://assets/art/production/environment_20260930/water_mask_world2x.png")
@export var ripple_atlas: Texture2D = preload("res://assets/art/production/environment/courtyard_ripple.png")
@export var reflection_shader: Shader = preload("res://scripts/world/water_reflection.gdshader")
@export_range(0.2, 1.0, 0.01) var ripple_duration := 0.24
@export_range(8.0, 40.0, 1.0) var ripple_step_distance := 20.0

var _water: TileMapLayer
var _actors: Node2D
var _reflection_by_actor: Dictionary = {}
var _ripple_by_actor: Dictionary = {}
var _ripple_age_by_actor: Dictionary = {}
var _ripple_foot_by_actor: Dictionary = {}
var _was_in_water_by_actor: Dictionary = {}
var _shadow_factor_by_actor: Dictionary = {}
var _mask_texture: ImageTexture
var _mask_image: Image
var _last_signature := ""


func _ready() -> void:
	_water = get_node_or_null("../WaterSurface") as TileMapLayer
	_actors = get_node_or_null("../../Actors") as Node2D
	if _water == null or _actors == null:
		push_error("WaterSurface needs Arena/WaterSurface and Actors")
		return
	_rebuild_mask()


func _process(delta: float) -> void:
	if _water == null or _actors == null:
		return
	var signature := str(_water.get_used_cells())
	for cell: Vector2i in _water.get_used_cells():
		signature += str(_water.get_cell_source_id(cell)) + str(_water.get_cell_atlas_coords(cell))
	if signature != _last_signature:
		_rebuild_mask()
	for actor: Node in _actors.get_children():
		if actor is Node2D:
			_update_actor(actor, delta)
		elif actor.name == "Enemies":
			for enemy: Node in actor.get_children():
				_update_actor(enemy, delta)
	for actor: Node in _reflection_by_actor.keys():
		if not is_instance_valid(actor):
			(_reflection_by_actor[actor] as Sprite2D).queue_free()
			(_ripple_by_actor[actor] as Sprite2D).queue_free()
			_reflection_by_actor.erase(actor)
			_ripple_by_actor.erase(actor)
			_ripple_age_by_actor.erase(actor)
			_ripple_foot_by_actor.erase(actor)
			_was_in_water_by_actor.erase(actor)
			_shadow_factor_by_actor.erase(actor)


func _update_actor(actor: Node, delta: float = 0.0) -> void:
	if not actor.has_method("get_current_animation_frame_texture") or not actor.has_method("get_visual_foot_anchor_global"):
		return
	var reflection: Sprite2D = _reflection_by_actor.get(actor)
	if reflection == null:
		reflection = Sprite2D.new()
		reflection.name = "Reflection_" + actor.name
		reflection.centered = false
		reflection.flip_v = true
		reflection.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		var material := ShaderMaterial.new()
		material.shader = reflection_shader
		material.set_shader_parameter("water_mask", _mask_texture)
		material.set_shader_parameter("mask_size", Vector2(960.0, 540.0))
		reflection.material = material
		add_child(reflection)
		_reflection_by_actor[actor] = reflection
		var created_ripple := Sprite2D.new()
		created_ripple.name = "Ripple_" + actor.name
		created_ripple.texture = ripple_atlas
		created_ripple.hframes = 4
		created_ripple.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		created_ripple.modulate = Color(0.84, 0.96, 1.0, 0.72)
		add_child(created_ripple)
		_ripple_by_actor[actor] = created_ripple
	reflection.texture = actor.get_current_animation_frame_texture()
	var foot: Vector2 = actor.get_visual_foot_anchor_global()
	var visual: Sprite2D = actor.get_node_or_null("Visual/Sprite") as Sprite2D
	var anchor := -visual.position if visual != null else Vector2(24.0, 50.0)
	var frame_height := reflection.texture.get_height() if reflection.texture != null else 0
	# flip_v maps the authored foot to height-anchor.y. Align that pixel to the
	# live foot, including per-frame transparent canvas padding.
	reflection.position = to_local(foot) + Vector2(-anchor.x, anchor.y - float(frame_height))
	reflection.visible = _has_water_at(foot) and reflection.texture != null
	var factor: float = _shadow_factor_by_actor.get(actor, 1.0)
	factor = move_toward(factor, 0.45 if reflection.visible else 1.0, maxf(delta, 0.0) * 0.55 / 0.08)
	_shadow_factor_by_actor[actor] = factor
	var ground_shadow := actor.get_node_or_null("GroundShadow") as DynamicActorShadow
	if ground_shadow != null:
		ground_shadow.set_water_shadow_factor(factor)
	if actor.has_method("is_alive") and not actor.is_alive():
		reflection.visible = false
	var ripple: Sprite2D = _ripple_by_actor[actor]
	var was_in_water: bool = _was_in_water_by_actor.get(actor, false)
	var last_ripple_foot: Vector2 = _ripple_foot_by_actor.get(actor, foot)
	if reflection.visible and (not was_in_water or foot.distance_to(last_ripple_foot) >= ripple_step_distance):
		_ripple_age_by_actor[actor] = 0.0
		_ripple_foot_by_actor[actor] = foot
	elif _ripple_age_by_actor.has(actor):
		_ripple_age_by_actor[actor] = float(_ripple_age_by_actor[actor]) + delta
	var ripple_age: float = _ripple_age_by_actor.get(actor, ripple_duration)
	ripple.position = to_local(_ripple_foot_by_actor.get(actor, foot))
	ripple.frame = mini(3, int(4.0 * ripple_age / ripple_duration))
	ripple.modulate.a = 0.72 * (1.0 - clampf(ripple_age / ripple_duration, 0.0, 1.0))
	ripple.visible = reflection.visible and ripple_age < ripple_duration
	_was_in_water_by_actor[actor] = reflection.visible


func _has_water_at(foot: Vector2) -> bool:
	var cell := _water.local_to_map(_water.to_local(foot))
	if _water.get_cell_source_id(cell) != 1 or _mask_image == null:
		return false
	var atlas_cell := _water.get_cell_atlas_coords(cell)
	var cell_top_left := _water.map_to_local(cell) - Vector2(16.0, 16.0)
	var local_pixel := Vector2i(_water.to_local(foot) - cell_top_left)
	var pixel := atlas_cell * 32 + local_pixel
	return pixel.x >= 0 and pixel.y >= 0 and pixel.x < _mask_image.get_width() and pixel.y < _mask_image.get_height() and _mask_image.get_pixelv(pixel).a > 0.5


func _rebuild_mask() -> void:
	var image := Image.create(960, 540, false, Image.FORMAT_RGBA8)
	image.fill(Color.TRANSPARENT)
	_mask_image = mask_atlas.get_image()
	for cell: Vector2i in _water.get_used_cells():
		if _water.get_cell_source_id(cell) != 1:
			continue
		var atlas_cell := _water.get_cell_atlas_coords(cell)
		if atlas_cell.x < 0 or atlas_cell.y < 0:
			continue
		var cell_top_left := _water.map_to_local(cell) - Vector2(16.0, 16.0)
		image.blit_rect(_mask_image, Rect2i(atlas_cell * 32, Vector2i(32, 32)), Vector2i(cell_top_left))
	if _mask_texture == null:
		_mask_texture = ImageTexture.create_from_image(image)
	else:
		_mask_texture.update(image)
	for reflection: Sprite2D in _reflection_by_actor.values():
		(reflection.material as ShaderMaterial).set_shader_parameter("water_mask", _mask_texture)
	_last_signature = str(_water.get_used_cells())
	for cell: Vector2i in _water.get_used_cells():
		_last_signature += str(_water.get_cell_source_id(cell)) + str(_water.get_cell_atlas_coords(cell))


func get_reflection_for_actor(actor: Node) -> Sprite2D:
	return _reflection_by_actor.get(actor)
