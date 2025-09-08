extends Node2D

var tutorial_scene = preload("res://Scenes/toturial.tscn")
@export var shake_key = false  # animation player will toggle this

var shaking := false

func _physics_process(delta: float) -> void:
	# Check if shake_key is set during animations
	if shake_key and not shaking:
		shaking = true
		shake_key = false  # reset so it doesn’t loop forever
		screen_shake(10.0, 0.4, 0.03)


func _on_button_pressed() -> void:
	$AnimationPlayer.play("JailBg2")
	$PointLight2D.visible = true
	$Button.queue_free()


func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	if anim_name == "JailBg1":
		$AnimationPlayer.play("BG1")
		$PointLight2D.visible = false
	elif anim_name == "BG1":
		$AnimationPlayer.play("JailBg1_2")
		$PointLight2D.visible = true
	elif anim_name == "JailBg1_2":
		$AnimationPlayer.play("BG2")
		$PointLight2D.visible = false
	elif anim_name == "BG2":
		$AnimationPlayer.play("JailBg1_3")
		$PointLight2D.visible = true
	elif anim_name == "JailBg1_3":
		$AnimationPlayer.play("BG3")
		$PointLight2D.visible = false
	elif anim_name == "BG3":
		$AnimationPlayer.play("JailBg2")
		$PointLight2D.visible = true
	elif anim_name == "JailBg2":
		$PointLight2D.visible = false
		get_tree().change_scene_to_file("res://Scenes/toturial.tscn")


# --- SHAKE FUNCTION ---
func screen_shake(intensity: float = 3.0, duration: float = 0.25, frequency: float = 0.02) -> void:
	var elapsed := 0.0
	var original_canvas := get_viewport().canvas_transform

	while elapsed < duration:
		var falloff := 1.0 - (elapsed / duration) # makes shake fade out
		var offset := Vector2(
			randf_range(-intensity, intensity),
			randf_range(-intensity, intensity)
		) * falloff

		var t := original_canvas
		t.origin = original_canvas.origin + offset
		get_viewport().canvas_transform = t

		await get_tree().create_timer(frequency).timeout
		elapsed += frequency

	# reset
	get_viewport().canvas_transform = original_canvas
	shaking = false
