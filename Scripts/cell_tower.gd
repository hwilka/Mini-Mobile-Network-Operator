extends Node2D

@onready var cell = $Cell
@onready var radio1 = $Radio1
@onready var radio2 = $Radio2
@onready var radio3 = $Radio3

const COMPUTE_TIME = 1
var next_compute_time = COMPUTE_TIME

var _capacity = 1
var capacity: int:
	get:
		return _capacity
	set(value):
		_capacity = value
		if value == 1:
			$Cell.texture = preload("res://img/Cell.png")
		if value == 2:
			$Cell.texture = preload("res://img/Cell2.png")
		if value == 3:
			$Cell.texture = preload("res://img/Cell3.png")
			
var _range = 1
var range: int:
	get:
		return _range
	set(value):
		_range = value
		$Radius.scale = Vector2.ONE * get_range_radius()
		$RadiusUpgrade.scale = Vector2.ONE * get_range_upgrade_radius()
		$Radio2.visible = false
		$Radio3.visible = false
		if value == 2:
			$Radio2.visible = true
		if value == 3:
			$Radio3.visible = true

var queued_requests = []

func get_range_radius():
	if range == 1:
		return 20
	elif range == 2:
		return 30
	elif range == 3:
		return 40
		
func get_range_upgrade_radius():
	if range == 1:
		return 30
	elif range == 2:
		return 40
	elif range == 3:
		return 40
		
func init_radius_shape():
	var rad = $Radius
	var points = []
	for i in range(36):
		points.append(Vector2(cos(2*PI*i/36),sin(2*PI*i/36))*100)
	rad.polygon = PackedVector2Array(points)
	$RadiusUpgrade.polygon = rad.polygon

var radius_visible: bool:
	get:
		return $Radius.visible
	set(value):
		$Radius.visible = value
		
var radius_upgrade_visible: bool:
	get:
		return $RadiusUpgrade.visible
	set(value):
		$RadiusUpgrade.visible = value

var _radio = 3
var radio: int:
	get:
		return _radio
	set(value):
		if value == _radio:
			return
		radio1.visible = false
		radio2.visible = false
		radio3.visible = false
		if value >= 1:
			radio1.visible = true
		if value >= 2:
			radio2.visible = true
		if value >= 3:
			radio3.visible = true
		_radio = clamp(value, 0, 3)
		

func color_bg_red():
	$BGRect.visible = true
	$BGRect.color = Color.RED

func color_bg_green():
	$BGRect.visible = true
	$BGRect.color = Color.GREEN
	
func color_bg_hide():
	$BGRect.visible = false

#func _on_button_pressed():
#	print("clicked on cell tower")

func _ready():
	init_radius_shape()
	range = _range

func _on_button_pressed():
	print("clicked on cell tower")


func _on_button_button_down():
	cell.modulate = Color(0.7, 0.7, 0.7)


func _on_button_button_up():
	cell.modulate = Color(1,1,1)

func get_type() -> String:
	return "cell_tower"
	
	
func is_reachable(from_pos: Vector2) -> bool:
	var radius_world = get_range_radius()*100
	return (position + Vector2(100,100)).distance_squared_to(from_pos) <= radius_world*radius_world
	
func get_free_capacity() -> float:
	return len(queued_requests) / float(capacity)

func place_request(pop: Node2D, signal_particle: Node2D):
	queued_requests.append([pop, signal_particle])
	
func unqueue_request(pop: Node2D):
	for q in queued_requests:
		if q[0] == pop:
			q[1].kill()
			queued_requests.erase(q)
			break

func process_world(delta_world):
	next_compute_time -= delta_world
	while(next_compute_time <= 0):
		next_compute_time += COMPUTE_TIME
		
		# handle requests based on capacity
		for i in capacity:
			if queued_requests.is_empty():
				break
			var next = queued_requests.pop_front()
			next[0].cell_answered = true
			next[1].mode = 2
