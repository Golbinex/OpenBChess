extends PopupPanel

func open(txt: String, duration, window_size):
	$c/Label.text = txt
	popup_centered(window_size)
	if duration != 0:
		$Timer.start(duration)


func _on_Timer_timeout():
	hide()
