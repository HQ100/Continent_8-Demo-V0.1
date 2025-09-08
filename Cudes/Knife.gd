extends CharacterBody2D


var speed = 0
var attacking = false

func _physics_process(delta):
	
	velocity.y = speed
	move_and_slide()
	
	if is_on_floor() and attacking:
		$"../Knfie_warning".visible = false
		speed = 0
	
	if global_position.y < 0:
		speed = 0


func _on_area_2d_area_entered(area: Area2D) -> void:
	pass
