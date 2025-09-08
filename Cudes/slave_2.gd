extends CharacterBody2D

var seen_player = false
var got_passed = false
var freed = false
var ignored = false
var reached_door = false
var infront_of_player = false
var out_of_jail = false
var end_point = false
var player_position_x
var animation_number = 0
@export var speed = 125
var jail_3 := false
var beheaded := false
var ended
var Death = false

@export var char_delay := 0.05 
var _typing := false
var type_cooldown := false
var _dialogue_finished := false
var has_talk1_played := false
var has_talk2_played := false
var has_talk3_played := false
var _waiting_next := false
var label_origin := Vector2.INF
@onready var lablel_pos_y = $Label.global_position.y
var Ui_mike = false

func _ready() -> void:
	pass

func _physics_process(delta: float) -> void:
	if not seen_player and animation_number == 0:
		if $AnimationPlayer.current_animation != "setting":
			$AnimationPlayer.play("setting")
	elif seen_player and animation_number == 0:
		if $AnimationPlayer.current_animation != "setting_top":
			$AnimationPlayer.play("setting_top")
			animation_number = 1

	if got_passed and animation_number == 1:
		if $AnimationPlayer.current_animation != "Wave":
			$AnimationPlayer.play("Wave")
			animation_number = 2

	if freed and animation_number == 2:
		if $AnimationPlayer.current_animation != "Get_up":
			$AnimationPlayer.play("Get_up")
			animation_number = 3

	if ignored and animation_number == 2:
		$AnimationPlayer.play("Wave2")
		shake_label()

	if reached_door and not infront_of_player and animation_number == 3:
		$AnimationPlayer.play("RESET")
		z_index = 1
		$AnimatedSprite2D.flip_h = false
		velocity.x = 0
		$Timer.start()
		animation_number = 4

	if get_tree().get_nodes_in_group("PlayerC").size() > 0 and jail_3 == false:
		player_position_x = get_tree().get_nodes_in_group("PlayerC")[0].global_position.x

		if player_position_x - global_position.x > 10 and (_typing or not $Timer2.is_stopped()):
			$AnimatedSprite2D.flip_h = false
		elif player_position_x - global_position.x < -10 and (_typing or not $Timer2.is_stopped()):
			$AnimatedSprite2D.flip_h = true

		if abs(global_position.x - player_position_x) < 80 and reached_door:
			velocity.x = 0
			infront_of_player = true
		else:
			infront_of_player = false

		if not _typing and not infront_of_player and out_of_jail and animation_number < 7 and not type_cooldown:
			if player_position_x - global_position.x > 70:
				velocity.x = speed
				$AnimationPlayer.play("Walk")
				$AnimatedSprite2D.flip_h = false
			elif player_position_x - global_position.x < -70:
				velocity.x = -speed
				$AnimationPlayer.play("Walk")
				$AnimatedSprite2D.flip_h = true
			else:
				velocity.x = 0
		elif _typing or infront_of_player or animation_number >= 7:
			velocity.x = 0

	if freed and infront_of_player and animation_number == 4 and not has_talk1_played:
		has_talk1_played = true
		$AnimationPlayer.play("Talk1")
		velocity.x = 0

	elif freed and infront_of_player and animation_number == 5 and not has_talk2_played:
		has_talk2_played = true
		$AnimationPlayer.play("Talk2")
		velocity.x = 0

	elif freed and infront_of_player and animation_number == 6 and not has_talk3_played:
		has_talk3_played = true
		$AnimationPlayer.play("Talk3")
		velocity.x = 0

	elif freed and animation_number == 7 and not end_point:
		$AnimationPlayer.play("RESET")
		velocity.x = 0

	if freed and animation_number == 8 and not end_point:
		if player_position_x - global_position.x > 50:
			velocity.x = speed
			$AnimationPlayer.play("Walk")
			$AnimatedSprite2D.flip_h = false

		elif player_position_x - global_position.x < -50:
			velocity.x = -speed
			$AnimationPlayer.play("Walk")
			$AnimatedSprite2D.flip_h = true
		else:
			$AnimationPlayer.play("RESET")

	move_and_slide()

	if jail_3:
		if not beheaded and not Death:
			$AnimationPlayer.play("Talk4")
		elif Death and not beheaded:
			$AnimationPlayer.play("WalkHappy")
			velocity.x = speed
			shake_label()
			$Label.scale = Vector2(1.5, 1.5)
		elif beheaded and not ended:
			$AnimationPlayer.play("WalkHappy_2")
			velocity.x = speed
		elif beheaded and ended:
			velocity.x = 0
			global_position.y =global_position.y + 1
			set_physics_process(false)
			$Slave2Area/CollisionShape2D.disabled = true

func show_flying_text(lines: Array[String]) -> void:
	if _typing:
		return
	_typing = true
	_dialogue_finished = false
	$Label.text = ""
	velocity.x = 0
	await _type_lines(lines)
	_typing = false
	_dialogue_finished = true
	_waiting_next = true
	$Timer2.start()

func _type_lines(lines: Array[String]) -> void:
	var full_text := ""
	for line in lines:
		for i in range(line.length()):
			full_text += line[i]
			$Label.text = full_text
			await get_tree().create_timer(char_delay).timeout
		full_text += "\n"
		$Label.text = full_text
		await get_tree().create_timer(char_delay).timeout

func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	if anim_name == "Get_up":
		$AnimatedSprite2D.flip_h = true
		$AnimationPlayer.play("Walk")
		velocity.x = -speed

	elif anim_name == "RESET" and animation_number == 7:
		animation_number = 8

	elif anim_name == "WalkHappy_2":
		ended = true
	elif anim_name == "Talk3":
		await get_tree().create_timer(4.6).timeout
		$Label2.text = "Mike dyson joins the party"
		party()
		Ui_mike = true

func party():
	var label := $Label2
	var tween := create_tween()

	# Move label up by 50 pixels
	tween.tween_property(label, "position:y", label.position.y - 25, 1.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

	# Fade out (modulate.a = alpha)
	tween.tween_property(label, "modulate:a", 0.0, 1.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)

	# When finished, reset the label if you want
	tween.tween_callback(func():
		label.modulate.a = 1.0
		label.position.y = label_origin.y
		label.text = ""
	)

	
	
func _on_timer_timeout() -> void:
	$Timer.stop()
	if infront_of_player:
		velocity.x = 0
		out_of_jail = true
	else:
		velocity.x = speed
		out_of_jail = true
		$AnimationPlayer.play("Walk")

func _on_animation_player_animation_started(anim_name: StringName) -> void:
	if anim_name == "Wave2":
		show_flying_text(["HEEEEY DONT LEAVE ME HERE!!!"])
		type_cooldown = true
	if anim_name == "Talk1":
		show_flying_text(["I Can't Believe it!"])
		type_cooldown = true
		velocity.x = 0
	if anim_name == "Talk2":
		show_flying_text(["Thank you so much!"])
		type_cooldown = true
		velocity.x = 0
	if anim_name == "Talk3":
		show_flying_text(["I will remember you for the rest of my life!"])
		type_cooldown = true
		velocity.x = 0
	if anim_name == "Talk4":
		show_flying_text(["Finally after all those years"])
		type_cooldown = true
		velocity.x = 0
	if anim_name == "WalkHappy" and $".".global_position.x < 90:
		show_flying_text(["FREEDOM!!!"])
		
func _on_timer_2_timeout() -> void:
	type_cooldown = false
	$Label.text = ""
	if _waiting_next:
		_waiting_next = false
		if animation_number == 4:
			animation_number = 5
		elif animation_number == 5:
			animation_number = 6
		elif animation_number == 6:
			animation_number = 7
			$Label.text = ""
		if jail_3 :
			Death = true
			

# 🎯 Godot 4.x-compatible Label Shake
func shake_label():
	var label := $Label

	# Store true anchor once
	if label_origin == Vector2.INF:
		label_origin = label.position

	var tween := create_tween()
	tween.set_parallel(false)

	var shake_amount := 2
	var shake_speed := 0.025
	var iterations := 8

	for i in range(iterations):
		var offset := Vector2(
			randf_range(-shake_amount, shake_amount),
			randf_range(-shake_amount, shake_amount)
		)
		tween.tween_property(label, "position", label_origin + offset, shake_speed)
		tween.tween_property(label, "position", label_origin, shake_speed)
