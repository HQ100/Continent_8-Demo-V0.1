extends Node2D

var start = false
var cinema = false

func _ready() -> void:
	# Start the flashes asynchronously (non-blocking)
	call_deferred("play_white_flashes", 2, 0.75, 0.15, 0.1)

	$VideoStreamPlayer.play()

func _physics_process(delta: float) -> void:
	if start:
		start = false
		for child in $Lines.get_children():
			var tween = get_tree().create_tween()
			tween.tween_property(child, "self_modulate:a", 1.0, 0.2)
			await tween.finished
			await get_tree().create_timer(0.3).timeout 
		await get_tree().create_timer(0.2).timeout
		CameraZoom()


func CameraZoom():
	var cam = $Camera2D
	var tween = get_tree().create_tween()

	# Zoom in
	tween.tween_property(cam, "zoom", Vector2(50, 50), 7.5)

	# Offset tweens (separate x & y but same duration so they sync perfectly)
	tween.parallel().tween_property(cam, "offset:x", 192, 0.75)
	tween.parallel().tween_property(cam, "offset:y", 55, 0.75)

	# Smooth easing
	tween.set_trans(Tween.TRANS_LINEAR)

	await get_tree().create_timer(2).timeout

	# Fade in black screen
	var fade_tween = get_tree().create_tween()
	fade_tween.tween_property($BlackFade, "self_modulate:a", 1.0, 1.5)


func _on_video_stream_player_finished() -> void:
	$"3Dlevel1".visible = true
	await get_tree().create_timer(1.0).timeout
	start = true


# --- WHITE FLASH FUNCTION (ASYNC, NON-BLOCKING) ---
func play_white_flashes(flashes: int = 2, alpha: float = 0.75, flash_duration: float = 0.2, wait_duration: float = 0.1) -> void:
	var flash = ColorRect.new()
	flash.color = Color(1, 1, 1, 0.0)
	flash.size = get_viewport_rect().size
	flash.z_index = 50
	add_child(flash)

	# Start coroutine without blocking
	_flash_sequence(flash, flashes, alpha, flash_duration, wait_duration)


# --- ACTUAL FLASH SEQUENCE ---
func _flash_sequence(flash: ColorRect, flashes: int, alpha: float, flash_duration: float, wait_duration: float) -> void:
	# Use an async loop with await internally
	for i in range(flashes):
		var t := 0.0
		# fade in
		while t < flash_duration:
			t += get_process_delta_time()
			flash.color.a = lerp(0.0, alpha, t / flash_duration)
			await get_tree().process_frame
		# hold
		await get_tree().create_timer(wait_duration).timeout
		# fade out
		t = 0.0
		while t < flash_duration:
			t += get_process_delta_time()
			flash.color.a = lerp(alpha, 0.0, t / flash_duration)
			await get_tree().process_frame
		flash.color.a = 0.0

	flash.queue_free()
