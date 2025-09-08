extends Node2D

var player_scene = preload("res://Scenes/player.tscn")
var player = player_scene.instantiate()
var jail_2_scene = preload("res://Scenes/jail_2.tscn")
var player_is_spawned = false

# UI Key
var UI_modulation := 0.0
var fading_in := false
var fading_out := false
var animation_loop := false

# Transition
var transition_speed := 2.0 # seconds for fade-in/out
var transition_in_progress := false


func _ready():
	# Ensure ColorRect is on top
	$ColorRect.z_index = 5

	# Add player
	player.camera = false
	add_child(player)

	if GlobalC.first_time_game:
		$AnimatedSprite2D.play("default")
		player.global_position = $AnimatedSprite2D.global_position
		player.visible = false
		player.speed = 0
		player.forcewalk = true
		$AnimationPlayer.play("new_animation")
	else:
		player_is_spawned = true
		player.global_position = Vector2(189, 222)
		player.can_dash = false
		player.forcewalk = true
		$AnimatedSprite2D.visible = false

	# Start fade-in at scene start
	start_transition()


func start_transition() -> void:
	# Start with black overlay fully opaque
	var c = $ColorRect.color
	c.a = 1
	$ColorRect.color = c
	transition_in_progress = true
	fade_in_then_ui()


func fade_in_then_ui() -> void:
	# Fade from black to transparent
	var c = $ColorRect.color  # declare once before loop
	while c.a > 0:
		c.a -= get_process_delta_time() / transition_speed
		$ColorRect.color = c
		await get_tree().process_frame

	transition_in_progress = false

	# Start UI_Key fade-in 3 seconds after fade-in ends
	await get_tree().create_timer(1.0).timeout
	if not player_is_spawned:
		fading_in = true
		$Ui_Key.letter = "W"


func _physics_process(delta: float):
	# UI_Key fade-in
	if fading_in and not player_is_spawned:
		UI_modulation += delta
		if UI_modulation >= 1.0:
			UI_modulation = 1.0
			fading_in = false
			start_animation_loop()
		_set_ui_alpha(UI_modulation)

	# UI_Key fade-out
	if fading_out:
		UI_modulation -= delta
		if UI_modulation <= 0.0:
			UI_modulation = 0.0
			fading_out = false
			$Ui_Key/AnimatedSprite2D.stop()
		_set_ui_alpha(UI_modulation)

	# Spawn player when W pressed
	if Input.is_action_just_pressed("W") and not player_is_spawned and not fading_in and not transition_in_progress:
		$AnimatedSprite2D.play("Wakeup")
		player_is_spawned = true
		player.global_position.x = $AnimatedSprite2D.global_position.x
		player.set_physics_process(false)

		# Start fading out UI_Key
		fading_in = false
		fading_out = true


func _on_animated_sprite_2d_animation_finished() -> void:
	$AnimatedSprite2D.visible = false
	player.set_physics_process(true)
	player.speed = 320
	player.visible = true
	player.can_dash = false
	GlobalC.first_time_game = false


# Fade-out to next scene when Area2D entered
func _on_area_2d_area_entered(area: Area2D) -> void:
	if not transition_in_progress:
		transition_in_progress = true
		fade_out_then_change_scene("res://Scenes/jail_2.tscn")


func fade_out_then_change_scene(next_scene_path: String) -> void:
	# Start from transparent
	var c = $ColorRect.color
	c.a = 0
	$ColorRect.color = c

	while $ColorRect.color.a < 1:
		c.a += get_process_delta_time() / transition_speed
		$ColorRect.color = c
		await get_tree().process_frame

	# Fully opaque, now change scene
	get_tree().change_scene_to_file(next_scene_path)


# Pressed/Pressedn't loop
func start_animation_loop() -> void:
	if animation_loop: return
	animation_loop = true
	animate_key()


func animate_key() -> void:
	if fading_out: return
	$Ui_Key/AnimatedSprite2D.play("Pressed")
	await get_tree().create_timer(1).timeout
	if fading_out: return
	$Ui_Key/AnimatedSprite2D.play("Pressedn't")
	await get_tree().create_timer(1).timeout
	animate_key()


# Sets alpha for UI_Key and its label
func _set_ui_alpha(alpha: float) -> void:
	var color = Color(1, 1, 1, alpha)
	$Ui_Key/AnimatedSprite2D.self_modulate = color
	$Ui_Key/AnimatedSprite2D/Label.self_modulate = color
