extends CharacterBody2D

var knife_scene = preload("res://Scenes/knife.tscn")
var knife = knife_scene.instantiate()
var arrow_scene = preload("res://Scenes/arrow.tscn")
var nextlevel_scene = preload("res://Scenes/Nextlevel.tscn")
@export var anticipation_finish = false
var player_position_x
var target_pos
@export var stop_after_attack = false
var is_attacking = false
var attack_pool = []
var arrow_pool = []
var facing_left = false
var entrance = false
var gravity = true
var entrance_switch = true
var phase2 = false
var phase3 = false
var phase4 = false
var phase5 = false
var rng = RandomNumberGenerator.new()
var stopper = true
var special = false
var knife_count = 2
var special_end = false
var Health = 150
var invinc = false
var Chaos = false
var death = false
var In_phase_2 = false
var skip_cutscene = true

func _ready():
	reset_attack_pool()
	$RayCast2D.enabled = false
	$Hitbox/CollisionShape2D.disabled = true
func _physics_process(delta: float):
	
	if Health <= 0 and not phase4:
		$Atk1timer.stop()
		await get_tree().create_timer(0.01).timeout
		$AnimationPlayer.stop()
		velocity.x = 0
		$Explosion.Explode()
		phase4 = true
	if death:
		print("win")
		visible = false
		set_physics_process(false)
	if entrance and not gravity:
		scale = Vector2(1,-1)
		rotation = PI
		$AnimationPlayer.play("Drop")
		
	elif entrance and gravity and not is_on_floor() and entrance_switch:
		velocity.y = 800
		$EarthSlam.start()
	elif entrance and gravity and is_on_floor() and entrance_switch:
		entrance_switch = false
		$AnimationPlayer.play("Entrance")
		$EntranceTimer.start()
		
	if not is_on_floor() and gravity:
		velocity += get_gravity() * delta

	var players = get_tree().get_nodes_in_group("PlayerC")
	if !phase4:
		if players.size() > 0 and !entrance and skip_cutscene:
			var player = players[0]
			player_position_x = player.global_position.x
			if Health <= 0 :
				player.Inputs = false
			if not is_attacking:
				target_pos = global_position.x - player_position_x
			
			if target_pos > 30 and not is_attacking:
				scale = Vector2(1,-1)
				rotation = PI
				velocity.x = -50
				
			elif target_pos < -30 and not is_attacking:
				scale = Vector2(1,1)
				rotation = 0
				velocity.x = 50
			elif target_pos < 30 and target_pos > -30 and not is_attacking:
				velocity.x = 0
				$AnimationPlayer.play("Idle")
				
			if target_pos > 0 and not is_attacking:
				scale = Vector2(1,-1)
				rotation = PI
			elif target_pos < 0 and not is_attacking:
				scale = Vector2(1,1)
				rotation = 0
				
				
			if $AnimationPlayer.current_animation == "Attack" and anticipation_finish:
				if target_pos > 0:
					velocity = Vector2(-350, -50)
					scale = Vector2(1,-1)
					rotation = PI
					facing_left = true
				else:
					velocity = Vector2(350, -50)
					scale = Vector2(1,1)
					rotation = 0
					facing_left = false


			if $AnimationPlayer.current_animation == "Attack1_1" and anticipation_finish:
				if target_pos > 0:
					velocity = Vector2(-300, 0)
				else:
					velocity = Vector2(300, 0)

			if $AnimationPlayer.current_animation == "Attack1_2" and anticipation_finish:
				if target_pos > 0:
					velocity = Vector2(-300, -50)
				else:
					velocity = Vector2(300, -50)


			elif $AnimationPlayer.current_animation == "Attack2" and anticipation_finish:
				target_pos = global_position.x - player_position_x
				var target_velocity_x = -200.0 if target_pos > 1 else 200.0
				velocity.x = lerp(velocity.x, target_velocity_x, 6.0 * delta)
			
		if stop_after_attack:
			velocity.x = lerp(velocity.x, 0.0, 8.0 * delta)
			if abs(velocity.x) < 0.1:
				velocity.x = 0.0
				stop_after_attack = false
				
				
			
		if $RayCast2D.is_colliding():
			$RayCast2D.enabled = false
			velocity.x = 0
			is_attacking = true
			
			if attack_pool.size() == 0:
				reset_attack_pool()
				
			var attack_name = attack_pool.pop_front()
			$AnimationPlayer.play(attack_name)
			
		if velocity.x != 0 and is_attacking == false:
			$AnimationPlayer.play("Walk")
			
		move_and_slide()
	
	if phase4:
		if players.size() > 0 and !entrance and skip_cutscene:
			var player = players[0]
			player_position_x = player.global_position.x

			if Chaos and not attack_pool.is_empty():
				if Health <= 200 and Health > 100:
					Chaos = false
					arrow_attack()
					await get_tree().create_timer(1.7).timeout
					Chaos = true
				elif Health <= 100:
					Chaos = false
					arrow_attack()
					arrow_attack()
					await get_tree().create_timer(1.7).timeout
					Chaos = true

			if $AnimationPlayer.current_animation == "":
				$RayCast2D.target_position.x = $RayCast2D.target_position.x*-1
				await get_tree().create_timer(0.3).timeout
			if not is_attacking:
				target_pos = global_position.x - player_position_x
				
			if target_pos > 30 and not is_attacking:
				scale = Vector2(1,-1)
				rotation = PI
				velocity.x = -50
				
			elif target_pos < -30 and not is_attacking:
				scale = Vector2(1,1)
				rotation = 0
				velocity.x = 50
			elif target_pos < 30 and target_pos > -30 and not is_attacking:
				velocity.x = 0
				$AnimationPlayer.play("Idle")
				
			if target_pos > 0 and not is_attacking:
				scale = Vector2(1,-1)
				rotation = PI
			elif target_pos < 0 and not is_attacking:
				scale = Vector2(1,1)
				rotation = 0
				
				
			if $AnimationPlayer.current_animation == "Attack" and anticipation_finish:
				if target_pos > 0:
					velocity = Vector2(-350, -50)
					scale = Vector2(1,-1)
					rotation = PI
					facing_left = true
				else:
					velocity = Vector2(350, -50)
					scale = Vector2(1,1)
					rotation = 0
					facing_left = false


			if $AnimationPlayer.current_animation == "Attack1_1" and anticipation_finish:
				if target_pos > 0:
					velocity = Vector2(-300, 0)
				else:
					velocity = Vector2(300, 0)

			if $AnimationPlayer.current_animation == "Attack1_2" and anticipation_finish:
				if target_pos > 0:
					velocity = Vector2(-300, -50)
				else:
					velocity = Vector2(300, -50)
					
			if $AnimationPlayer.current_animation == "Attack2" and anticipation_finish:
				target_pos = global_position.x - player_position_x
				var target_velocity_x = -200.0 if target_pos > 1 else 200.0
				velocity.x = lerp(velocity.x, target_velocity_x, 6.0 * delta)
				
			if $AnimationPlayer.current_animation == "Jump_attack1":
				target_pos = global_position.x - player_position_x
				if target_pos > 0 and stopper:
					stopper = false
					velocity = Vector2(-1000,-1150)
				elif target_pos <= 0 and stopper:
					stopper = false
					velocity = Vector2(1000,-1150)
				if global_position.y < 71:
					velocity.y = 0
				if abs(target_pos) < 30 :
					velocity = Vector2(0,velocity.y)
					await get_tree().create_timer(0.5).timeout
					$AnimationPlayer.play("Jump_attack2")
					velocity.y = 500
					
			if special:
				special = false
				await get_tree().create_timer(1.0).timeout
				phase2 = true
			if phase2:
				knife_attack()
				phase2 = false
				
			if phase3:
				phase3 = false
				arrow_attack()
				await get_tree().create_timer(1.0).timeout
				arrow_attack()
				await get_tree().create_timer(1.0).timeout
				arrow_attack()
				await get_tree().create_timer(1.0).timeout
				arrow_attack()
				arrow_attack()
				await get_tree().create_timer(1.0).timeout
				arrow_attack()
				arrow_attack()
				await get_tree().create_timer(1.0).timeout
				arrow_attack()
				arrow_attack()
				await get_tree().create_timer(1.0).timeout
				special_end = true
				velocity.y = 0
				
		if stop_after_attack:
			velocity.x = lerp(velocity.x, 0.0, 8.0 * delta)
			if abs(velocity.x) < 0.1:
				velocity.x = 0.0
				stop_after_attack = false
				
		$RayCast2D.target_position.x = 230
		if $RayCast2D.is_colliding():
			$RayCast2D.enabled = false
			velocity.x = 0
			is_attacking = true

			if attack_pool.is_empty() and !special and !special_end:
				special = true
				$AnimationPlayer.play("Jump")
				velocity = Vector2(target_pos,-1000)
				Chaos = false
				await get_tree().create_timer(1.0).timeout
				velocity = Vector2.ZERO
				global_position.x = 1500
				
			var attack_name = attack_pool.pop_front()
			
			if attack_name != null:
				$AnimationPlayer.play(attack_name)
		if attack_pool.is_empty() and special_end and !special and !entrance:
			scale = Vector2(1,-1)
			reset_attack_pool()
			var arrow_instance = arrow_scene.instantiate()  
			get_parent().add_child(arrow_instance)
			arrow_instance.get_child(0).visible = true
			arrow_instance.get_child(0).global_position = Vector2(431, -14)
			arrow_instance.get_child(0).global_rotation = -PI/2
			await get_tree().create_timer(1.0).timeout
			arrow_instance.get_child(0).visible = false
			global_position = Vector2(431,-131)
			velocity.y = 800
			entrance = true
			rotation = PI
			$AnimationPlayer.play("DROPPPPPPP")
			$EntranceTimer.wait_time = 1.75
			$EntranceTimer.start()
			special_end = false
			
		if velocity.x != 0 and is_attacking == false:
			$AnimationPlayer.play("Walk")
			
		move_and_slide()
		

func knife_attack():
	var Random
	if Health <= 100 :
		if player_position_x <= 415:
			Random = rng.randi_range(159,672)
		else: 
			Random = rng.randi_range(490,340)
	else:
		if player_position_x <= 415:
			Random = rng.randi_range(490,672)
		else: 
			Random = rng.randi_range(159,340)
	get_parent().add_child(knife)
	knife.get_child(0).visible = true
	knife.get_child(0).global_position = Vector2(Random,306)
	knife.get_child(1).global_position.x = knife.get_child(0).global_position.x
	if abs(player_position_x - knife.get_child(0).global_position.x) > 350:
		await get_tree().create_timer(1.35).timeout
	else:
		await get_tree().create_timer(0.85).timeout
	knife.get_child(1).get_child(1).get_child(0).monitoring = true
	knife.get_child(1).speed = 1100
	knife.get_child(1).attacking = true
	await get_tree().create_timer(1).timeout
	knife.get_child(1).get_child(1).get_child(0).monitoring = false
	knife.get_child(1).speed = -1500
	knife.get_child(1).attacking = false
	await get_tree().create_timer(0.3).timeout
	if knife_count != 0:
		knife_count -= 1
		knife_attack()
	else:
		knife_count = 2
		phase3 = true
	
func arrow_attack():
	if arrow_pool.size() == 0:
		reset_arrow_pool()
		
	var arrow_variant = arrow_pool.pop_front()
	var arrow_instance = arrow_scene.instantiate()  
	get_parent().add_child(arrow_instance)

	if arrow_variant == 1:
		arrow_instance.get_child(0).visible = true
		arrow_instance.get_child(0).global_position = Vector2(415, 256)
		await get_tree().create_timer(0.5).timeout
		arrow_instance.get_child(0).visible = false
		arrow_instance.get_child(1).global_position = Vector2(780, 256)
		arrow_instance.get_child(1).speed = -500

	elif arrow_variant == 2:
		arrow_instance.get_child(0).visible = true
		arrow_instance.get_child(0).global_position = Vector2(415, 206)
		await get_tree().create_timer(0.5).timeout
		arrow_instance.get_child(0).visible = false
		arrow_instance.get_child(1).global_position = Vector2(780, 206)
		arrow_instance.get_child(1).speed = -500

	elif arrow_variant == 3:
		arrow_instance.get_child(0).visible = true
		arrow_instance.get_child(0).global_position = Vector2(415, 156)
		await get_tree().create_timer(0.5).timeout
		arrow_instance.get_child(0).visible = false
		arrow_instance.get_child(1).global_position = Vector2(780, 156)
		arrow_instance.get_child(1).speed = -500

	elif arrow_variant == 4:
		arrow_instance.get_child(0).visible = true
		arrow_instance.get_child(0).flip_h = true
		arrow_instance.get_child(0).global_position = Vector2(415, 256)
		await get_tree().create_timer(0.5).timeout
		arrow_instance.get_child(0).visible = false
		arrow_instance.get_child(1).get_child(0).flip_h = true
		arrow_instance.get_child(1).global_position = Vector2(95, 256)
		arrow_instance.get_child(1).speed = 500

	elif arrow_variant == 5:
		arrow_instance.get_child(0).visible = true
		arrow_instance.get_child(0).flip_h = true
		arrow_instance.get_child(0).global_position = Vector2(415, 206)
		await get_tree().create_timer(0.5).timeout
		arrow_instance.get_child(0).visible = false
		arrow_instance.get_child(1).get_child(0).flip_h = true
		arrow_instance.get_child(1).global_position = Vector2(95, 206)
		arrow_instance.get_child(1).speed = 500

	elif arrow_variant == 6:
		arrow_instance.get_child(0).visible = true
		arrow_instance.get_child(0).flip_h= true
		arrow_instance.get_child(0).global_position = Vector2(415, 156)
		await get_tree().create_timer(0.5).timeout
		arrow_instance.get_child(0).visible = false
		arrow_instance.get_child(1).get_child(0).flip_h = true
		arrow_instance.get_child(1).global_position = Vector2(95, 156)
		arrow_instance.get_child(1).speed = 500
	await get_tree().create_timer(10).timeout
	arrow_instance.queue_free()
func reset_arrow_pool():
	arrow_pool = [1,1,2,3,4,4,5,6]
	arrow_pool.shuffle()

func reset_attack_pool():
	if !phase4:
		attack_pool = ["Attack", "Attack2"]
		attack_pool.shuffle()
	elif phase4:
		attack_pool = ["Jump_attack1","Attack","Jump_attack1","Attack2"]
		attack_pool.shuffle()

func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	if Health > 0:
		if anim_name == "Attack2":
			velocity.x = 0.0
			is_attacking = false
			$Cooldown.start()
		if anim_name == "Attack":
			velocity.x = 0.0
			$Atk1timer.start()
		if anim_name == "Attack1_2":
			velocity.x = 0.0
			is_attacking = false
			$Cooldown.start()
			$AnimationPlayer.play("Idle")
			
		if anim_name == "Attack1_1":
			velocity.x = 0.0
			is_attacking = false
			$Cooldown.start()
			$AnimationPlayer.play("Idle")

		if anim_name == "Entrance":
			$AnimationPlayer.play("Idle")
			
		if anim_name == "Jump_attack2":
				$Cooldown.start()
				is_attacking = false
				stopper = true
				$AnimationPlayer.play("Entrance")
				
func _on_cooldown_timeout() -> void:
	$RayCast2D.enabled = true


func _on_atk_1_timer_timeout() -> void:
	target_pos = global_position.x - player_position_x
	if facing_left == false and target_pos < 0 :
		$AnimationPlayer.play("Attack1_1")
	elif facing_left == true and target_pos > 0 :
		$AnimationPlayer.play("Attack1_1")
	elif facing_left == false and target_pos > 0 :
		$AnimationPlayer.play("Attack1_2")
	elif facing_left == true and target_pos < 0 :
		$AnimationPlayer.play("Attack1_2")


func _on_entrance_timer_timeout() -> void:
	entrance = false
	$RayCast2D.enabled = true
	if phase4:
		await get_tree().create_timer(0.8).timeout
		Chaos = true

func _on_hurtbox_area_entered(area: Area2D) -> void:
	if area.name == "PlayerHitbox" and not invinc:
		invinc = true
		Health -=6
		$AnimationPlayer2.play("Flash")
		Hitstop(0.05,0.05)
		var color = Color()
		$Sprite2D.self_modulate = color
		await get_tree().create_timer(0.2).timeout
		$AnimationPlayer2.play("Flash")
		Health -=6
		await get_tree().create_timer(0.4).timeout
		invinc = false

func Hitstop(timescale, duration):
	Engine.time_scale = 0
	await(get_tree().create_timer(duration, true, false, true).timeout)
	Engine.time_scale = 1


func _on_earth_slam_timeout() -> void:
	$Explosion.EarthSlam()
	get_parent().screen_shake(3, 0.25, 0.02) # call shake in parent scene
	
