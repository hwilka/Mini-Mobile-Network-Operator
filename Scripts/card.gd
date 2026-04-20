extends Control

signal pressed

@export var _symbol_type = 0
var symbol_type: int:
	get:
		return _symbol_type
	set(value):
		_symbol_type = value
		if value == 0:
			$Symbol.texture = preload("res://img/UI/Card/CellHouse.png")
		elif value == 1:
			$Symbol.texture = preload("res://img/UI/Card/CellTower.png")
		elif value == 2:
			$Symbol.texture = preload("res://img/UI/Card/CellWiden.png")
		elif value == 3:
			$Symbol.texture = preload("res://img/UI/Card/CellCapacity.png")
			
@export var _title = "Title"
var title: String:
	get:
		return _title
	set(value):
		_title = value
		$Title.text = value
		
@export var _count = 0
var count: int:
	get:
		return _count
	set(value):
		_count = value
		$CountText.text = str(value)

func _ready():
	
	# Update symbol
	symbol_type = _symbol_type
	title = _title
	count = _count


func _on_texture_button_pressed():
	pressed.emit()
