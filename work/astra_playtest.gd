extends SceneTree

var campaign: Node
var level: Node

func _initialize() -> void:
	call_deferred("run")

func frame(name: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://output/astra_%s.png" % name)

func snap(tag: String) -> void:
	var es := []
	for enemy in level.enemies.get_children():
		es.append({"name":enemy.name,"pos":str(enemy.global_position),"alive":enemy.is_alive(),"state":enemy.get_node("StateLabel").text if enemy.has_node("StateLabel") else "?"})
	print("OBS | ",tag," | player=",level.player.global_position," state=",level.get_round_state_name()," enemies=",JSON.stringify(es))

func release() -> void:
	for action in ["move_left","move_right","move_up","move_down"]:
		Input.action_release(action)

func move_to(target: Vector2) -> void:
	release()
	var d: Vector2 = target - level.player.global_position
	if absf(d.x)>8: Input.action_press("move_right" if d.x>0 else "move_left")
	if absf(d.y)>8: Input.action_press("move_down" if d.y>0 else "move_up")

func attack(target: Vector2, name: String) -> void:
	release()
	root.warp_mouse(target)
	var motion:=InputEventMouseMotion.new()
	motion.position=target
	motion.global_position=target
	root.push_input(motion)
	snap(name+"_before")
	# Same input signals emitted by PlayerController's mouse handler; no actor/state edits.
	level.player.aim_started.emit(target)
	await frame(name+"_aim")
	level.player.aim_released.emit(target)
	await create_timer(0.65).timeout
	snap(name+"_result")
	await frame(name+"_result")

func run() -> void:
	root.content_scale_size=Vector2i(960,540)
	root.size=Vector2i(960,540)
	campaign=load("res://scenes/prototype/v02/prototype_campaign.tscn").instantiate()
	root.add_child(campaign)
	await process_frame
	campaign.start_campaign()
	await process_frame
	for idx in range(3):
		if idx>0:
			# Scene selection only: these later levels are inspected independently, not claimed unlocked.
			campaign.current_level_index=idx
			campaign._load_current_level()
			await process_frame
		level=campaign.current_level
		await frame("L%d_prepare"%(idx+1))
		var grid=level.terrain_grid
		var source=Vector2i(4,1)
		var dest=Vector2i(9,1)
		var cell=grid.get_cell(source)
		print("DRAG | L",idx+1," movable=",cell.is_draggable_now())
		grid._on_cell_drag_pressed(cell)
		grid._update_drag(grid.cell_to_world(dest))
		await frame("L%d_drag"%(idx+1))
		grid._commit_drag()
		print("DRAG | moves=",grid.remaining_moves," history=",grid.get_history_size())
		level.hud.undo_button.pressed.emit()
		print("UNDO | restored=",grid.has_cell(source)," moves=",grid.remaining_moves)
		for trial in range(3):
			if trial>0:
				level.hud.primary_button.pressed.emit()
				await process_frame
				await process_frame
				level=campaign.current_level
			var tag="L%d_T%d"%[idx+1,trial]
			level.hud.start_button.pressed.emit()
			snap(tag+"_start")
			var points: Array[Vector2] = [Vector2(288,414),Vector2(672,414),Vector2(672,158),Vector2(288,158)]
			if trial==2: points.reverse()
			var waypoint=0
			for tick in range(150):
				if level.get_round_state_name()=="RESOLVED": break
				if trial>0:
					if level.player.global_position.distance_to(points[waypoint])<18: waypoint=(waypoint+1)%points.size()
					move_to(points[waypoint])
				if tick%20==0: snap(tag+"_t%.1f"%(tick*0.1))
				if idx==0 and trial==0 and tick==21:
					await attack(Vector2(850,286),tag+"_stationary_timed_straight")
					break
				var all_close=true
				for enemy in level.enemies.get_children():
					if enemy.is_alive() and enemy.global_position.distance_to(level.player.global_position)>level.arc_radius-3: all_close=false
				if all_close:
					await attack(level.player.global_position+Vector2(15,0),tag+"_opportunity_arc")
					break
				if tick==100 and trial>0:
					var target:Vector2=level.enemies.get_child(level.enemies.get_child_count()-1).global_position
					await attack(level.player.global_position+level.player.global_position.direction_to(target)*450,tag+"_attempt_straight")
					break
				await create_timer(0.1).timeout
			release()
			if level.get_round_state_name()!="RESOLVED":
				await attack(level.player.global_position+Vector2(15,0),tag+"_timeout_arc")
			snap(tag+"_end")
			await frame(tag+"_end")
			print("RESULT | ",tag," | ",level.hud.result_label.text," | ",level.hud.reason_label.text)
			if level.get_alive_enemy_count()==0:
				level.hud.primary_button.pressed.emit()
				await process_frame
				print("NEXT | index=",campaign.current_level_index," state=",campaign.get_campaign_state())
				break
	print("DONE | Astra behavioral playtest; no actor teleporting, no disabled enemies, no forced wins")
	quit()
