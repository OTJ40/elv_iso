extends Area2D

@export var PRESS_DELAY = 0.1
var press_timer = Timer.new()

func _ready() -> void:
	press_timer.timeout.connect(_onPress)
	press_timer.one_shot = true
	add_child(press_timer)

func _on_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event.is_pressed():
		if press_timer.is_stopped():
			press_timer.start(PRESS_DELAY)
	else:
		press_timer.stop()


func _onPress():
	Globals.pick_expansion.emit(position)


func _on_area_entered(area: Area2D) -> void:
	if Globals.exit:
		Globals.enter = true
	else:
		Globals.enter = false


func _on_area_exited(area: Area2D) -> void:
	if Globals.enter:
		Globals.exit = true
	else:
		Globals.exit = false
