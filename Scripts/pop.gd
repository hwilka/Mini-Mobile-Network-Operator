extends Node2D


var home_house: Node2D
var work_house: Node2D
var path_to_work
var home_pos: Vector2
var work_pos: Vector2

var map: Node2D = null

var mode = 0
var home_time: float = 1.0
var work_time: float = 1.0
var current_path_total = 0.0
var time_since = 0.0

var walk_speed = 4.0
var alive_time = 0.0

const CELL_WAIT_TIME = 5.0
const CELL_REQUEST_DIFF_MIN = 7.0
const CELL_REQUEST_DIFF_MAX = 12.0
var waiting_for_cell = false
var cell_answered = false
var queued_cell = null
var next_cell_request = 0.0
var next_cell_wait_time_end = 0.0
var next_cell_search = 0.0


# 3 - green
# 2 - yellow
# 1 - red
var _happiness = 3
var happiness: int:
	get:
		return _happiness
	set(value):
		if value == 1:
			$Sprite2D.texture = preload("res://img/PopRed.png")
		elif value == 2:
			$Sprite2D.texture = preload("res://img/PopYellow.png")
		elif value == 3:
			$Sprite2D.texture = preload("res://img/PopGreen.png")
		_happiness = value

func _ready():
	pass
	
	
func _process(delta):
	pass

func process_world(delta_world):
	alive_time += delta_world
	
	handle_movement(delta_world)
	handle_cell_signal(delta_world)
	
func handle_cell_signal(delta_world):
	var delta_cell = delta_world
	if not waiting_for_cell:
		next_cell_request -= delta_cell
		if next_cell_request <= 0:
			waiting_for_cell = true
			$Marker.visible = true
			cell_answered = false
			next_cell_wait_time_end = CELL_WAIT_TIME
			next_cell_request = 0.0
			next_cell_search = 0.0 # now
	if waiting_for_cell:
		if cell_answered:
			# success 
			#queued_cell.unqueue_request(self)
			queued_cell= null
			if happiness < 3:
				happiness += 1
			map.count_pops()
			map.update_pop_ui()
			next_cell_request = randf_range(CELL_REQUEST_DIFF_MIN, CELL_REQUEST_DIFF_MAX)
			waiting_for_cell = false
			$Marker.visible = false
		else:
			# not answered yet
			next_cell_wait_time_end -= delta_cell
			if next_cell_wait_time_end <= 0:
				# not successful
				if queued_cell != null:
					queued_cell.unqueue_request(self)
					queued_cell= null
					
				if happiness > 1:
					happiness -= 1
				map.count_pops()
				map.update_pop_ui()
				
				next_cell_request = randf_range(CELL_REQUEST_DIFF_MIN, CELL_REQUEST_DIFF_MAX)
				waiting_for_cell = false
				$Marker.visible = false
			else:
				# ask periodically for signal
				next_cell_search -= delta_cell
				if next_cell_search <= 0:
					next_cell_search += 1
					var cell_tower = map.get_cell_tower(position)
					if cell_tower != null:
						if queued_cell == cell_tower:
							# do nothing: already requested
							pass
						else:
							if queued_cell != null:
								# unqueue
								queued_cell.unqueue_request(self)
								queued_cell= null
							# place new request
							queued_cell = cell_tower
							var p = map.spawn_particle_signal(self, queued_cell)
							cell_tower.place_request(self, p)
						
			
			
func handle_movement(delta_world):
	while delta_world > 0:
		if mode == 0:
			# at home
			var time_left = home_time - time_since
			if time_left > delta_world:
				time_since += delta_world
				delta_world = 0
				position = home_pos# home_house.global_door_pos*map.GRID_SIZE
				break
			else:
				delta_world -= time_left
				mode = 1
				# recalculate route
				var new_route = map.get_route_custom_start(home_house.global_door_pos, work_house.global_door_pos, home_pos, work_pos)
				path_to_work = new_route
				current_path_total = 0.0
				position = home_pos # home_house.global_door_pos*map.GRID_SIZE
				continue
		elif mode == 1:
			# go to work
			current_path_total += walk_speed*delta_world
			var seg = floor(current_path_total)
			if seg < len(path_to_work) - 1:
				var p = current_path_total - seg
				position = (path_to_work[seg]*(1-p) + path_to_work[seg+1]*p)
				break
			else:
				# arrived at work
				mode = 2
				delta_world = (current_path_total - len(path_to_work) + 1)/walk_speed
				position = work_pos # work_house.global_door_pos*map.GRID_SIZE
				time_since = 0.0
				continue
		elif mode == 2:
			# at work
			var time_left = work_time - time_since
			if time_left > delta_world:
				time_since += delta_world
				delta_world = 0
				position = work_pos# work_house.global_door_pos*map.GRID_SIZE
				break
			else:
				delta_world -= time_left
				mode = 3
				current_path_total = 0.0
				position = work_pos# work_house.global_door_pos*map.GRID_SIZE
				continue
		elif mode == 3:
			# go to home
			current_path_total += walk_speed*delta_world
			var seg = floor(current_path_total)
			if seg < len(path_to_work) - 1:
				var p = current_path_total - seg
				position = (path_to_work[len(path_to_work)-seg-1]*(1-p) + path_to_work[len(path_to_work)-seg-2]*p)
				break
			else:
				# arrived at work
				mode = 0
				delta_world = (current_path_total - len(path_to_work) + 1)/walk_speed
				position = home_pos# home_house.global_door_pos*map.GRID_SIZE
				time_since = 0.0
				continue
	
	position += map.GRID_SIZE*(Vector2(0.23*sin(PI*alive_time), 0.16*cos(0.3*PI*alive_time)))
