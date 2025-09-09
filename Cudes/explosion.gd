extends Node2D

func Blood():
	$Blood.emitting = false  
	$Blood.restart()   

func Explode():
	$Explode.emitting = false
	$Explode.restart()

func EarthSlam():
	$EarthSlam.emitting = false
	$EarthSlam2.emitting = false
	$EarthSlam3.emitting = false
	
	$EarthSlam.restart()
	$EarthSlam2.restart()
	$EarthSlam3.restart()
	
func Blood2():
	$Blood2.emitting = false
	$Blood2.restart()
