extends Area2D


func _on_area_entered(area: Area2D) -> void:
	if area.name == "DragBuilding":
		Globals.counter += 1


func _on_area_exited(area: Area2D) -> void:
	if area.name == "DragBuilding":
		Globals.counter -= 1
