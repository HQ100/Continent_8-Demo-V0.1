extends CharacterBody2D


var speed = 0

func _physics_process(delta: float) -> void:
	velocity.x = speed
	move_and_slide()


func _on_area_2d_area_entered(area: Area2D) -> void:
	pass
