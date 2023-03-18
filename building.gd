extends Area2D


@export var PRESS_DELAY = 0.5
var press_timer = Timer.new()

func _ready() -> void:
	press_timer.timeout.connect(_onPress)
	press_timer.one_shot = true
	add_child(press_timer)

#func _process(delta: float) -> void:
#	print(get_viewport_transform().origin)

func _on_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event.is_pressed():
		if press_timer.is_stopped():
			press_timer.start(PRESS_DELAY)
	else:
		press_timer.stop()


func _onPress():
	print(self.name)
#	Globals.pick_expansion.emit(position)


func _on_mouse_entered() -> void:
	Globals.is_cursor_on_occupied = true


func _on_mouse_exited() -> void:
	Globals.is_cursor_on_occupied = false


func _on_body_entered(body: Node2D) -> void:
	print(body.name)


func _on_area_entered(area: Area2D) -> void:
	Globals.is_cursor_on_occupied = true
#	prints(12,area.name)


func _on_area_exited(area: Area2D) -> void:
	Globals.is_cursor_on_occupied = false
