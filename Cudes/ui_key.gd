extends Node2D
var letter = ""
func _physics_process(delta: float) -> void:
	if $AnimatedSprite2D.animation == "Pressed":
		$AnimatedSprite2D/Label.position.y = -7
	else: $AnimatedSprite2D/Label.position.y = -14
	$AnimatedSprite2D/Label.text = letter
