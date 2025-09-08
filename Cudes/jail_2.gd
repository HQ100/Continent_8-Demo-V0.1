extends Node2D

var player_scene = preload("res://Scenes/player.tscn")
var player = player_scene.instantiate()
var jail_3_scene = preload("res://Scenes/jail_3.tscn")
var energy_tween
var scale_tween
var near_lever = false
var fading_in := false
var fading_out := false

func _ready():
	# Add player
	add_child(player)
	player.global_position = Vector2(118,220)
	player.forcewalk = true
	player.can_dash = false

	# Candle effects
	candle()

	# Lever default animation
	$Lever.play("default")

	# Fade setup
	$CanvasLayer/fade.color = Color(0,0,0,1)  # black screen
	$CanvasLayer/fade.visible = true
	start_fade_in()

func _physics_process(delta: float):
	# Fade-in
	if fading_in:
		var c = $CanvasLayer/fade.color
		c.a -= delta / 2.0  # adjust fade-in speed
		if c.a <= 0.0:
			c.a = 0.0
			fading_in = false
		$CanvasLayer/fade.color = c

	# Fade-out
	if fading_out:
		var c = $CanvasLayer/fade.color
		c.a += delta / 2.0  # adjust fade-out speed
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

func candle():
	energy_tween = create_tween()
	scale_tween = create_tween()
	
	# Energy flicker
	energy_tween.tween_property($PointLight2D, "energy", 1.2,1.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	energy_tween.tween_property($PointLight2D, "energy", 2,1.0 ).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	energy_tween.set_loops()
	
	# Scale flicker
	scale_tween.tween_property($PointLight2D, "scale", Vector2(0.1,0.1) ,1.0 ).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	scale_tween.tween_property($PointLight2D, "scale", Vector2(0.125,0.125),1.0 ).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	scale_tween.set_loops()

# Fade-in coroutine
func start_fade_in() -> void:
	fading_in = true

# Trigger fade-out when entering scene areas
func _on_area_2d_area_entered(area: Area2D) -> void:
	if area.name == "PlayerHurtbox":
		fading_out = true
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
	near_lever = true

func _on_slave_2_ignoring_area_entered(area: Area2D) -> void:
	$Slave2.ignored = true

func _on_slave_2_cell_lever_area_exited(area: Area2D) -> void:
	near_lever = false
