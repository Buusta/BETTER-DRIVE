extends SubViewport


func _input(event: InputEvent) -> void:
	print(event)

func pressed(toggle: bool):
	print('woow ', toggle)
