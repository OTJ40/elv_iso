extends Node2D


enum BUILDING_TYPE{
	ROAD,
	MAIN_HALL,
	HOUSE,
	WORKSHOP
}

var build_mode = false
var sell_mode = false
var move_mode = false
var drag_mode = false
var expanse_mode = false
var dialog_mode = false

var mouse_pressing = false
var is_first_time = true
var has_painted_building = false
var has_lands_preview = false
var place_valid = false

const LIMIT = 300
var half_camera_rect = Vector2i()
var zoom_factor = 1.0
var buildings_data_array = []
var own_lands_array = []
var own_lands_array_ortho = [
		Vector2i(10, 0),
		Vector2i(15, 0),
		Vector2i(10, 5),
		Vector2i(15, 5),
		Vector2i(10, 10),
		Vector2i(15, 10),
		]
var for_sale_lands_array = []
var file_manager: FileManager = FileManager.new()

var build_type
var build_location

var sell_cursor
var move_cursor
var default_cursor

var whitey = preload("res://scenes/white.tscn").instantiate()


var even_directions = [
	Vector2i(2,-5),
	Vector2i(2,5),
	Vector2i(-3,5),
	Vector2i(-3,-5)
	]

var odd_directions = [
	Vector2i(3,-5),
	Vector2i(3,5),
	Vector2i(-2,5),
	Vector2i(-2,-5)
	]


func _ready() -> void:
	Globals.play_mode = true
	
	$CameraManager.limit_bottom = 4 * LIMIT # 2000
	$CameraManager.limit_left = -4 * LIMIT # -2000
	$CameraManager.limit_right = 6 * LIMIT # 3000
	$CameraManager.limit_top = -3 * LIMIT # -1500

	load_config()
	if is_first_time:
		build_main_hall()
	else:
		load_from_buildings_data_file()
	update_map()
	
	default_cursor = load("res://assets/ui/default_cursor_32.png")
	move_cursor = load("res://assets/ui/move_cursor_32.png")
	sell_cursor = load("res://assets/ui/sell_cursor_32.png")
	DisplayServer.cursor_set_custom_image(default_cursor)
	for b in get_tree().get_nodes_in_group("menu_buttons"):
		b.pressed.connect(init_menu_mode.bind(b))
	for b in get_tree().get_nodes_in_group("build_buttons"):
		b.pressed.connect(init_build_mode.bind(b))



func _process(_delta: float) -> void:
	var current_cell = $Ortho/OrthoLand.local_to_map(get_global_mouse_position())
#	print(current_cell)
#	print(Globals.counter)
	Globals.is_cursor_on_occupied = false if Globals.counter == 0 else true
#	print(idle_mode,build_mode,expanse_mode,move_mode)
	if build_mode or drag_mode:
		update_building_preview()
	show_modes()

func get_iso_array(base: Vector2i,dims: Vector2i):
	var result = []
	for w in range(dims.x):
		for h in range(dims.y):
			result.append(get_iso_coord(base,Vector2i(w,h)))
	return result

func get_iso_coord(base,offset):
	var result = base
	for w in range(offset.x):
		if absi(result.y % 2) == 1:
			result += Vector2i(1,1)
		else:
			result += Vector2i(0,1)
	for h in range(offset.y):
		if absi(result.y % 2) == 1:
			result += Vector2i(0,1)
		else:
			result += Vector2i(-1,1)
	return result

func show_modes():
	var text = ""
	if build_mode:
		text += "build_mode / "
	if sell_mode:
		text += "sell_mode / "
	if move_mode:
		text += "move_mode / "
	if drag_mode:
		text += "drag_mode / "
	if expanse_mode:
		text += "expanse_mode / "
	if dialog_mode:
		text += "dialog_mode / "
	if Globals.play_mode:
		text += "play_mode / "
	
	$UI/HUD/DebugLabel.text = text

func _unhandled_input(event: InputEvent) -> void:
	if Globals.play_mode:
		if event.is_action_released("ui_accept"):
			var current_cell = get_global_mouse_position()
	
	if build_mode:
		if event.is_action_released("ui_accept"):
			place_building()
			if build_type != "Road":
				cancel_build_mode()
				$Iso/IsoBase.modulate = Color(1,1,1,1)
		if event.is_action_released("ui_cancel"):
			cancel_build_mode()
			$Iso/IsoBase.modulate = Color(1,1,1,1)
	
	if move_mode:
		
		if !has_lands_preview:
			show_lands_for_sale()
			expanse_mode = true
			has_lands_preview = true
		if event.is_action_released("ui_accept"):
			var current_cell = $Iso/IsoLand.local_to_map(get_global_mouse_position())
			print("move",current_cell)
			if $Iso/IsoRoads.get_used_cells(0).has(current_cell):
				pass
#				for item in buildings_data_array:
#					for pos in get_atlas_positions_array_from_dims(item["dims"],item["base"]):
#						if current_cell == pos:
#							erase_building("Yes",item)
#							$UI.set_building_preview(item["type"], get_global_mouse_position())
#							build_type = item["type"]
#							drag_mode = true
#
#			elif has_point_in_for_sale_lands(current_cell):
#				expanse_mode = true
	
	if expanse_mode:
		pass
	
	if event is InputEventMouseMotion and not dialog_mode:
		mouse_pressing = Input.get_action_strength("ui_accept")
		if mouse_pressing:
			Globals.play_mode = false
			$CameraManager.position.x = clamp(
				$CameraManager.position.x,
				$CameraManager.limit_left + half_camera_rect.x,
				$CameraManager.limit_right - half_camera_rect.x
				)
			$CameraManager.position.y = clamp(
				$CameraManager.position.y,
				$CameraManager.limit_top + half_camera_rect.y,
				$CameraManager.limit_bottom - half_camera_rect.y
				)
			$CameraManager.position -= event.relative * zoom_factor
	else:
		Globals.play_mode = true
	
#	if event is InputEventMouseButton:
#		half_camera_rect = get_viewport_rect().size * zoom_factor * 0.5
#			if event.is_pressed():


func place_building():
	if place_valid:
		# -1- prepare dictionary
		var dict = {}
		var dims = get_build_dims()
		var connected = true
#		if build_type == "Road":
#			connected = is_road_connected_to_MH(build_location)
#		elif build_type == "Main_Hall":
#			connected = true
#		else:
#			connected = get_connected_for_building_to_place(dims)
		dict = {
			"id": str(Time.get_unix_time_from_system()).split(".")[0],
			"type": build_type,
			"base": build_location,
			"level": 1,
			"dims": dims,
			"connected": connected,
			"last_coll": str(0) if build_type == "Road" else str(Time.get_unix_time_from_system()).split(".")[0]
		}
		# -2- place building
		if build_type == "Road":
			$Iso/IsoRoads.set_cells_terrain_connect(0,[build_location],0,0,false)
		else:
			var building_instance = load("res://scenes/" + build_type.to_lower() + ".tscn").instantiate()
			building_instance.position = $Iso/IsoLand.map_to_local(build_location)
			$Iso/BuildingS.add_child(building_instance)
#			for cell in get_atlas_positions_array_from_dims(dims,build_location):
#				if connected:
#					$Buildings.set_cell(0,cell,BUILDING_TYPE[build_type.to_upper()],Vector2i(0,0)+cell)
#				else:
#					$Buildings.set_cell(0,cell,BUILDING_TYPE[build_type.to_upper()]+2,Vector2i(0,0)+cell)
		buildings_data_array.append(dict)
		# -3- save changes
		file_manager.save_to_file("buildings_data", buildings_data_array)
#	update_map()

func cancel_build_mode():
	$Iso/IsoCells.visible = false
	place_valid = false
	build_mode = false
	get_node("Iso/BP/BuildingPreview").queue_free()
	$UI/HUD/BuildButtons.visible = true
	$UI/HUD/DoneButton.visible = true

func init_menu_mode(btn):
	match btn.name:
		"BuildButton":
			$UI/HUD/BuildButtons.visible = true
			$UI/HUD/Menu.visible = false
			$UI/HUD/DoneButton.visible = true
		"SellButton":
			DisplayServer.cursor_set_custom_image(sell_cursor)
			sell_mode = true
			$UI/HUD/Menu.visible = false
			$UI/HUD/DoneButton.visible = true
		"MoveButton":
			move_mode = true
			$Iso/IsoCells.visible = true
			DisplayServer.cursor_set_custom_image(move_cursor)
			$UI/HUD/Menu.visible = false
			$UI/HUD/DoneButton.visible = true
		"ResearchButton":
			pass
		"WorldMapButton":
			pass
		"InventoryButton":
			pass

func build_main_hall():
	own_lands_array = [
		Vector2i(10, 0),
		Vector2i(12, 5),
		Vector2i(7, 5),
		Vector2i(10, 10),
		Vector2i(5, 10),
		Vector2i(7, 15),
		]
	own_lands_array_ortho = [
		Vector2i(10, 0),
		Vector2i(15, 0),
		Vector2i(10, 5),
		Vector2i(15, 5),
		Vector2i(10, 10),
		Vector2i(15, 10),
		]
	var mh = load("res://scenes/main_hall.tscn").instantiate()
	mh.position = $Iso/IsoLand.map_to_local(Vector2i(10, 0))
	var mh_dict = {
				"id": str(Time.get_unix_time_from_system()).split(".")[0],
				"type": "Main_Hall",
				"base": Vector2i(10,0),
				"level": 1,
				"dims": Vector2i(6,7),
				"connected": true,
				"last_coll": str(Time.get_unix_time_from_system()).split(".")[0]
	}
	buildings_data_array.append(mh_dict)
	$Iso/BuildingS.add_child(mh)
	
	file_manager.save_to_file("buildings_data",buildings_data_array)
	file_manager.save_to_file("lands_data",own_lands_array)
	file_manager.save_to_file("config","not_first_time")

func load_from_buildings_data_file() :
	var content: Array = file_manager.load_from_file("buildings_data") as Array
	buildings_data_array.clear()
	buildings_data_array.append_array(content)
	
	content = file_manager.load_from_file("lands_data") as Array
	own_lands_array.clear()
	own_lands_array.append_array(content)

func update_building_preview():
	var current_cell = $Iso/IsoBase.local_to_map(get_global_mouse_position())
	var current_cell_in_px = Vector2i($Iso/IsoBase.map_to_local(current_cell))
#	print(current_cell_in_px)
	var count_cells = 0
	for w in get_build_dims().x:
		for h in get_build_dims().y:
			var cell = current_cell_in_px +  w * Vector2i(32,16) + h * Vector2i(-32,16)
			if is_cell_legal_to_place(cell):
				count_cells += 1
	if count_cells == get_build_dims().x * get_build_dims().y and not Globals.is_cursor_on_occupied:
		place_valid = true
		build_location = current_cell
		update_building_previe(current_cell_in_px,Vector2i($CameraManager.position),"33fd146b")
	else:
		place_valid = false
		update_building_previe(current_cell_in_px,Vector2i($CameraManager.position),"f600039c")

func get_build_dims():
	match build_type:
		"Main_Hall":
			return Vector2i(6,7)
		"Resa":
			return Vector2i(2,2)
		"Work":
			return Vector2i(2,2)
		"Road":
			return Vector2i(1,1)

func is_cell_legal_to_place(cell: Vector2i) -> bool:
	return $Iso/IsoLand.get_used_cells(0).has($Iso/IsoLand.local_to_map(cell))

func init_build_mode(btn):
	build_mode = true
	Globals.play_mode = false
	build_type = btn.name
	$Iso/IsoCells.visible = true
	$UI/HUD/BuildButtons.visible = false
	$UI/HUD/DoneButton.visible = false
	if build_type != "Expansion":
		$Iso/IsoBase.modulate = Color(1,1,1,0.4)
		set_building_preview(build_type, get_global_mouse_position())
	else:
		show_lands_for_sale()
		has_lands_preview = true
		$UI/HUD/DoneButton.visible = true
		expanse_mode = true
		build_mode = false

func set_building_preview(building_type, preview_position):
	var drag_building = load("res://scenes/" + building_type.to_lower() + ".tscn").instantiate()
	drag_building.set_name("DragBuilding")
	var control = Control.new()
	control.add_child(drag_building,true)
	control.position = preview_position
	control.set_name("BuildingPreview")
	$Iso/BP.add_child(control, true)


func update_building_previe(new_pos, pos_offset,color):
	get_node("Iso/BP/BuildingPreview").global_position = new_pos# - pos_offset
	get_node("Iso/BP/BuildingPreview/DragBuilding").modulate = Color(color)

func load_config():
	var content = file_manager.load_from_file("config")
	if content == "not_first_time":
		is_first_time = false

func show_lands_for_sale():
	$Iso/IsoBase.modulate = Color(1,1,1,0.4)
	for_sale_lands_array.clear()
	for land in own_lands_array:
		if absi(land.y % 2) == 1:
			for dir in odd_directions:
				if own_lands_array.has(dir + land):
					continue
				else:
					if !for_sale_lands_array.has(dir + land):
						for_sale_lands_array.append(dir + land)
		else:
			for dir in even_directions:
				if own_lands_array.has(dir + land):
					continue
				else:
					if !for_sale_lands_array.has(dir + land):
						for_sale_lands_array.append(dir + land)

	for l in for_sale_lands_array:
		var expansion_instance = load("res://scenes/expansion.tscn").instantiate()
		expansion_instance.position = $Iso/IsoLand.map_to_local(l)
		expansion_instance.add_to_group("expansions")
		$Iso/ExpansionPreviews.add_child(expansion_instance)
	
	if !Globals.pick_expansion.is_connected(Callable(self,"manage_expanse")):
		Globals.pick_expansion.connect(Callable(self,"manage_expanse"))

func manage_expanse(pos):
	if !has_painted_building:
		
		var exp_pos = $Iso/IsoBase.local_to_map(pos)
		paint_building(exp_pos,Vector2i(5,5), Color(0,0,1,0.2))
#		GlobalSignal.pick_expansion.disconnect(Callable(self,"manage_expanse"))
#		if GlobalSignal.pick_expansion.is_connected(Callable(self,"manage_expanse")):
#			GlobalSignal.pick_expansion.disconnect(Callable(self,"manage_expanse"))
		$UI/HUD/Dialog/VBoxContainer/Label.text = "Buy Expansion?"
		$UI/HUD/Dialog.visible = true
		$UI/HUD/DoneButton.visible = false
		var callable = Callable(self,"buy_expansion")
		connect_dialog_buttons({"position": exp_pos},callable)

func buy_expansion(btn_name,dict):
	if btn_name == "Yes":
		own_lands_array.append(dict["position"])
		for cell in get_iso_array(dict["position"],Vector2i(5,5)):
			$Iso/IsoLand.set_cell(0,cell,0,Vector2i(0,0))
		file_manager.save_to_file("lands_data", own_lands_array)
		if has_lands_preview:
			for l in $Iso/ExpansionPreviews.get_children():
				l.queue_free()
		show_lands_for_sale()
		desactivate_dialog_btns()
	elif btn_name == "No":
		desactivate_dialog_btns()
	

func desactivate_dialog_btns():
	$UI/HUD/Dialog.visible = false
	$UI/HUD/DoneButton.visible = true
	var painted_array = $Iso/PaintedBuildings.get_children()
	if painted_array.size() > 0:
		for unit in painted_array:
			unit.queue_free()
	if has_painted_building:
		has_painted_building = false
	
	var c = null
#	if sell_mode:
#		c = Callable(self,"erase_building")
	if expanse_mode:
		c = Callable(self,"buy_expansion")
		
	disconnect_dialog_buttons(c)

func paint_building(base: Vector2i,dims: Vector2i,color):
	for cell in get_iso_array(base,dims):
		var cell_white = load("res://scenes/white.tscn").instantiate()
		cell_white.position = $Iso/IsoBase.map_to_local(cell)
		cell_white.modulate = color
		$Iso/PaintedBuildings.add_child(cell_white)
	has_painted_building = true


func update_map():
	
	for land_base in own_lands_array_ortho:
		$Ortho/OrthoLand.set_pattern(0,land_base,$Ortho/OrthoLand.tile_set.get_pattern(0))
	
	for land_base in own_lands_array:
		for cell in get_iso_array(land_base,Vector2i(5,5)):
			$Iso/IsoLand.set_cell(0,cell,0,Vector2i(0,0))
	
	var roads_array = []
	for item in buildings_data_array:
		if item["type"] == "Road":
			roads_array.append(item["base"])
		else:
			var b_instance = load("res://scenes/"+item["type"].to_lower()+".tscn").instantiate()
			b_instance.position = $Iso/IsoLand.map_to_local(item["base"])
			$Iso/BuildingS.add_child(b_instance)
	$Iso/IsoRoads.set_cells_terrain_connect(0,roads_array,0,0,false)
	
#	var roads_array = []
#	for item in buildings_data_array:
#		if item["type"] == "Road":
#			roads_array.append(item["base"])
#		else:
#			for cell in get_atlas_positions_array_from_dims(item["dims"],item["base"]):
#				var sourse_id = BUILDING_TYPE[item["type"].to_upper()] if item["connected"] else BUILDING_TYPE[item["type"].to_upper()] + 2
#				$Buildings.set_cell(0, cell, sourse_id, cell - item["base"])
#	$Buildings.set_cells_terrain_connect(0,roads_array,0,0,false)

#func get_atlas_positions_array_from_dims(dims,base) -> Array:
#	var result = []
#	for y in dims.y:
#		for x in dims.x:
#			result.append(base + Vector2i(x,y))
#	return result

func connect_dialog_buttons(dict,func_name):
	dialog_mode = true
	for b in get_tree().get_nodes_in_group("dialog_buttons"):
		if !b.pressed.is_connected(func_name):
			b.pressed.connect(func_name.bind(b.name,dict))

func disconnect_dialog_buttons(func_name):
	dialog_mode = false
	if func_name != null:
		for b in get_tree().get_nodes_in_group("dialog_buttons"):
			if b.pressed.is_connected(func_name):
				b.pressed.disconnect(func_name)

func _on_done_button_pressed() -> void:
	if has_lands_preview:
		for preview in $Iso/ExpansionPreviews.get_children():
			preview.queue_free()
	$Iso/IsoBase.modulate = Color(1,1,1,1)
	has_lands_preview = false
	$Iso/IsoCells.visible = false
	has_painted_building = false
	
	Globals.play_mode = true
	sell_mode = false
	move_mode = false
	build_mode = false
	drag_mode = false
	expanse_mode = false
	
	DisplayServer.cursor_set_custom_image(default_cursor)
	$UI/HUD/BuildButtons.visible = false
	$UI/HUD/Menu.visible = true
	$UI/HUD/DoneButton.visible = false
	$UI/HUD/Dialog.visible = false
	
	if Globals.pick_expansion.is_connected(Callable(self,"manage_expanse")):
		Globals.pick_expansion.disconnect(Callable(self,"manage_expanse"))
	
	var painted_array = $Iso/PaintedBuildings.get_children()
	if painted_array.size() > 0:
		for unit in painted_array:
			unit.queue_free()


func _on_iso_ortho_button_toggled(button_pressed: bool) -> void:
	$Ortho.visible = !button_pressed
	$Iso.visible = button_pressed
	$UI/HUD/IsoOrthoButton.text = "IsoMode" if button_pressed else "OrthoMode"
