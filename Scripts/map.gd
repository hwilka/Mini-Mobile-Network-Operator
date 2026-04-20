extends Node2D

var current_speed = 1

var current_zoom_level = 1
const MAX_ZOOM_LEVEL = 2
const MIN_ZOOM_LEVEL = 0.05
var cam_is_dragged = false

var min_cam_pos = Vector2(-1000, -1000)
var max_cam_pos = Vector2(1000, 1000)

var grid_min = Vector2i(-250, -250)
var grid_max = Vector2i(250, 250)

var world_time: float = 0.0

var next_house_time = 0.0

const GRID_SIZE = 100
const HOUSE_GRID_SIZE = 3*GRID_SIZE

const CAN_DIE = true
var is_dead = false
var on_reward = false
var on_startup = true
var next_reward_time = TIME_FULL_DAY

var quit_is_extended = false

var tutorial_enabled = false

const CENTER_DISTANCE_MIN = 20
const CENTER_DISTANCE_MAX = 27

@onready var button_pause = $UI/TimeControl/ButtonPause
@onready var button_play = $UI/TimeControl/ButtonPlay
@onready var button_play2 = $UI/TimeControl/ButtonPlay2
@onready var cam = $Cam
@onready var houses = $Houses
@onready var pops = $Pops
@onready var cell_towers = $CellTowers
@onready var street_tiles = $StreetTiles
@onready var parc_tiles = $ParcTiles
@onready var clock = $UI/TimeControl/Clock
@onready var pop_green_label = $UI/PopOverview/PGreen/PGreenLabel
@onready var pop_yellow_label = $UI/PopOverview/PYellow/PYellowLabel
@onready var pop_red_label = $UI/PopOverview/PRed/PRedLabel
@onready var pop_total_label = $UI/PopOverview/PTotal/PTotalLabel
@onready var mouse_pos = $MousePositionWorld
@onready var cell_tower_placement = $CellTowerPlacement
@onready var particles_world = $ParticlesWorld

@onready var card_build_on_house = $UI/Cards/CardsTop/Card1/Card
@onready var card_build_on_ground = $UI/Cards/CardsTop/Card2/Card
@onready var card_upgrade_distance = $UI/Cards/CardsTop/Card3/Card
@onready var card_upgrade_capacity = $UI/Cards/CardsTop/Card4/Card

@onready var death_screen = $UI/DeathScreen
@onready var ds_bg = $UI/DeathScreen/BG
@onready var ds_pop = $UI/DeathScreen/Pop
@onready var ds_pop_count = $UI/DeathScreen/PopCount
@onready var ds_text1 = $UI/DeathScreen/Text1
@onready var ds_again = $UI/DeathScreen/PlayAgain
@onready var ds_menu = $UI/DeathScreen/MainMenu

@onready var reward_screen = $UI/RewardScreen
@onready var rs_text = $UI/RewardScreen/RewardText
@onready var rs_card1 = $UI/RewardScreen/Card1
@onready var rs_card2 = $UI/RewardScreen/Card2

var in_tutorial = false
var tutorial_step = 0
var tutorial_pop = null
var tutorial_cell = null
var tutorial_cells_enabled = false

const REWARD_CARDS = [[0,1], [0,2], [0,3], [1,1], [1,2], [1,3], [2,1], [2,2], [2,3], [3,1], [3,2]]
const REWARD_CHANCE = [0.13, 0.1, 0.02, 0.15, 0.12, 0.03, 0.1, 0.1, 0.05, 0.15, 0.1]

# helper for ui/game problems:
var mouse_block_card = false

var astar_street_builder: AStarGrid2D
var astar_navigation: AStarGrid2D

var homes = []
var works = []
var centers = []

var house_grid_array = []
var house_grid_array_width = 0
var house_grid_array_height = 0

var cell_grid_array = []
var cell_grid_array_width = 0
var cell_grid_array_height = 0

var mode_card = -1
var radius_shown = null
var cell_marked = null

var pops_green = 0
var pops_yellow = 0
var pops_red = 0
var pops_total: int:
	get:
		return pops_green + pops_yellow + pops_red

const MAX_POP_RED = 5

const BUILDER_ROAD = 1.0
const BUILDER_PREFERRED_ROAD = 3.0
const BUILDER_UNPREFERRED_ROAD = 4.0
const BUILDER_AVOID_ROAD = 100.0
const BUILDER_LARGE_ROAD_GRID_X = 4
const BUILDER_LARGE_ROAD_GRID_Y = 4

const TIME_FULL_DAY = 60.0
const HOUSE_SPAWN_TIME_MAX = 8.0
const HOUSE_SPAWN_TIME_MIN = 3.0
const HOUSE_SPAWN_TIME_Q = 100.0

const CENTER_ORDER = [0, 2, 1, 0, 1, 0, 2, 2, 0, 1]

func _ready():
	# Set inital speed to 1
	
	tutorial_enabled = Global.tutorial_enabled
	if tutorial_enabled:
		# deactivate tutorial in the future
		Global.tutorial_enabled = false
		in_tutorial = true
		
	if in_tutorial:
		current_speed = 0
		button_play.disabled = true
		button_pause.disabled = true
		button_play2.disabled = true
	else:
		current_speed = 1
		button_play.disabled = true
		button_pause.disabled = false
		button_play2.disabled = false
	
	
	cell_tower_placement.radius_visible = true
	setup_array()
	init_grids()
	
	init_sample_1()
	count_pops()
	update_pop_ui()
	prepare_startup()
	
	
func init_sample_1():
	new_house()
	new_house()
	
func end_start_camera():
	on_startup = false
	if tutorial_enabled:
		start_tutorial_1()
	
func prepare_startup():
	var ANIM_TIME = 2.3
	var goal_pos = pops.get_child(0).position
	var initial_cam_pos = goal_pos + Vector2(3000, 3000)
	cam.position = initial_cam_pos
	cam.zoom = Vector2(2, 2)
	cam.rotation_degrees = -20
	
	var pop_overview = $UI/PopOverview
	var pop_overview_goal = pop_overview.position
	pop_overview.position += Vector2(-500, 0)
	
	var time_control = $UI/TimeControl
	var time_control_goal = time_control.position
	time_control.position += Vector2(+500, 0)
	
	var card_control = $UI/Cards
	var card_control_goal = card_control.position
	card_control.position += Vector2(0, 600)
	
	var quit_control = $UI/Quit
	var quit_control_goal = quit_control.position
	quit_control.position += Vector2(-500,0)
	
	
	var tween = create_tween()
	tween.tween_property(cam, "position", goal_pos, ANIM_TIME)
	tween = create_tween()
	tween.tween_property(cam, "zoom", Vector2(0.6, 0.6), ANIM_TIME)
	tween = create_tween()
	tween.tween_property(cam, "rotation_degrees", 0, ANIM_TIME)
	tween.tween_callback(end_start_camera)
	
	tween = create_tween()
	tween.tween_property(pop_overview, "position", pop_overview_goal, 0.8)
	tween = create_tween()
	tween.tween_property(time_control, "position", time_control_goal, 0.8)
	tween = create_tween()
	tween.tween_property(quit_control, "position", quit_control_goal, 0.8)
	tween = create_tween()
	tween.tween_interval(0.6)
	tween.tween_property(card_control, "position", card_control_goal, 1.0)

func setup_array():
	house_grid_array = []
	cell_grid_array = []
	house_grid_array_width = grid_max.x - grid_min.x + 1
	house_grid_array_height = grid_max.y - grid_min.y + 1
	cell_grid_array_width = house_grid_array_width
	cell_grid_array_height = house_grid_array_height
	for ix in range(house_grid_array_width*house_grid_array_height):
		house_grid_array.append(null)
		cell_grid_array.append(null)

func house_grid_array_set(pos: Vector2i, value: Variant):
	if pos.x < grid_min.x or pos.x > grid_max.x or pos.y < grid_min.y or pos.y > grid_max.y:
		return
	var apos = house_grid_array_height*(pos.x - grid_min.x) + (pos.y - grid_min.y)
	house_grid_array[apos] = value
	
func house_grid_array_get(pos: Vector2i) -> Variant:
	if pos.x < grid_min.x or pos.x > grid_max.x or pos.y < grid_min.y or pos.y > grid_max.y:
		return null
	var apos = house_grid_array_height*(pos.x - grid_min.x) + (pos.y - grid_min.y)
	return house_grid_array[apos]

func cell_grid_array_set(pos: Vector2i, value: Variant):
	if pos.x < grid_min.x or pos.x > grid_max.x or pos.y < grid_min.y or pos.y > grid_max.y:
		return
	var apos = cell_grid_array_height*(pos.x - grid_min.x) + (pos.y - grid_min.y)
	cell_grid_array[apos] = value
	
func cell_grid_array_get(pos: Vector2i) -> Variant:
	if pos.x < grid_min.x or pos.x > grid_max.x or pos.y < grid_min.y or pos.y > grid_max.y:
		return null
	var apos = cell_grid_array_height*(pos.x - grid_min.x) + (pos.y - grid_min.y)
	return cell_grid_array[apos]
	
	

func init_grids():
	var grid_region = Rect2i(grid_min.x, grid_min.y, grid_max.x - grid_min.x + 1, grid_max.y - grid_min.y + 1)

	astar_street_builder = AStarGrid2D.new()
	astar_street_builder.region = grid_region
	astar_street_builder.cell_size = Vector2(GRID_SIZE, GRID_SIZE)
	astar_street_builder.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	astar_street_builder.default_compute_heuristic = AStarGrid2D.HEURISTIC_MANHATTAN
	astar_street_builder.default_estimate_heuristic = AStarGrid2D.HEURISTIC_MANHATTAN
	astar_street_builder.update()
	astar_street_builder.fill_weight_scale_region(grid_region, BUILDER_UNPREFERRED_ROAD) # makes roads more attractive
	
	# radically enforce "straight" lines by allowing streets only along houses:
	var minimal_street_pos = grid_min
	while not (minimal_street_pos.x % 3 == -1 or minimal_street_pos.x % 3 == 2):
		minimal_street_pos.x += 1
	while not (minimal_street_pos.y % 3 == -1 or minimal_street_pos.y % 3 == 2):
		minimal_street_pos.y += 1
	
	var ix = minimal_street_pos.x
	var cx = BUILDER_LARGE_ROAD_GRID_X
	while ix < grid_max.x:
		var iy = minimal_street_pos.y
		var cy = BUILDER_LARGE_ROAD_GRID_Y
		while iy < grid_max.y:
			astar_street_builder.set_point_weight_scale(Vector2i(ix+1,iy+1), BUILDER_AVOID_ROAD)
			astar_street_builder.set_point_weight_scale(Vector2i(ix+1,iy+2), BUILDER_AVOID_ROAD)
			astar_street_builder.set_point_weight_scale(Vector2i(ix+2,iy+1), BUILDER_AVOID_ROAD)
			astar_street_builder.set_point_weight_scale(Vector2i(ix+2,iy+2), BUILDER_AVOID_ROAD)
			if cy == BUILDER_LARGE_ROAD_GRID_Y:
				cy = 0
				astar_street_builder.set_point_weight_scale(Vector2i(ix+0,iy), BUILDER_PREFERRED_ROAD)
				astar_street_builder.set_point_weight_scale(Vector2i(ix+1,iy), BUILDER_PREFERRED_ROAD)
				astar_street_builder.set_point_weight_scale(Vector2i(ix+2,iy), BUILDER_PREFERRED_ROAD)
			cy += 1
			iy += 3
		if cx == BUILDER_LARGE_ROAD_GRID_X:
			cx = 0
			astar_street_builder.set_point_weight_scale(Vector2i(ix,iy+0), BUILDER_PREFERRED_ROAD)
			astar_street_builder.set_point_weight_scale(Vector2i(ix,iy+1), BUILDER_PREFERRED_ROAD)
			astar_street_builder.set_point_weight_scale(Vector2i(ix,iy+2), BUILDER_PREFERRED_ROAD)
		cx += 1
		ix += 3
	astar_street_builder.update()
	
	
	astar_navigation = AStarGrid2D.new()
	astar_navigation.region = grid_region
	astar_navigation.cell_size = Vector2(GRID_SIZE, GRID_SIZE)
	astar_navigation.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	astar_navigation.update()
	astar_navigation.fill_weight_scale_region(grid_region, 100) # makes paths without road VERY unattractive (vs solid)
	
	
func _unhandled_input(event):
	if on_startup or is_dead:
		return
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT:
			if event.pressed:
				cam_is_dragged = true
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			pass
			
func _input(event):
	if on_startup or is_dead:
		return
	if event is InputEventMouseMotion:
		if cam_is_dragged:
			cam.global_position -= event.relative / cam.zoom
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT:
			if cam_is_dragged and not event.pressed:
				cam_is_dragged = false
	
func get_reward():
	var dice = randf()
	var c = REWARD_CHANCE[0]
	for i in range(len(REWARD_CHANCE)):
		if dice <= c:
			return i
		c += REWARD_CHANCE[i+1]
	
func start_reward_screen():
	on_reward = true
	
	var reward_i1 = get_reward()
	var reward_i2 = get_reward()
	while reward_i2 == reward_i1:
		reward_i2 = get_reward()
		
	rs_card1.count = REWARD_CARDS[reward_i1][1]
	rs_card1.symbol_type = REWARD_CARDS[reward_i1][0]
	
	rs_card2.count = REWARD_CARDS[reward_i2][1]
	rs_card2.symbol_type = REWARD_CARDS[reward_i2][0]
	
	# TODO: choose reward
	
	reward_screen.visible = true
	reward_screen.modulate = Color(1,1,1,0)
	rs_text.modulate = Color(1,1,1,0)
	rs_card1.modulate = Color(1,1,1,0)
	rs_card2.modulate = Color(1,1,1,0)
	
	var tween = create_tween()
	tween.tween_property(reward_screen, "modulate", Color(1,1,1,1), 0.3)
	
	tween = create_tween()
	tween.tween_interval(0.3)
	tween.tween_property(rs_text, "modulate", Color(1,1,1,1), 0.7)
	
	tween = create_tween()
	tween.tween_interval(0.9)
	tween.tween_property(rs_card2, "modulate", Color(1,1,1,1), 0.8)
	
	tween = create_tween()
	tween.tween_interval(1.1)
	tween.tween_property(rs_card1, "modulate", Color(1,1,1,1), 0.8)
	
	
func hide_tutorial_1():
	$UI/Tutorial/Step1.visible = false
	
func end_tutorial_1():
	
	var tween = create_tween()
	tween.tween_property($UI/Tutorial/Step1, "modulate", Color(1,1,1,0), 0.5)
	tween.tween_callback(hide_tutorial_1)
	
	tween = create_tween()
	tween.tween_interval(0.5)
	tween.tween_callback(start_tutorial_2)
	
func start_tutorial_1():
	tutorial_step = 1
	$UI/Tutorial/Step1/Label.modulate = Color(1,1,1,0)
	$UI/Tutorial/Step1/Label2.modulate = Color(1,1,1,0)
	$UI/Tutorial/Step1/Label3.modulate = Color(1,1,1,0)
	$UI/Tutorial/Step1/Label4.modulate = Color(1,1,1,0)
	$UI/Tutorial/Step1.visible = true
	
	var tween =create_tween()
	tween.tween_property($UI/Tutorial/Step1/Label, "modulate", Color(1,1,1,1), 0.5)
	
	tween = create_tween()
	tween.tween_interval(4.0)
	tween.tween_property($UI/Tutorial/Step1/Label2, "modulate", Color(1,1,1,1), 0.5)
	
	tween = create_tween()
	tween.tween_interval(6.0)
	tween.tween_property($UI/Tutorial/Step1/Label3, "modulate", Color(1,1,1,1), 0.5)
	
	tween = create_tween()
	tween.tween_interval(7.0)
	tween.tween_property($UI/Tutorial/Step1/Label4, "modulate", Color(1,1,1,1), 0.5)
	tween.tween_interval(10.0)
	tween.tween_callback(end_tutorial_1)
	
	
func hide_tutorial_2():
	$UI/Tutorial/Step2.visible = false
	
func end_tutorial_2():
	var tween = create_tween()
	tween.tween_property($UI/Tutorial/Step2, "modulate", Color(1,1,1,0), 0.5)
	tween.tween_callback(hide_tutorial_2)
	
	tutorial_step = 3

func tutorial_2_enable_time():
	button_play.disabled = false
	
func start_tutorial_2():
	tutorial_step = 2
	$UI/Tutorial/Step2/Label.modulate = Color(1,1,1,0)
	$UI/Tutorial/Step2/Label2.modulate = Color(1,1,1,0)
	$UI/Tutorial/Step2/Label3.modulate = Color(1,1,1,0)
	$UI/Tutorial/Step2.visible = true
	
	var tween = create_tween()
	tween.tween_property($UI/Tutorial/Step2/Label, "modulate", Color(1,1,1,1), 0.5)
	tween.tween_interval(1.5)
	tween.tween_callback(tutorial_2_enable_time)
	
	tween = create_tween()
	tween.tween_interval(2.0)
	tween.tween_property($UI/Tutorial/Step2/Label2, "modulate", Color(1,1,1,1), 0.5)
	
	tween = create_tween()
	tween.tween_interval(2.0)
	tween.tween_property($UI/Tutorial/Step2/Label3, "modulate", Color(1,1,1,1), 0.5)
	
func hide_tutorial_4():
	$UI/Tutorial/Step4.visible = false
	
func end_tutorial_4():
	var tween = create_tween()
	tween.tween_property($UI/Tutorial/Step4, "modulate", Color(1,1,1,0), 0.5)
	tween.tween_callback(hide_tutorial_4)
	
	tween = create_tween()
	tween.tween_interval(0.5)
	tween.tween_callback(start_tutorial_5)
	
func start_tutorial_4():
	current_speed = 0
	button_pause.disabled = true
	button_play.disabled = false
	button_play2.disabled = false
	
	tutorial_step = 4
	$UI/Tutorial/Step4/Label.modulate = Color(1,1,1,0)
	$UI/Tutorial/Step4/Label2.modulate = Color(1,1,1,0)
	$UI/Tutorial/Step4/Label3.modulate = Color(1,1,1,0)
	$UI/Tutorial/Step4/Label4.modulate = Color(1,1,1,0)
	$UI/Tutorial/Step4.visible = true
	
	var tween = create_tween()
	tween.tween_interval(3.0)
	tween.tween_property($UI/Tutorial/Step4/Label, "modulate", Color(1,1,1,1), 0.5)
	
	tween = create_tween()
	tween.tween_interval(6.0)
	tween.tween_property($UI/Tutorial/Step4/Label2, "modulate", Color(1,1,1,1), 0.5)
	
	tween = create_tween()
	tween.tween_interval(9.0)
	tween.tween_property($UI/Tutorial/Step4/Label3, "modulate", Color(1,1,1,1), 0.5)
	
	tween = create_tween()
	tween.tween_interval(12.0)
	tween.tween_property($UI/Tutorial/Step4/Label4, "modulate", Color(1,1,1,1), 0.5)
	tween.tween_interval(5.0)
	tween.tween_callback(end_tutorial_4)
	
	tween = create_tween()
	tween.tween_property(cam, "position", tutorial_pop.position, 1.0)
	tween = create_tween()
	tween.tween_property(cam, "zoom", Vector2(2.0, 2.0), 1.0)
	
	
func hide_tutorial_5():
	$UI/Tutorial/Step5.visible = false
	
func end_tutorial_5():
	var tween = create_tween()
	tween.tween_property($UI/Tutorial/Step5, "modulate", Color(1,1,1,0), 0.5)
	tween.tween_callback(hide_tutorial_5)
	
	start_tutorial_6()
	
func tutorial_5_enable_cards():
	tutorial_cells_enabled = true
	
func start_tutorial_5():
	tutorial_step = 5
	$UI/Tutorial/Step5/Label.modulate = Color(1,1,1,0)
	$UI/Tutorial/Step5/Label1.modulate = Color(1,1,1,0)
	$UI/Tutorial/Step5/Label2.modulate = Color(1,1,1,0)
	$UI/Tutorial/Step5/Label3.modulate = Color(1,1,1,0)
	$UI/Tutorial/Step5/Label4.modulate = Color(1,1,1,0)
	$UI/Tutorial/Step5.visible = true
	
	var tween = create_tween()
	tween.tween_property($UI/Tutorial/Step5/Label, "modulate", Color(1,1,1,1), 0.5)
	
	tween = create_tween()
	tween.tween_interval(3.0)
	tween.tween_property($UI/Tutorial/Step5/Label1, "modulate", Color(1,1,1,1), 0.5)
	
	tween = create_tween()
	tween.tween_interval(6.0)
	tween.tween_property($UI/Tutorial/Step5/Label2, "modulate", Color(1,1,1,1), 0.5)
	
	tween = create_tween()
	tween.tween_interval(9.0)
	tween.tween_property($UI/Tutorial/Step5/Label3, "modulate", Color(1,1,1,1), 0.5)
	
	tween = create_tween()
	tween.tween_interval(12.0)
	tween.tween_property($UI/Tutorial/Step5/Label4, "modulate", Color(1,1,1,1), 0.5)
	tween.tween_callback(tutorial_5_enable_cards)
	
func hide_tutorial_6():
	$UI/Tutorial/Step6.visible = false
	
func end_tutorial_6():
	var tween = create_tween()
	tween.tween_property($UI/Tutorial/Step6, "modulate", Color(1,1,1,0), 0.5)
	tween.tween_callback(hide_tutorial_6)
	
	start_tutorial_7()
	
func start_tutorial_6():
	tutorial_step = 6
	$UI/Tutorial/Step6/Label.modulate = Color(1,1,1,0)
	$UI/Tutorial/Step6/Label1.modulate = Color(1,1,1,0)
	$UI/Tutorial/Step6/Label2.modulate = Color(1,1,1,0)
	$UI/Tutorial/Step6/Label3.modulate = Color(1,1,1,0)
	$UI/Tutorial/Step6/Label4.modulate = Color(1,1,1,0)
	$UI/Tutorial/Step6/Label5.modulate = Color(1,1,1,0)
	$UI/Tutorial/Step6.visible = true
	
	var tween = create_tween()
	tween.tween_interval(3.0)
	tween.tween_property($UI/Tutorial/Step6/Label, "modulate", Color(1,1,1,1), 0.5)
	
	tween = create_tween()
	tween.tween_interval(6.0)
	tween.tween_property($UI/Tutorial/Step6/Label1, "modulate", Color(1,1,1,1), 0.5)
	
	tween = create_tween()
	tween.tween_interval(10.0)
	tween.tween_property($UI/Tutorial/Step6/Label2, "modulate", Color(1,1,1,1), 0.5)
	
	tween = create_tween()
	tween.tween_interval(13.0)
	tween.tween_property($UI/Tutorial/Step6/Label3, "modulate", Color(1,1,1,1), 0.5)
	
	tween = create_tween()
	tween.tween_interval(18.0)
	tween.tween_property($UI/Tutorial/Step6/Label4, "modulate", Color(1,1,1,1), 0.5)
	
	tween = create_tween()
	tween.tween_interval(21.0)
	tween.tween_property($UI/Tutorial/Step6/Label5, "modulate", Color(1,1,1,1), 0.5)
	tween.tween_interval(6.0)
	tween.tween_callback(end_tutorial_6)
	
	tween = create_tween()
	tween.tween_property(cam, "position", tutorial_cell.position + Vector2(100, 100), 1.0)
	tween = create_tween()
	tween.tween_property(cam, "zoom", Vector2(0.5, 0.5), 1.0)
	
	
func hide_tutorial_7():
	$UI/Tutorial/Step7.visible = false
	$UI/Tutorial.visible = false
	
func end_tutorial_7():
	var tween = create_tween()
	tween.tween_property($UI/Tutorial/Step7, "modulate", Color(1,1,1,0), 0.5)
	tween.tween_callback(hide_tutorial_7)
	
	# end of tutorial
	in_tutorial = false
	tutorial_enabled = false
	
	
func start_tutorial_7():
	tutorial_step = 7
	$UI/Tutorial/Step7/Label.modulate = Color(1,1,1,0)
	$UI/Tutorial/Step7/Label1.modulate = Color(1,1,1,0)
	$UI/Tutorial/Step7/Label2.modulate = Color(1,1,1,0)
	$UI/Tutorial/Step7/Label3.modulate = Color(1,1,1,0)
	$UI/Tutorial/Step7.visible = true
	
	var tween = create_tween()
	tween.tween_interval(3.0)
	tween.tween_property($UI/Tutorial/Step7/Label, "modulate", Color(1,1,1,1), 0.5)
	
	tween = create_tween()
	tween.tween_interval(7.0)
	tween.tween_property($UI/Tutorial/Step7/Label1, "modulate", Color(1,1,1,1), 0.5)
	
	tween = create_tween()
	tween.tween_interval(11.0)
	tween.tween_property($UI/Tutorial/Step7/Label2, "modulate", Color(1,1,1,1), 0.5)
	
	tween = create_tween()
	tween.tween_interval(16.0)
	tween.tween_property($UI/Tutorial/Step7/Label3, "modulate", Color(1,1,1,1), 0.5)
	tween.tween_interval(8.0)
	tween.tween_callback(end_tutorial_7)
	
func end_reward_screen(choice: int):
	
	var count = 0
	var type = 0
	if choice == 1:
		count = rs_card1.count
		type = rs_card1.symbol_type
	else:
		count = rs_card2.count
		type = rs_card2.symbol_type
	
	if type == 0:
		card_build_on_house.count += count
	elif type == 1:
		card_build_on_ground.count += count
	elif type == 2:
		card_upgrade_distance.count += count
	else:
		card_upgrade_capacity.count += count
	
	var lambda = func make_invisible():
		print('lam')
		reward_screen.visible = false
		on_reward = false
		
	var tween = create_tween()
	tween.tween_property(reward_screen, "modulate", Color(1,1,1,0), 0.3)
	tween.tween_callback(lambda)
	
	
func start_death_sequence():
	ds_pop_count.text = str(pops_total)
	ds_pop_count.modulate = Color(1,1,1,0);
	ds_pop.modulate = Color(1,1,1,0);
	ds_text1.modulate = Color(1,1,1,0);
	ds_again.modulate = Color(1,1,1,0);
	ds_menu.modulate = Color(1,1,1,0);
	death_screen.visible = true
	
	var tween = create_tween()
	tween.tween_property(ds_bg, "color", Color(0.1,0.1,0.1,0.7), 2)
	
	tween = create_tween()
	tween.tween_interval(1.8)
	tween.tween_property(ds_text1, "modulate", Color(1,1,1,1), 2)
	
	tween = create_tween()
	tween.tween_interval(4)
	tween.tween_property(ds_pop, "modulate", Color(1,1,1,1), 2)
	
	tween = create_tween()
	tween.tween_interval(5.5)
	tween.tween_property(ds_pop_count, "modulate", Color(1,1,1,1), 1.3)
	
	tween = create_tween()
	tween.tween_interval(6.0)
	tween.tween_property(ds_again, "modulate", Color(1,1,1,1), 1.0)
	
	tween = create_tween()
	tween.tween_interval(6.0)
	tween.tween_property(ds_menu, "modulate", Color(1,1,1,1), 1.0)
	
	tween = create_tween()
	tween.tween_property(cam, "zoom", Vector2.ONE * MIN_ZOOM_LEVEL, 6.0)
	
	tween = create_tween()
	tween.tween_property(cam, "position", Vector2.ZERO, 6.0)
	
	tween = create_tween()
	tween.tween_property(cam, "rotation_degrees", 60, 6.0)
	
func process_death_screen(delta):
	
	pass

func _process(delta):
	
	if is_dead:
		process_death_screen(delta)
		return
		
	if on_reward:
		return
		
	if on_startup:
		return
	
	# handle inputs
	handle_input()
	
	if current_speed > 0:
		var delta_world = delta * current_speed
		world_time += delta_world
		process_world(delta_world)
	
	var grid_pos = get_mouse_grid_pos()
	var house_pos = get_mouse_house_grid_pos()
	
	if radius_shown != null:
		radius_shown.radius_visible = false
		radius_shown.radius_upgrade_visible = false
		radius_shown = null
	if cell_marked != null:
		cell_marked.color_bg_hide()
		cell_marked = null
		
	if mode_card != -1:
		if mode_card == 0:
			cell_tower_placement.position = house_pos * HOUSE_GRID_SIZE
			if house_grid_array_get(house_pos) != null and cell_grid_array_get(house_pos) == null:
				cell_tower_placement.color_bg_green()
				if Input.is_action_just_released("mouse_left") and not mouse_block_card:
					spawn_cell_tower(house_pos)
					card_build_on_house.count -= 1
					unselect_card()
			else:
				cell_tower_placement.color_bg_red()
			
		elif mode_card == 1:
			cell_tower_placement.position = house_pos * HOUSE_GRID_SIZE
			if house_grid_array_get(house_pos) == null and cell_grid_array_get(house_pos) == null:
				cell_tower_placement.color_bg_green()
				if Input.is_action_just_released("mouse_left") and not mouse_block_card:
					spawn_cell_tower(house_pos)
					card_build_on_ground.count -= 1
					unselect_card()
			else:
				cell_tower_placement.color_bg_red()
				
		elif mode_card == 2:
			var possible_cell = cell_grid_array_get(house_pos)
			if possible_cell != null:
				cell_marked = possible_cell
				radius_shown = possible_cell
				if possible_cell.range < 3:
					possible_cell.color_bg_green()
					possible_cell.radius_upgrade_visible = true
					possible_cell.radius_visible = true
					if Input.is_action_just_released("mouse_left") and not mouse_block_card:
						upgrade_cell_range(possible_cell)
						card_upgrade_distance.count -= 1
						unselect_card()
				else:
					possible_cell.color_bg_red()
					
		elif mode_card == 3:
			var possible_cell = cell_grid_array_get(house_pos)
			if possible_cell != null:
				cell_marked = possible_cell
				radius_shown = possible_cell
				possible_cell.radius_visible = true
				if possible_cell.capacity < 3:
					possible_cell.color_bg_green()
					if Input.is_action_just_released("mouse_left") and not mouse_block_card:
						upgrade_cell_capacity(possible_cell)
						card_upgrade_capacity.count -= 1
						unselect_card()
				else:
					possible_cell.color_bg_red()
	else:
		var hovered_tower = cell_grid_array_get(house_pos)
		if hovered_tower != null:
			hovered_tower.radius_visible = true
			radius_shown = hovered_tower
	mouse_block_card = false
	
func process_world(delta_world):
	next_house_time += delta_world
	
	for p in pops.get_children():
		p.process_world(delta_world)
	for c in cell_towers.get_children():
		c.process_world(delta_world)
		
	# update time
	var time_of_day = fmod(world_time, TIME_FULL_DAY)
	clock.arm_rotation_degrees = 360*time_of_day / TIME_FULL_DAY
	
	for p in particles_world.get_children():
		p.process_world(delta_world)
	
	
	var current_house_spawn_time = HOUSE_SPAWN_TIME_MAX - min(houses.get_child_count(), HOUSE_SPAWN_TIME_Q) / HOUSE_SPAWN_TIME_Q * (HOUSE_SPAWN_TIME_MAX - HOUSE_SPAWN_TIME_MIN)
	while (next_house_time >= current_house_spawn_time):
		next_house_time -= current_house_spawn_time
		new_house()
		
		count_pops()
		update_pop_ui()
		
	if world_time > next_reward_time:
		next_reward_time += TIME_FULL_DAY
		start_reward_screen()
		
	if tutorial_enabled and tutorial_step == 3:
		if tutorial_pop.waiting_for_cell:
			start_tutorial_4()
	
func new_center():
	var num_of_houses = houses.get_child_count()
	
	var r_max = num_of_houses/1.4 + 15
		
	if len(centers) == 0:
		var new_center = CityCenter.new()
		new_center.center = Vector2i(0,0)
		new_center.city_type = CENTER_ORDER[len(centers)]
		centers.append(new_center)
		return true
	else:
		for i in range(1000):
			var r = randf_range(max(0, r_max - 10), r_max)
			var w = randf_range(0, 2*PI)
			var new_center_pos = Vector2i(round(r*cos(w)), round(r*sin(w)))
			# check for distance to other centers
			var distance_large_enough = true
			var close_to_any_center = false
			for c in centers:
				var dist = abs(c.center.x - new_center_pos.x) + abs(c.center.y - new_center_pos.y)
				if dist < CENTER_DISTANCE_MIN*(1.0 + num_of_houses/100):
					distance_large_enough = false
					break
				if dist < CENTER_DISTANCE_MAX*(1.0 + num_of_houses/100):
					close_to_any_center = true
			if not (close_to_any_center or len(centers) == 0):
				continue
				
			if distance_large_enough:
				# create new center
				var new_center = CityCenter.new()
				new_center.center = new_center_pos
				if len(centers) <  len(CENTER_ORDER):
					new_center.city_type = CENTER_ORDER[len(centers)]
				else:
					new_center.city_type = randi_range(0,2)
					
				spawn_parc(Rect2i(new_center_pos.x*3 - randi_range(0,7), new_center_pos.y*3 - randi_range(0,7), randi_range(4,15), randi_range(4,15)))
				centers.append(new_center)
				return true
	return false
	
func new_house():
	# decide for new city center:
	var num_of_houses = houses.get_child_count()
	var goal_centers = 1 + sqrt(num_of_houses-2)/1.6

	var center_to_spawn = -1
	# special rule for beginning:
	if num_of_houses < 2:
		assert(new_center(), "Could not spawn initial city center")
		center_to_spawn = len(centers) - 1
	else:
		if goal_centers > len(centers):
			# create new center
			if new_center():
				center_to_spawn = len(centers) - 1
	
	
	if center_to_spawn == -1:
		# TODO: more advanced formula
		center_to_spawn = randi_range(0, len(centers)-1)
		
		
	var center = centers[center_to_spawn]
	# get recommendend distance from center = 
	var house_prob = [0.7, 1.0, 1.0]
	if center.city_type == 1:
		house_prob = [0.1, 0.65, 1.0]
	elif center.city_type == 2:
		house_prob = [0.4, 0.9, 1.0]
			
	# house size
	var s = 1
	# door pos
	var rd = Vector2i(randi_range(0,1), randi_range(0,1))
	var hp = randf()
	if num_of_houses == 0:
		hp = 0
	elif num_of_houses == 1:
		hp = 0.9
	if hp <= house_prob[0]:
		# small house
		pass
	elif hp <= house_prob[1]:
		# medium house
		if randf() < 0.5:
			s = 2
			rd = Vector2i(randi_range(0,4), randi_range(0,1))
		else:
			s = 3
			rd = Vector2i(randi_range(0,1), randi_range(0,4))
	else:
		# large house
		s = 4
		var entry_side = randi_range(0,3)
		if entry_side == 0:
			rd = Vector2i(0, randi_range(1,4))
		elif entry_side == 1:
			rd = Vector2i(4, randi_range(0,3))
		elif entry_side == 2:
			rd = Vector2i(randi_range(1,4), 4)
		else :
			rd = Vector2i(randi_range(0,3), 0)
				
	# try position house
	for i in range(1000):
		var r = round(3 + sqrt(len(center.houses)))
		var rp = Vector2i(randi_range(-r, r), randi_range(-r,r)) + center.center
			
		var nh = null
		var is_home = true
		if num_of_houses == 0:
			is_home = true
		elif num_of_houses == 1:
			is_home = false
		else:
			if s == 1:
				is_home = randf() < 0.8
			elif s == 2 or s == 3:
				is_home = randf() < 0.5
			else:
				is_home = false
		nh = spawn_house(s, rp, rd, is_home)
		center.houses.append(nh)
		if num_of_houses == 0:
			break
		if not (nh == null):
			if nh.is_home:
				spawn_pop(nh, null)
			else:
				spawn_pop(null, nh)
			break

func spawn_parc(region: Rect2i):
	var new_pos = []
	for ix in range(region.position.x, region.end.x+1):
		for iy in range(region.position.y, region.end.y+1):
			new_pos.append(Vector2i(ix,iy))
	
	parc_tiles.set_cells_terrain_connect(new_pos, 0, 1)
	pass
	
func handle_input():
	if Input.is_action_just_pressed("zoom_in"):
		# TODO zoom pos
		control_zoom_in()
	elif Input.is_action_just_pressed("zoom_out"):
		# TODO zoom pos
		control_zoom_out()
	
	if Input.is_action_just_pressed("pause"):
		_on_button_pause_pressed()
	
func control_zoom_in():
	var new_zoom_level = clamp(current_zoom_level*1.5, MIN_ZOOM_LEVEL, MAX_ZOOM_LEVEL)
	if current_zoom_level != new_zoom_level:
		current_zoom_level = new_zoom_level
		var tween = create_tween()
		tween.tween_property(cam, "zoom", Vector2.ONE * current_zoom_level, 0.2)
	
func control_zoom_out():
	var new_zoom_level = clamp(current_zoom_level/1.5, MIN_ZOOM_LEVEL, MAX_ZOOM_LEVEL)
	if current_zoom_level != new_zoom_level:
		current_zoom_level = new_zoom_level
		var tween = create_tween()
		tween.tween_property(cam, "zoom", Vector2.ONE * current_zoom_level, 0.2)


func spawn_pop(home: Node2D, work: Node2D):
	
	if home == null:
		var i = randi_range(0, len(homes)-1)
		home = homes[i]
	
	if work == null:
		var i = randi_range(0, len(works)-1)
		work = works[i]
	
	var pop = preload("res://Scenes/Pop.tscn").instantiate()
	pop.home_house = home
	pop.work_house = work
	pop.home_pos = home.get_random_pos_inside()
	pop.work_pos = work.get_random_pos_inside()
	var route = get_route_custom_start(home.global_door_pos, work.global_door_pos, pop.home_pos, pop.work_pos)
	if len(route) == 2:
		assert(false, "Route to work can not be found")
	pop.path_to_work = route
	pop.next_cell_request = randf_range(pop.CELL_REQUEST_DIFF_MIN, pop.CELL_REQUEST_DIFF_MAX)
	
	pops.add_child(pop)
	pop.position = pop.home_pos
	pop.map = self
	pop.home_time = randf_range(10, 15)
	pop.work_time = randf_range(10, 15)
	pop.time_since = randf_range(0.7,0.95)*pop.home_time
	pop.walk_speed = randf_range(3.0, 5.0)
	if tutorial_enabled:
		tutorial_pop = pop
		pop.home_time = randf_range(10, 15)
		pop.time_since = pop.home_time - 1
		pop.next_cell_request = 3
	
	return pop
	
func spawn_cell_tower(pos: Vector2i):
	var cell_tower = preload("res://Scenes/CellTower.tscn").instantiate()
	cell_tower.position = pos * HOUSE_GRID_SIZE
	cell_towers.add_child(cell_tower)
	cell_grid_array_set(pos, cell_tower)
	
	if in_tutorial and tutorial_step == 5:
		tutorial_cell = cell_tower
		end_tutorial_5()
	
func upgrade_cell_range(cell_tower: Node2D):
	if cell_tower.range < 3:
		cell_tower.range += 1
	
func upgrade_cell_capacity(cell_tower: Node2D):
	if cell_tower.capacity < 3:
		cell_tower.capacity += 1

func spawn_house(size: int, house_grid_pos: Vector2i, local_door_pos: Vector2i, is_home: bool):
	# TODO: Check house size
	var new_house: Node2D = null
	if size == 1:
		new_house = preload("res://Scenes/HouseSmall.tscn").instantiate()
	elif size == 2:
		new_house = preload("res://Scenes/HouseMedium.tscn").instantiate()
		new_house.tall = false
	elif size == 3:
		new_house = preload("res://Scenes/HouseMedium.tscn").instantiate()
		new_house.tall = true
	elif size == 4:
		new_house = preload("res://Scenes/HouseLarge.tscn").instantiate()
	else:
		assert(false, "House can only be of size 1")
	
	new_house.position = house_grid_pos*HOUSE_GRID_SIZE
	new_house.is_home = is_home
	new_house.house_grid_pos = house_grid_pos
	new_house.local_door_pos = local_door_pos
	new_house.init_door()
	
	# TODO: check overlap with other houses, streets, AND cell towers
	var found_collision = false
	var house_region: Rect2i = new_house.get_region()
	for ix in range(house_region.size.x):
		for iy in range(house_region.size.y):
			var tp = house_region.position + Vector2i(ix, iy)
			if astar_street_builder.is_point_solid(tp) or astar_navigation.get_point_weight_scale(tp) <= 1.0:
				found_collision = true
				break
		if found_collision:
			break
	
	if found_collision:
		new_house.queue_free()
		return null
		
	if is_home:
		homes.append(new_house)
	else:
		works.append(new_house)
	var house_grid_points = new_house.get_house_grid_points()
	for p in house_grid_points:
		house_grid_array_set(p, new_house)
		spawn_build_particle(Vector2(p)*300 + Vector2(50, 50), 0)
		
	
	houses.add_child(new_house)
	var door_pos: Vector2i = new_house.global_door_pos
	astar_street_builder.fill_solid_region(house_region, true)
	astar_street_builder.set_point_solid(door_pos, false)
	astar_street_builder.set_point_weight_scale(door_pos, BUILDER_AVOID_ROAD) # don't plan through doors...
	astar_street_builder.update()
	
	astar_navigation.set_point_weight_scale(door_pos, 10.0) # don't plan through doors...
	
	# set street point
	street_tiles.set_cells_terrain_connect([door_pos], 0, 0)
	
	# spawn parc
	if randf() < 0.25:
		spawn_parc(Rect2i(house_grid_pos.x*3 - randi_range(0,3), house_grid_pos.y*3 - randi_range(0,3), randi_range(2,7), randi_range(2,7)))
	
	if houses.get_child_count() > 1:
		# connect to random houses
		var n_other = min(houses.get_child_count()-1, 3)
		for ii in range(n_other):
			var h1i = randi_range(0, houses.get_child_count()-2)
			var h1 = houses.get_child(h1i)
			var d1 = h1.global_door_pos
			var new_street = astar_street_builder.get_id_path(d1, door_pos)
			street_tiles.set_cells_terrain_connect(new_street, 0, 0)
			# set street network
			for k in range(1, len(new_street)-1):
				astar_navigation.set_point_weight_scale(new_street[k], 1.0)
				if astar_street_builder.get_point_weight_scale(new_street[k]) != BUILDER_ROAD:
					spawn_build_particle( Vector2(new_street[k])*100 + Vector2(50, 50), k*0.003)
				astar_street_builder.set_point_weight_scale(new_street[k], BUILDER_ROAD)
		
	return new_house

func count_pops():
	if is_dead:
		return
	pops_green = 0
	pops_yellow = 0
	pops_red = 0
	for p in pops.get_children():
		if p.happiness == 3:
			pops_green += 1
		elif p.happiness == 2:
			pops_yellow += 1
		elif p.happiness == 1:
			pops_red += 1
	
	if pops_red >= MAX_POP_RED:
		if CAN_DIE:
			is_dead = true
			start_death_sequence()
			
func update_pop_ui():
	pop_total_label.text = str(pops_total)
	pop_green_label.text = str(pops_green)
	pop_yellow_label.text = str(pops_yellow)
	pop_red_label.text = str(pops_red) + " / " + str(MAX_POP_RED)

func get_route(from: Vector2i, to: Vector2i):
	return astar_navigation.get_id_path(from, to)
	
func get_route_custom_start(from: Vector2i, to: Vector2i, start: Vector2, end: Vector2):
	var route1 = get_route(from, to)
	var route2 = [start]
	for pi in route1:
		route2.append(Vector2(pi)*GRID_SIZE)
	route2.append(end)
	return route2

func _on_button_pause_pressed():
	if not (current_speed == 0):
		current_speed = 0
		button_pause.disabled = true
		button_play.disabled = false
		button_play2.disabled = false


func _on_button_play_pressed():
	if tutorial_enabled and tutorial_step == 2:
			current_speed = 1
			button_pause.disabled = false
			button_play.disabled = true
			button_play2.disabled = false
			end_tutorial_2()
	else:
		if not (current_speed == 1):
			current_speed = 1
			button_pause.disabled = false
			button_play.disabled = true
			button_play2.disabled = false


func _on_button_play_2_pressed():
	if not (current_speed == 3):
		current_speed = 3
		button_pause.disabled = false
		button_play.disabled = false
		button_play2.disabled = true


func unselect_card():
	if mode_card == 0:
		var tween = create_tween()
		tween.tween_property(card_build_on_house, "position", Vector2(0, 0), 0.1)
	elif mode_card == 1:
		var tween = create_tween()
		tween.tween_property(card_build_on_ground, "position", Vector2(0, 0), 0.1)
	elif mode_card == 2:
		var tween = create_tween()
		tween.tween_property(card_upgrade_distance, "position", Vector2(0, 0), 0.1)
	elif mode_card == 3:
		var tween = create_tween()
		tween.tween_property(card_upgrade_capacity, "position", Vector2(0, 0), 0.1)
	mode_card = -1
	cell_tower_placement.visible = false
	

func select_card(card: int):
	if card == 0:
		if card_build_on_house.count > 0:
			mode_card = card
			cell_tower_placement.visible = true
			var tween = create_tween()
			tween.tween_property(card_build_on_house, "position", Vector2(0, -40), 0.1)
	elif card == 1:
		if card_build_on_ground.count > 0:
			cell_tower_placement.visible = true
			mode_card = card
			var tween = create_tween()
			tween.tween_property(card_build_on_ground, "position", Vector2(0, -40), 0.1)
	elif card == 2:
		if card_upgrade_distance.count > 0:
			mode_card = card
			var tween = create_tween()
			tween.tween_property(card_upgrade_distance, "position", Vector2(0, -40), 0.1)
	elif card == 3:
		if card_upgrade_capacity.count > 0:
			mode_card = card
			var tween = create_tween()
			tween.tween_property(card_upgrade_capacity, "position", Vector2(0, -40), 0.1)
	else:
		return
		

func _on_card_build_on_house_pressed():
	if in_tutorial:
		if not tutorial_cells_enabled:
			return
	
	mouse_block_card = true
	var old_card_mode = mode_card
	unselect_card()
	if old_card_mode != 0:
		select_card(0)
	
func _on_card_build_on_ground_pressed():
	if in_tutorial:
		if not tutorial_cells_enabled:
			return
		
	mouse_block_card = true
	var old_card_mode = mode_card
	unselect_card()
	if old_card_mode != 1:
		select_card(1)

func _on_card_upgrade_distance_pressed():
	if in_tutorial:
		if tutorial_step < 6:
			return
		
	mouse_block_card = true
	var old_card_mode = mode_card
	unselect_card()
	if old_card_mode != 2:
		select_card(2)

func _on_card_upgrade_capacity_pressed():
	if in_tutorial:
		if tutorial_step < 6:
			return
		
	mouse_block_card = true
	var old_card_mode = mode_card
	unselect_card()
	if old_card_mode != 3:
		select_card(3)
	
	
func get_mouse_pos_world() -> Vector2:
	mouse_pos.global_position = get_global_mouse_position()
	return mouse_pos.position
	
func get_mouse_grid_pos() -> Vector2i:
	var world_pos = get_mouse_pos_world()
	return Vector2i(floor(world_pos.x / GRID_SIZE), floor(world_pos.y / GRID_SIZE))
	
func get_mouse_house_grid_pos() -> Vector2i:
	var world_pos = get_mouse_pos_world()
	return Vector2i(round((world_pos.x) / HOUSE_GRID_SIZE - 0.33), round((world_pos.y) / HOUSE_GRID_SIZE - 0.33))
	
func get_cell_tower(from_pos: Vector2) -> Variant:
	var first_hit = null
	var first_cap = -1
	for c in cell_towers.get_children():
		if c.is_reachable(from_pos):
			if first_hit == null:
				first_hit = c
				first_cap = c.get_free_capacity()
				if first_cap <= 1.0:
					return first_hit
			else:
				var other_cap = c.get_free_capacity()
				if other_cap < first_cap:
					first_cap = other_cap
					first_hit = c
	return first_hit

func spawn_particle_signal(pop, cell):
	var new_particle = preload("res://Scenes/SignalParticle.tscn").instantiate()
	new_particle.pop = pop
	new_particle.cell_tower = cell 
	new_particle.position = pop.position + Vector2(0, -60)
	particles_world.add_child(new_particle)
	return new_particle 


func to_main_callback():
	get_tree().change_scene_to_file("res://Scenes/MainMenu.tscn")

func _on_main_menu_pressed():
	var cover = $UI/Cover
	cover.modulate = Color(1,1,1,0)
	cover.visible = true
	
	var tween = create_tween()
	tween.tween_property(cover, "modulate", Color(1,1,1,1), 1.0)
	
	tween = create_tween()
	tween.tween_property(cam, "position", cam.position + Vector2(10000, 0), 1.0)
	
	tween = create_tween()
	tween.tween_interval(1.0)
	tween.tween_callback(to_main_callback)


func to_map_callback():
	get_tree().change_scene_to_file("res://Scenes/Map.tscn")
	
func _on_play_again_pressed():
	
	var cover = $UI/Cover
	cover.modulate = Color(1,1,1,0)
	cover.visible = true
	
	var tween = create_tween()
	tween.tween_property(cover, "modulate", Color(1,1,1,1), 1.0)
	
	tween = create_tween()
	tween.tween_property(cam, "position", cam.position + Vector2(10000, -10000), 1.0)
	
	tween = create_tween()
	tween.tween_interval(1.0)
	tween.tween_callback(to_map_callback)


func _on_card_reward_1_pressed():
	print("Clicked on reward 1")
	end_reward_screen(1)


func _on_card_reward_2_pressed():
	print("Clicked on reward 2")
	end_reward_screen(2)
	
func spawn_build_particle(pos_world: Vector2, wait: float):
	var cnt = randi_range(1, 4)
	for i in cnt:
		var p = preload("res://Scenes/ParticleSimple.tscn").instantiate()
		var dir = Vector2(cos(randf_range(0,2*PI)), sin(randf_range(0, 2*PI)))
		p.position = pos_world + dir *randf_range(10, 80)
		p.total_lifetime = randf_range(0.4, 0.7)
		p.wait_time = wait
		p.visible = wait <= 0.0
		p.speed = dir * randf_range(150, 250)
		$Particles.add_child(p)


func _on_button_quit_pressed():
	if quit_is_extended:
		var tween = create_tween()
		tween.tween_property($UI/Quit, "position", Vector2(0, $UI/Quit.position.y), 0.3)
	else:
		var tween = create_tween()
		tween.tween_property($UI/Quit, "position", Vector2(200, $UI/Quit.position.y), 0.3)
	quit_is_extended = not quit_is_extended
		


func _on_button_quit_accept_pressed():
	if in_tutorial:
		get_tree().change_scene_to_file("res://Scenes/MainMenu.tscn")
	else:
		if CAN_DIE:
			is_dead = true
			start_death_sequence()
		else:
			get_tree().change_scene_to_file("res://Scenes/MainMenu.tscn")
			
