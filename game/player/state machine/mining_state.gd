extends PlayerState

signal stop_mining

enum SelectionMode { RAYCAST, NEAREST }

@export var selection_mode: SelectionMode= SelectionMode.NEAREST
@export var mining_range: int= 4

@onready var sound_interval: Timer = $"Sound Interval"

var mining_progress: float



func on_enter():
	mining_progress= 0
	player.block_breaker.show()
	player.on_start_mining(player.get_hand_object().type.mining_animation if player.has_hand_object() else "")


func on_exit():
	player.block_breaker.hide()
	player.on_stop_mining()


func on_physics_process(delta: float):
	match selection_mode:
		SelectionMode.RAYCAST:
			if player.ray_cast.is_colliding() and is_raycast_hitting_terrain():
				select_block()
			else:
				stop_mining.emit()
				return
				
		SelectionMode.NEAREST:
			var from: Vector2i= player.get_tile_pos()
			var mine_positions: Array[Vector2i]= []

			for x in range(-mining_range, mining_range + 1):
				for y in range(-mining_range, mining_range + 1):
					var tile:= from + Vector2i(x, y)
					if get_world().is_block_solid_at(tile):
						mine_positions.append(tile)
			
			if mine_positions.is_empty():
				stop_mining.emit()
				return
			
			var best_match_pos: Vector2i
			var best_rating: float= -INF
			
			for to in mine_positions:
				var rating: float= player.get_look_direction().dot(Vector2(to - from).normalized())
				rating*= 1.0 / (to - from).length()
				if rating > best_rating:
					best_match_pos= to
					best_rating= rating
			
			select_block_pos(best_match_pos)
			
	
	
	if not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		stop_mining.emit()
		return

	mining_progress+= player.mining_speed * delta
	var block: Block= get_world().get_block(selected_block_pos)
	if not block:
		stop_mining.emit()
		return

	var total_mining_effort= block.hardness
	if player.get_hand_object_type() != block.mining_tool:
		total_mining_effort*= 1 + block.other_tool_penalty
		
	if mining_progress >= total_mining_effort or Global.game.cheats.instant_mine:
		var do_drop: bool= block.other_tool_produces_drops or player.get_hand_object_type() == block.mining_tool
		get_world().break_block(selected_block_pos, do_drop)
		NodeDebugger.write(player, str("mined block ", selected_block_pos), 1)
		stop_mining.emit()
		player.break_block.emit(block)
		return
	else:
		player.block_breaker.position= get_world().map_to_local(selected_block_pos)
		var frames: int= player.block_breaker.sprite_frames.get_frame_count("default")
		player.block_breaker.frame= int(frames * mining_progress / total_mining_effort)

	if sound_interval.is_stopped():
		player.play_hand_item_sound(block.material)
		sound_interval.start()


func _on_player_ui_hotbar_slot_changed():
	if is_current_state():
		stop_mining.emit()


func on_selected_block_changed():
	stop_mining.emit()
