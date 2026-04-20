extends Sprite2D


var pop = null
var cell_tower = null

# 0: travel to cell
# 1: wait at cell
# 2: travel to pop
var mode = 0
var time_alive = 0

const TRAVEL_SPEED = 5000


func process_world(delta_world):
	time_alive += delta_world
	if mode == 0:
		var dir: Vector2 = (cell_tower.position + Vector2(100,100)) - position
		if dir.length_squared() <= delta_world*delta_world*TRAVEL_SPEED*TRAVEL_SPEED:
			mode = 1
		else:
			position += delta_world*TRAVEL_SPEED*dir.normalized()
	elif mode == 2:
		var dir: Vector2 = pop.position - position
		if dir.length_squared() <= delta_world*delta_world*TRAVEL_SPEED*TRAVEL_SPEED:
			queue_free()
		else:
			position += delta_world*TRAVEL_SPEED*dir.normalized()
	
	if mode == 1:
		position = cell_tower.position + Vector2(100,100) + Vector2(150*cos(0.8*time_alive), 150*sin(0.8*time_alive))

func kill():
	queue_free()
