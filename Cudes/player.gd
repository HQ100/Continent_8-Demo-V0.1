extends CharacterBody2D

var speed = 320 
var forcewalk = false
var can_dash = true
const JUMP_VELOCITY = -385
var target_velocity = Vector2.ZERO
var last_direction = Vector2(0,0)
var dash_direction
var dash_speed = 650
var dashing = false
var frozen = false
var was_on_floor = false
var walking = false
var camera = true
var cooldown = false
var Health = 3
var invinc
var Inputs = true
# Coyote time variables
var coyote_time = 0.1
var coyote_timer = 0.0

func _ready() -> void:
	print("im handsome")

func _physics_process(delta):
	move_and_slide()
	if Inputs:
		if not dashing:
			if walking:
				velocity.x = lerp(velocity.x, target_velocity.x/2, 11*delta)
			else:
				velocity.x = lerp(velocity.x, target_velocity.x, 11*delta)
		
		if Health == 0:
			queue_free()
			
		if camera:
			$Camera2D.enabled = true
		else:
			$Camera2D.enabled = false

		if frozen:
			velocity = Vector2.ZERO
			move_and_slide()
			return
		
		# Apply gravity if in air
		if not is_on_floor() and !dashing:
			velocity += get_gravity() * delta
			$AnimationPlayer.play("Jump")
			
		var is_on_floor_now = is_on_floor()
		if not is_on_floor():
			was_on_floor = false
		if is_on_floor_now and not was_on_floor:
			$AnimationPlayer.play("Land")
		was_on_floor = is_on_floor_now
		
		# Update coyote timer
		if is_on_floor():
			coyote_timer = coyote_time
		else:
			coyote_timer -= delta

		# Jump with coyote time
		if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and not cooldown:
			$PlayerHitbox/CollisionShape2D.disabled = false
			$AnimationPlayer.play("Attack")
			cooldown = true
			$Timer.start()
			$Cooldown.start()
		if Input.is_action_just_pressed("W") and coyote_timer > 0 and !dashing:
			velocity.y = JUMP_VELOCITY
			coyote_timer = 0

		var input_direction = Input.get_action_strength("D") - Input.get_action_strength("A")
		target_velocity.x = input_direction * speed
		
	
		if Input.is_action_pressed("D"):
			$".".rotation = 0
			$".".scale = Vector2(1,1)
		elif Input.is_action_pressed("A"):
			$".".rotation = PI
			$".".scale = Vector2(1,-1)
			
		if Input.is_action_pressed("Shift") or forcewalk == true:
			walking = true
		else:
			walking = false
			
		if walking and input_direction != 0 and is_on_floor() and !dashing and $AnimationPlayer.current_animation != "Land" and $AnimationPlayer.current_animation != "Attack":
			$AnimationPlayer.play("UnarmedWalk")
		elif not walking and input_direction != 0 and is_on_floor() and !dashing and $AnimationPlayer.current_animation != "Land" and $AnimationPlayer.current_animation != "Attack":
			$AnimationPlayer.play("Run")
		if is_on_floor() and !dashing and $AnimationPlayer.current_animation != "Land" and target_velocity.x == 0 and forcewalk == false and $AnimationPlayer.current_animation != "Attack":
			$AnimationPlayer.play("UnarmedIdle")
		elif is_on_floor() and !dashing and $AnimationPlayer.current_animation != "Land" and target_velocity.x == 0 and forcewalk == true and $AnimationPlayer.current_animation != "Attack":
			$AnimationPlayer.play("UnarmedIdle2")
			
		if Input.is_action_pressed("D"):
			last_direction = Vector2(1, last_direction.y)
		elif Input.is_action_pressed("A"):
			last_direction = Vector2(-1, last_direction.y)
		else:
			last_direction = Vector2(0, last_direction.y)
			
		if Input.is_action_pressed("W"):
			last_direction = Vector2(last_direction.x, -1)
		elif Input.is_action_pressed("S"):
			last_direction = Vector2(last_direction.x, 1)
		else:
			last_direction = Vector2(last_direction.x, 0) 
			 
		if Input.is_action_just_pressed("ui_accept") and can_dash:
			can_dash = false
			dashing = true
			$AnimationPlayer.play("Dash")
			if last_direction != Vector2(0,0):
				dash_direction = last_direction.normalized()
			else:
				if rotation == 0:
					dash_direction = Vector2(1,0)
				else:
					dash_direction = Vector2(-1,0)
			velocity = dash_direction * dash_speed 
			$PlayerHurtbox/CollisionShape2D.disabled = true
			if dash_direction != Vector2(0,dash_direction.y):
				$DashP1.visible = true
				$DashP2.visible = true 
				$DashP3.visible = true 
			await get_tree().create_timer(0.2).timeout
			dashing = false
			frozen = true 
			$DashP1.visible = false
			$DashP2.visible = false
			$DashP3.visible = false
			await get_tree().create_timer(0.01).timeout  
			frozen = false
			$PlayerHurtbox/CollisionShape2D.disabled = false
			if Input.is_action_pressed("D") or Input.is_action_pressed("A"):
				velocity = dash_direction * speed 
				velocity.y = 0
			await get_tree().create_timer(0.55).timeout
			can_dash = true
		
func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	if anim_name == ("Attack"):
		$AnimationPlayer.play("UnarmedIdle")

func _on_timer_timeout() -> void:
	$PlayerHitbox/CollisionShape2D.disabled = true

func _on_cooldown_timeout() -> void:
	cooldown = false

func Hitstop(timescale, duration):
	Engine.time_scale = 0
	await(get_tree().create_timer(duration, true, false, true).timeout)
	Engine.time_scale = 1

func _on_player_hurtbox_area_entered(area: Area2D) -> void:
	if not invinc:
		Health -=1
		$Explosion.Blood()
		Hitstop(0.05,0.10)
		invinc = true
		$invincibility.start()

func _on_invincibility_timeout() -> void:
	invinc = false
