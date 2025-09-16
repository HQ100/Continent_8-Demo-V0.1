extends Node2D

var player_scene = preload("res://Scenes/player.tscn")
var player = player_scene.instantiate()
var jail_3_scene = preload("res://Scenes/jail_3.tscn")

var energy_tween
var scale_tween
var near_lever = false
var fading_in := false
var fading_out := false

# --- UI Key control ---
var ui_tween: Tween
var animating_key := false

func _ready():
	RenderingServer.set_default_clear_color(Color.BLACK)
	$AnimatedSprite2D.play("closed")
	add_child(player)
	player.global_position = Vector2(118,220)
	player.forcewalk = true
	player.can_dash = false

	# Candle effects
	candle()

	# Lever default animation
	$Lever.play("default")

	# Fade setup
	$CanvasLayer/fade.color = Color(0,0,0,1) # black screen
	$CanvasLayer/fade.visible = true
	start_fade_in()

	# UI Key setup (hidden at start)
	if $Ui_Key:
		$Ui_Key.visible = false
		$Ui_Key.letter = ""
		_ui_set_alpha(0.0)

func _physics_process(delta: float):
	
	if $Slave2.Ui_mike:
		var tween = get_tree().create_tween()
		# start fully transparent
		$CanvasLayer2/AnimatedSprite2D.self_modulate.a = 0.0
		# fade in to fully visible over 1 second
		tween.tween_property($CanvasLayer2/AnimatedSprite2D, "self_modulate:a", 1.0, 1.0)


	if fading_in:
		var c = $CanvasLayer/fade.color
		c.a -= delta / 2.0
		if c.a <= 0.0:
			c.a = 0.0
			fading_in = false
		$CanvasLayer/fade.color = c

	# Fade-out
	if fading_out:
		var c = $CanvasLayer/fade.color
		c.a += delta / 2.0
		if c.a >= 1.0:
			c.a = 1.0
			fading_out = false
			get_tree().change_scene_to_file("res://Scenes/jail_3.tscn")
		$CanvasLayer/fade.color = c

	# Camera follow
	var target_pos = $Camera2D.global_position.lerp(player.global_position, delta * 5.0)
	$Camera2D.global_position = target_pos.floor()

	# Lever interaction
	if near_lever and Input.is_action_just_pressed("F"):
		$Lever.play("activated")
		$Slave2.freed = true
		$Bars.play("Open")
		_ui_flash_stop() # hide after interaction

func candle():
	energy_tween = create_tween()
	scale_tween = create_tween()

	# Energy flicker
	energy_tween.tween_property($PointLight2D, "energy", 1.2, 1.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	energy_tween.tween_property($PointLight2D, "energy", 2, 1.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	energy_tween.set_loops()

	# Scale flicker
	scale_tween.tween_property($PointLight2D, "scale", Vector2(0.1,0.1), 1.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	scale_tween.tween_property($PointLight2D, "scale", Vector2(0.125,0.125), 1.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	scale_tween.set_loops()

# Fade-in coroutine
func start_fade_in() -> void:
	fading_in = true

# --- Area events ---
func _on_area_2d_area_entered(area: Area2D) -> void:
	if area.name == "PlayerHurtbox":
		fading_out = true
		player.Inputs = false
		_ui_flash_stop()
	if area.name == "Slave2Area":
		$Slave2.velocity.x = 0
		$Slave2.end_point = true

func _on_slave_2_cell_door_area_entered(area: Area2D) -> void:
	if area.name == "PlayerHurtbox":
		$Slave2.seen_player = true
	if area.name == "Slave2Area":
		$Slave2.reached_door = true

func _on_slave_2_cell_lever_area_entered(area: Area2D) -> void:
	$Slave2.got_passed = true
	$Ui_Key.letter = "F"
	near_lever = true
	_ui_flash_start()

func _on_slave_2_ignoring_area_entered(area: Area2D) -> void:
	if area.name == "PlayerHurtbox":
		$Slave2.ignored = true
	else:
		# Play the default animation once
		$AnimatedSprite2D.play("default")
		$Slave2.velocity.x = $Slave2.speed
		$Slave2.Stopper = true
		$Slave2/AnimationPlayer.play("RESET")
		# Wait for the default animation to finish
		await $AnimatedSprite2D.animation_finished
		$StaticBody2D2/CollisionShape2D.disabled = true
		$Slave2.Stopper = false
		$Slave2.velocity.x = $Slave2.speed
		$AnimatedSprite2D.play("open")

func _on_slave_2_cell_lever_area_exited(area: Area2D) -> void:
	near_lever = false
	_ui_flash_stop()

# --- UI Key helpers ---
func _ui_set_alpha(a: float) -> void:
	var c := Color(1,1,1,a)
	$Ui_Key/AnimatedSprite2D.self_modulate = c
	$Ui_Key/AnimatedSprite2D/Label.self_modulate = c

func _ui_flash_start() -> void:
	if not $Ui_Key:
		return
	if is_instance_valid(ui_tween):
		ui_tween.kill()
	$Ui_Key.visible = true
	_ui_set_alpha(0.0)
	# Fade-in (slower, ~0.4s)
	ui_tween = create_tween()
	ui_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	ui_tween.tween_property($Ui_Key/AnimatedSprite2D, "self_modulate:a", 1.0, 0.4)
	ui_tween.parallel().tween_property($Ui_Key/AnimatedSprite2D/Label, "self_modulate:a", 1.0, 0.4)
	# Start key animation loop
	animate_key()

func _ui_flash_stop() -> void:
	if not $Ui_Key:
		return
	if is_instance_valid(ui_tween):
		ui_tween.kill()
	animating_key = false
	# Fade-out (~0.3s), then hide
	ui_tween = create_tween()
	ui_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	ui_tween.tween_property($Ui_Key/AnimatedSprite2D, "self_modulate:a", 0.0, 0.3)
	ui_tween.parallel().tween_property($Ui_Key/AnimatedSprite2D/Label, "self_modulate:a", 0.0, 0.3)
	ui_tween.finished.connect(func():
		if $Ui_Key:
			$Ui_Key.visible = false
	)

# --- Key press animation loop ---
func animate_key() -> void:
	if animating_key or fading_out:
		return
	animating_key = true
	_key_loop()

func _key_loop() -> void:
	var state_pressed := false # start with Pressedn't first
	while animating_key and not fading_out:
		if state_pressed:
			$Ui_Key/AnimatedSprite2D.play("Pressed")
		else:
			$Ui_Key/AnimatedSprite2D.play("Pressedn't")
		await get_tree().create_timer(1.0).timeout
		state_pressed = !state_pressed # flip state each loop
