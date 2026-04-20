extends Node2D

var house_grid_pos: Vector2i = Vector2.ZERO
var local_door_pos: Vector2i = Vector2.ZERO
var is_home: bool


var global_door_pos: Vector2i:
	get:
		return 3*house_grid_pos + local_door_pos
	
func get_block_size():
	return Vector2i(1,1)

func init_door():
	$door.position = local_door_pos*100

func get_region()-> Rect2i:
	return Rect2i(house_grid_pos.x * 3, house_grid_pos.y * 3, 2, 2)

func get_type() -> String:
	return "house_small"
	
func get_house_grid_points():
	return [house_grid_pos]

func get_random_pos_inside() -> Vector2:
	return Vector2(house_grid_pos.x * 300 + 50 + randf_range(0,100), house_grid_pos.y * 300 + 50 + randf_range(0,100))
