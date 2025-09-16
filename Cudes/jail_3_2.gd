extends Node2D

var player_scene = preload("res://Scenes/player.tscn")
var player = player_scene.instantiate()
var slave2_scene = preload("res://Scenes/slave_2.tscn")
var slave2 = slave2_scene.instantiate()
var jail_3_2_scene = preload("res://Scenes/jail_3_2.tscn")
var stop = false
var stop2 = false
var scene = false
var direc = 0
var start = false
var dmg_overlay : ColorRect
var dmgshow = true
var flash_started = false
var counted = false

func _ready() -> void:
	var color = Color(1,1,1,1)
	$CanvasLayer2/AnimatedSprite2D.self_modulate = color
	$CanvasLayer2/AnimatedSprite2D.play("Death")
	$CanvasLayer2/AnimatedSprite2D2.play("3_HP")
	fade_in_from_black(2)
	
	add_child(player)
	player.set_physics_process(false)
	player.global_position = Vector2(120, 263.44555)
	$Slave2head/Sprite2D.flip_h = true
	$Camera2D.global_position.x = 5001.6
	Health_bar()
	stop2 = true
	$PrisonGuard/RayCast2D.enabled = true
	$PrisonGuard/RayCast2D2.enabled = true
	$PrisonGuard.entrance_switch = false
	$PrisonGuard.skip_cutscene = false
	$PrisonGuard.global_scale = Vector2(1,-1)
	$PrisonGuard.global_rotation = PI
	$Skipper.start()
	RenderingServer.set_default_clear_color(Color.BLACK)
	# --- DAMAGE OVERLAY ---
	dmg_overlay = ColorRect.new()
	dmg_overlay.z_index = 2
	dmg_overlay.color = Color(1, 0, 0, 0) # red but invisible
	dmg_overlay.size = Vector2(get_viewport().size.x, get_viewport().size.y)
	dmg_overlay.position = Vector2(95, 0)
	dmg_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dmg_overlay)

func _physics_process(delta: float):
	if $PrisonGuard.im_hit:
		player.landed_attack = true
		
	if player.Health == 2:
		$CanvasLayer2/AnimatedSprite2D2/UiHeart3.visible = false
		$CanvasLayer2/AnimatedSprite2D2.play("2_HP")
	if player.Health == 1:
		$CanvasLayer2/AnimatedSprite2D2/UiHeart2.visible = false
		$CanvasLayer2/AnimatedSprite2D2.play("1_HP")
	if player.Health == 0:
		$CanvasLayer2/AnimatedSprite2D2/UiHeart.visible = false
		$CanvasLayer2/AnimatedSprite2D2.play("0_HP")


	if player.Death:
		if not counted:
			GlobalC.death_counter += 1
			counted = true
		$PrisonGuard.set_physics_process(false)
		$PrisonGuard/AnimationPlayer.stop()
		$PrisonGuard/AnimationPlayer.play("Heal")
		await get_tree().create_timer(1.2).timeout
		await fade_to_black_and_change_scene("res://Scenes/jail_3_2.tscn")

	if $PrisonGuard.death and not flash_started:
		player.get_child(6).get_child(0).disabled = true
		player.get_child(6).get_child(1).disabled = true
		flash_started = true
		player.Inputs = false
		player.velocity.x = 0
		player.velocity.y = 385
		player.get_child(5).play("UnarmedIdle")
		$StaticBody2D2/CollisionShape2D.disabled = true
		await get_tree().create_timer(1.4).timeout
		player.velocity.x = player.speed
		player.rotation = 0
		player.scale = Vector2(1,1)
		player.get_child(5).play("Run")
		await get_tree().create_timer(1.4).timeout
		$PrisonGuard/AnimationPlayer2.play("purpledeath")
		$PrisonGuard/Explosion.Blood2()
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
	if not dmgshow and player.Death != true:
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
			player.velocity = Vector2(-2300,200)
		else:
			player.velocity = Vector2(2300,200)
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

func start_flash_and_change_scene() -> void:
	var flash = ColorRect.new()
	flash.color = Color(1, 1, 1, 0.0) # start transparent
	flash.scale = Vector2(1000,1000)
	flash.size = get_viewport_rect().size
	flash.z_index = 20
	add_child(flash)

	var flash_alpha = 0.75
	var flash_duration = 0.2
	var wait_duration = 0.1

	# --- First: Purple flash ---
	flash.color = Color(0.6, 0.0, 0.8, 0.0) # purple, transparent start
	var tween_purple_in := create_tween()
	tween_purple_in.tween_property(flash, "color:a", flash_alpha, flash_duration)
	await tween_purple_in.finished

	await get_tree().create_timer(wait_duration).timeout

	var tween_purple_out := create_tween()
	tween_purple_out.tween_property(flash, "color:a", 0.0, flash_duration)
	await tween_purple_out.finished

	# --- Next: Two white flashes ---
	for i in range(1):
		flash.color = Color(1, 1, 1, 0.0) # reset to white, transparent
		var tween_in := create_tween()
		tween_in.tween_property(flash, "color:a", flash_alpha, flash_duration)
		await tween_in.finished

		await get_tree().create_timer(wait_duration).timeout

		var tween_out := create_tween()
		tween_out.tween_property(flash, "color:a", 0.0, flash_duration)
		await tween_out.finished

	# remove flash node and switch scene
	flash.queue_free()
	get_tree().change_scene_to_file("res://Scenes/Nextlevel.tscn")


func fade_to_black_and_change_scene(next_scene: String) -> void:
	var fade = ColorRect.new()
	fade.color = Color(0, 0, 0, 0.0) # black, transparent
	fade.scale = Vector2(1000, 1000)
	fade.size = get_viewport_rect().size
	fade.z_index = 30
	add_child(fade)

	var tween := create_tween()
	tween.tween_property(fade, "color:a", 1.0, 2.0) # fade in over 1 second
	await tween.finished

	# cleanup
	fade.queue_free()

	# safe scene change
	if get_tree():
		get_tree().change_scene_to_file(next_scene)
func fade_in_from_black(duration: float = 2.0) -> void:
	var fade = ColorRect.new()
	fade.color = Color(0, 0, 0, 1.0) # fully black
	fade.scale = Vector2(1000, 1000)
	fade.size = get_viewport_rect().size
	fade.z_index = 30
	add_child(fade)

	var tween := create_tween()
	tween.tween_property(fade, "color:a", 0.0, duration) # fade out to transparent
	await tween.finished

	fade.queue_free()
