extends Node2D

var player_scene = preload("res://Scenes/player.tscn")
var player = player_scene.instantiate()
var slave2_scene = preload("res://Scenes/slave_2.tscn")
var slave2 = slave2_scene.instantiate()
var stop = false
var stop2 = false
var scene = false
var direc = 0
var start = false
var dmg_overlay : ColorRect
var dmgshow = true
var flash_started = false

func _ready() -> void:
	add_child(player)
	player.set_physics_process(false)
	player.global_position = Vector2(120, 263.44555)
	$Slave2head/Sprite2D.flip_h = true
	$Camera2D.global_position.x = 5001.6
	Health_bar()
	stop2 = true
	$PrisonGuard/RayCast2D.enabled = true
	$PrisonGuard.entrance_switch = false
	$PrisonGuard.skip_cutscene = false
	$PrisonGuard.global_scale = Vector2(1,-1)
	$PrisonGuard.global_rotation = PI
	$Skipper.start()
	
	# --- DAMAGE OVERLAY ---
	dmg_overlay = ColorRect.new()
	dmg_overlay.z_index = 2
	dmg_overlay.color = Color(1, 0, 0, 0) # red but invisible
	dmg_overlay.size = Vector2(get_viewport().size.x, get_viewport().size.y)
	dmg_overlay.position = Vector2(95, 0)
	dmg_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dmg_overlay)

func _physics_process(delta: float):
	# --- GUARD DEATH: WHITE FLASH + SCENE SWITCH ---
	if $PrisonGuard.death and not flash_started:
		flash_started = true
		await start_flash_and_change_scene()
		return

	direc = $PrisonGuard.global_position.x - player.global_position.x
	$TextureProgressBar.value = $PrisonGuard.Health
	if $PrisonGuard.In_phase_2 and $TextureProgressBar.value <= 0:
		$PrisonGuard.death = true

	# --- DAMAGE OVERLAY ---
	if player.invinc == true and dmgshow:
		dmgshow = false
		show_damage_overlay()
	if not dmgshow:
		await get_tree().create_timer(1.5).timeout
		dmgshow = true

	# --- CLOUDS PARALLAX ---
	$ParallaxBackground/ParallaxLayer2/Clouds.global_position.x -= 0.03
	if $ParallaxBackground/ParallaxLayer2/Clouds.global_position.x <= -320:
		$ParallaxBackground/ParallaxLayer2/Clouds.global_position.x = 320

	# --- PHASE 4 HEAL SCENE ---
	if $PrisonGuard.phase4 == true and not scene:
		$PrisonGuard/AnimationPlayer.stop()
		$PrisonGuard/AnimationPlayer.play("Heal")
		$PrisonGuard.Chaos = false
		$PrisonGuard.set_physics_process(false)
		if player.dashing:
			player.velocity.x = 0
		player.Inputs = false
		if direc >= 0 :
			player.velocity.x = -2300
		else:
			player.velocity.x = 2300
		scene = true
		await get_tree().create_timer(2.7).timeout
		$TextureProgressBar.max_value = 300
		$PrisonGuard.Health = 100
		await get_tree().create_timer(0.3).timeout
		$PrisonGuard.Health = 200
		await get_tree().create_timer(0.3).timeout
		$PrisonGuard.Health = 300
		await get_tree().create_timer(0.9).timeout
		player.Inputs = true
		$PrisonGuard.set_physics_process(true)
		$PrisonGuard.In_phase_2 = true
		if $PrisonGuard/AnimationPlayer.current_animation == "":
			$PrisonGuard/AnimationPlayer.play("Attack1_2")
			$PrisonGuard.velocity.x = 0
		$PrisonGuard.attack_pool = []


func Health_bar():
	if start == false:
		start = true
		await get_tree().create_timer(0.2).timeout
		$AnimationPlayer.play("Health_bar")


func show_damage_overlay():
	dmg_overlay.color = Color(1, 0, 0, 0.4)
	dmg_overlay.show()
	var tween := create_tween()
	tween.tween_property(dmg_overlay, "color:a", 0.0, 0.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_callback(Callable(dmg_overlay, "hide"))


func _on_skipper_timeout() -> void:
	$PrisonGuard.skip_cutscene = true
	$StaticBody2D/CollisionShape2D2.disabled = false
	player.set_physics_process(true)


# --- WHITE FLASH + SCENE CHANGE ---
func start_flash_and_change_scene() -> void:
	var flash = ColorRect.new()
	flash.scale = Vector2(1000,1000)
	flash.color = Color(1, 1, 1, 0.0) # transparent white
	flash.size = get_viewport_rect().size
	flash.z_index = 20
	add_child(flash)

	var flashes = 2
	var flash_alpha = 0.75
	var flash_duration = 0.2
	var wait_duration = 0.1

	for i in range(flashes):
		# fade in
		var t := 0.0
		while t < flash_duration:
			t += get_process_delta_time()
			flash.color.a = lerp(0.0, flash_alpha, t / flash_duration)
			await get_tree().process_frame
		# hold full alpha
		await get_tree().create_timer(wait_duration).timeout
		# fade out
		t = 0.0
		while t < flash_duration:
			t += get_process_delta_time()
			flash.color.a = lerp(flash_alpha, 0.0, t / flash_duration)
			await get_tree().process_frame
		flash.color.a = 0.0

	# remove flash node and switch scene
	flash.queue_free()
	get_tree().change_scene_to_file("res://Scenes/Nextlevel.tscn")
