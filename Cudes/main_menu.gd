extends Node2D

var backstory_scene = preload("res://Scenes/backstory_2.tscn")
var color = Color(1,1,1,1)
var attack_button = "J"
var jump_button = "W"
var Dash_button = "space"
var can_be_pressed = true
var _bg2 = preload("res://Assets/Environment/Jail/JailBg2-Sheet.png")

func _ready() -> void:
	$Menu/AnimationPlayer.play("1")
	RenderingServer.set_default_clear_color(Color.BLACK)
	$Options.visible = false
	
	
func _physics_process(delta: float) -> void:
	$Options/Label3/Ui_Key.get_child(0).self_modulate = color
	$Options/Label3/Ui_Key.letter = attack_button
	
	$Options/Label4/Ui_Key.get_child(0).self_modulate = color
	$Options/Label4/Ui_Key.letter = jump_button
	
	$Options/Label5/Ui_Key.get_child(0).self_modulate = color
	$Options/Label5/Ui_Key.letter = Dash_button

func _on_texture_button_mouse_entered() -> void:
	if can_be_pressed:
		$Menu/TextureButton/ColorRect.visible = true


func _on_texture_button_3_mouse_entered() -> void:
	if can_be_pressed:
		$Menu/TextureButton3/ColorRect3.visible = true


func _on_texture_button_mouse_exited() -> void:
	$Menu/TextureButton/ColorRect.visible = false


func _on_texture_button_3_mouse_exited() -> void:
	$Menu/TextureButton3/ColorRect3.visible = false


func _on_texture_button_pressed() -> void:
	can_be_pressed = false
	$Menu/TextureButton.global_position.y += 1
	await get_tree().create_timer(0.1).timeout
	$Menu/TextureButton.global_position.y -=1
	#sound plays
	await get_tree().create_timer(0.2).timeout
	$Menu/AnimationPlayer.play("3")
	await get_tree().create_timer(0.4).timeout
	$Menu/AnimationPlayer.play("new_animation")

func _on_texture_button_3_pressed() -> void:
	if can_be_pressed:
		$Menu/TextureButton3.global_position.y += 1
		await get_tree().create_timer(0.1).timeout
		$Menu/TextureButton3.global_position.y -=1
		$Menu.visible = false
		$Options.visible = true

func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	if anim_name == "new_animation":
		$Menu/AnimationPlayer.play("2")
	if anim_name == "2":
		await get_tree().create_timer(1).timeout
		$BlackFade.visible = true
		$BlackFade.color.a = 0.0
		var tween := create_tween()
		tween.tween_property($BlackFade, "color:a", 1.0, 1.5)
		await get_tree().create_timer(1.3).timeout
		get_tree().change_scene_to_file("res://Scenes/backstory_2.tscn")


func _on_texture_button_5_mouse_entered() -> void:
	$Options/TextureButton5/ColorRect.visible = true


func _on_texture_button_5_mouse_exited() -> void:
	$Options/TextureButton5/ColorRect.visible = false


func _on_texture_button_5_pressed() -> void:
	$Options.visible = false
	$Menu.visible = true
