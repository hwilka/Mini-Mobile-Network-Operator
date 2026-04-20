extends Node2D

var house_grid_pos: Vector2i = Vector2.ZERO
var local_door_pos: Vector2i = Vector2.ZERO
var is_home: bool
var _tall = false
var tall: bool:
	get:
		return _tall
	set(value):
		if value:
			$Sprite.rotation_degrees = 90
			$Sprite.position.x = 200
		else:
			$Sprite.rotation_degrees = 0
			$Sprite.position.x = 0
		_tall = value
	

var global_door_pos: Vector2i:
	get:
		return 3*house_grid_pos + local_door_pos
	
func get_block_size():
	if tall:
		return Vector2i(1,2)
	else:
		return Vector2i(2,1)
		

func init_door():
	$door.position = local_door_pos*100

func get_region()-> Rect2i:
	if tall:
		return Rect2i(house_grid_pos.x * 3, house_grid_pos.y * 3, 2, 5)
	else:
		return Rect2i(house_grid_pos.x * 3, house_grid_pos.y * 3, 5, 2)

func get_type() -> String:
	return "house_medium"

func get_house_grid_points():
	if tall:
		return [house_grid_pos, house_grid_pos+Vector2i(0,1)]
	else:
		return [house_grid_pos, house_grid_pos+Vector2i(1,0)]

func get_random_pos_inside() -> Vector2:
	if tall:
		return Vector2(house_grid_pos.x * 300 + 50 + randf_range(0,100), house_grid_pos.y * 300 + 50 + randf_range(0,400))
	else:
		return Vector2(house_grid_pos.x * 300 + 50 + randf_range(0,400), house_grid_pos.y * 300 + 50 + randf_range(0,100))
