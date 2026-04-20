extends Node2D

func _ready():
	set_tutorial_text()
	
	var cam = $Camera2D
	cam.position = $CamStart.position
	cam.rotation_degrees = $CamStart.rotation_degrees
	cam.zoom = Vector2(1/$CamStart.scale.x, 1/$CamStart.scale.y)
	_on_back_pressed()

func set_tutorial_text():
	if Global.tutorial_enabled:
		$MMPos/Control2/Tutorial.text = "Disable Tutorial"
	else:
		$MMPos/Control2/Tutorial.text = "Enable Tutorial"
	
	
func load_map_scene():
	get_tree().change_scene_to_file("res://Scenes/Map.tscn")
	

func _on_start_pressed():
	const ANIM_TIME = 1.5
	var tween = create_tween()
	tween.tween_property($Camera2D, "position", $MMPos.position + Vector2(-400, -4000), ANIM_TIME)
	
	tween = create_tween()
	tween.tween_property($Camera2D, "rotation_degrees", -20, ANIM_TIME)
	
	tween = create_tween()
	tween.tween_property($Camera2D, "zoom", Vector2(1.1, 1.1), ANIM_TIME)
	tween.tween_callback(load_map_scene)
	


func _on_tutorial_pressed():
	Global.tutorial_enabled = not Global.tutorial_enabled
	set_tutorial_text()

func _on_credits_pressed():
	const ANIM_TIME = 0.9
	
	var tween = create_tween()
	tween.tween_property($Camera2D, "position", $CreditsPos.position, ANIM_TIME)
	tween = create_tween()
	tween.tween_property($Camera2D, "rotation_degrees", $CreditsPos.rotation_degrees, ANIM_TIME)
	tween = create_tween()
	tween.tween_property($Camera2D, "zoom", Vector2(1/$CreditsPos.scale.x, 1/$CreditsPos.scale.y), ANIM_TIME)

func _on_back_pressed():
	const ANIM_TIME = 0.9
	
	var tween = create_tween()
	tween.tween_property($Camera2D, "position", $MMPos.position, ANIM_TIME)
	tween = create_tween()
	tween.tween_property($Camera2D, "rotation_degrees", $MMPos.rotation_degrees, ANIM_TIME)
	tween = create_tween()
	tween.tween_property($Camera2D, "zoom", Vector2(1/$MMPos.scale.x, 1/$MMPos.scale.y), ANIM_TIME)
