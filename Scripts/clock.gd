extends Node2D

var arm_rotation_degrees: float:
	get:
		return $Arm.rotation_degrees
	set(value):
		$Arm.rotation_degrees = value
