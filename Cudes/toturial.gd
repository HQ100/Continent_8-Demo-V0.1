extends Node2D

var jail_scene = preload("res://Scenes/jail.tscn")
var target_pos
var Attacked = false
var speed = 0.0
var stiffness = 80.0   # how strong dummy pulls back to 0
var modulation = 0
var UI_modulation := 0.0
var Player_is_spawned := false
var fading_in := false
var fading_out := false
var animation_loop := false
var input_blocked := true

func _ready() -> void:
	# Camera setup
	$Camera2D.limit_left = 0
	$Camera2D.limit_bottom = 424
	$Camera2D.limit_top = $Camera2D.limit_bottom - 360
	$Camera2D.position.y = $Player.position.y - 30
	$Camera2D.make_current()

	# Player setup
	$Player.global_position = $AnimatedSprite2D.global_position
	$Player.visible = false
	$Player.set_physics_process(false)

	# Fade setup
	$CanvasLayer/fade.color = Color(0,0,0,1)  # fully black at start
	$CanvasLayer/fade.visible = true

	# Start fade-in coroutine
	start_fade_in()

func start_fade_in() -> void:
	input_blocked = true  # block W input during black screen
	var c = $CanvasLayer/fade.color

	# Fade out the black screen
	while c.a > 0:
		c.a -= get_process_delta_time() / 2.0   # adjust speed
		$CanvasLayer/fade.color = c
		await get_tree().process_frame

	# Black screen fade is done → unblock input immediately
	input_blocked = false

	# Wait 3 seconds before showing the UI_Key
	await get_tree().create_timer(1.0).timeout
	if not Player_is_spawned:
		fading_in = true
		$Ui_Key.letter = "W"





func _physics_process(delta: float) -> void:
	# UI_Key fade-in
	if fading_in and not Player_is_spawned:
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

	# Only allow pressing W after fade-in finishes
	if Input.is_action_just_pressed("W") and not Player_is_spawned and not input_blocked:
		$AnimatedSprite2D.play("Wakeup")
		Player_is_spawned = true
		$Player.global_position.x = $AnimatedSprite2D.global_position.x
		$Player.set_physics_process(false)

		fading_in = false
		fading_out = true

	# Dummy logic
	target_pos = $Dummy.global_position.x - $Player.global_position.x
	$Dummy.global_position = Vector2(2640.0,357.0)

	var restoring_force = -$Dummy.rotation * stiffness * delta
	speed += restoring_force
	$Dummy.rotation += speed * delta

	if $Dummy.rotation < deg_to_rad(-60):
		$Dummy.rotation = deg_to_rad(-60)
		speed *= -1
	elif $Dummy.rotation > deg_to_rad(60):
		$Dummy.rotation = deg_to_rad(60)
		speed *= -1

	speed *= 0.985

	# ColorRect2 modulate based on player X
	if $Player.global_position.x >= 3710 and $Player.global_position.x < 4520:
		modulation = ($Player.global_position.x - 3710)/765
		var color = Color(1,1,1,modulation)
		$ColorRect2.self_modulate = color

	# Move to jail scene
	if $Player.global_position.x > 4520:
		get_tree().change_scene_to_file("res://Scenes/jail.tscn")

	# Camera follow with limits
	var cam_pos = $Player.position
	cam_pos.y = clamp(cam_pos.y, $Camera2D.limit_top, $Camera2D.limit_bottom)
	cam_pos.x = max(cam_pos.x, $Camera2D.limit_left) 
	$Camera2D.position = cam_pos


func _on_area_2d_area_entered(area: Area2D) -> void:
	Attacked = true
	if area.name == "PlayerHitbox" and Attacked:
		if target_pos <= 0:
			speed = -10
		else:
			speed = 10
	await get_tree().create_timer(0.1).timeout
	Attacked = false


func _on_animated_sprite_2d_animation_finished() -> void:
	$AnimatedSprite2D.visible = false
	$Player.set_physics_process(true)
	$Player.visible = true


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


func _set_ui_alpha(alpha: float) -> void:
	var color = Color(1,1,1,alpha)
	$Ui_Key/AnimatedSprite2D.self_modulate = color
	$Ui_Key/AnimatedSprite2D/Label.self_modulate = color
