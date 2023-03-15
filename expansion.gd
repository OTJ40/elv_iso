extends Area2D


func _on_input_event(_viewport: Node, _event: InputEvent, _shape_idx: int) -> void:
	if _event.is_action_released("ui_accept"):
#		print(self)
		GlobalSignal.pick_expansion.emit(position)

#func eee():
#	for n in get_tree().get_nodes_in_group("expansions"):
#		if n == self:
#			print(346,n)
