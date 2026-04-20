extends Sprite2D


var wait_time = 0.0
var total_lifetime = 1.0
var time_alive = 0.0
var speed = Vector2.ONE

func  _process(delta):
	if wait_time > 0:
		wait_time -= delta
		return
			
	visible = true
	time_alive += delta
	
	if time_alive >= total_lifetime:
		queue_free()
		return
		
	position += delta * speed
	
	modulate.a = clamp(1.0 - time_alive/total_lifetime,0.0, 1.0)
