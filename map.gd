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
var idle_mode = true

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
var for_sale_lands_array = []
var file_manager: FileManager = FileManager.new()

var build_type
var build_location

var sell_cursor
var move_cursor
var default_cursor

var whitey = preload("res://scenes/white.tscn").instantiate()
#var exp_to_buy_base = Vector2i()
#var has_point_in_for_sale = false

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

var iso_coords_5_5 = [
	Vector2i(-2, 4), Vector2i(-1, 2), Vector2i(-2, 3), Vector2i(-1, 4), Vector2i(-2, 5), 
	Vector2i(-1, 6), Vector2i(0, 0), Vector2i(-1, 1), Vector2i(0, 2), Vector2i(-1, 3), 
	Vector2i(0, 4), Vector2i(-1, 5), Vector2i(0, 6), Vector2i(-1, 7), Vector2i(0, 8), 
	Vector2i(0, 1), Vector2i(1, 2), Vector2i(0, 3), Vector2i(1, 4), Vector2i(0, 5), 
	Vector2i(1, 6), Vector2i(0, 7), Vector2i(1, 3), Vector2i(2, 4), Vector2i(1, 5)
	]

signal exper

func _ready() -> void:
	$CameraManager.limit_bottom = 4 * LIMIT # 2000
	$CameraManager.limit_left = -4 * LIMIT # -2000
	$CameraManager.limit_right = 6 * LIMIT # 3000
	$CameraManager.limit_top = -3 * LIMIT # -1500

#	load_config()
#	if is_first_time:
#		build_main_hall()
#	else:
#		load_from_buildings_data_file()
	build_main_hall()
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
#	print(idle_mode,build_mode,expanse_mode,move_mode)
	if build_mode or drag_mode:
		update_building_preview()

func _unhandled_input(event: InputEvent) -> void:
	if idle_mode:
		if event.is_action_released("ui_accept"):
			var current_cell = get_global_mouse_position()
#			var current_cell = $Base.local_to_map(get_global_mouse_position())
			print(current_cell)
	if build_mode:
		if event.is_action_released("ui_accept"):
			place_building()
			if build_type != "Road":
				cancel_build_mode()
				$Base.modulate = Color(1,1,1,1)
		if event.is_action_released("ui_cancel"):
			cancel_build_mode()
			$Base.modulate = Color(1,1,1,1)
	
	if move_mode:
		if !has_lands_preview:
			show_lands_for_sale()
			has_lands_preview = true
		if event.is_action_released("ui_accept"):
			var current_cell = $Land.local_to_map(get_global_mouse_position())
			print("w",current_cell)
			if $Buildings.get_used_cells(0).has(current_cell):
				print(99999)
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
#		if !has_painted_building:
#			paint_building(exp_to_buy_base,Color(0,0,1,0.2))
#			GlobalSignal.pick_expansion.disconnect(Callable(self,"_set_base_exp_to_buy"))
		
#		if event.is_action_released("ui_accept"):
#			if !has_painted_building:
#				var current_tile = $Base.local_to_map(get_global_mouse_position())
#				prints(current_tile,22)
#				if has_point_in_for_sale_lands(current_tile):
#					paint_building(exp_to_buy_base,Color(0,0,1,0.2))
#					print(9798787987)
#					var rect_for_sale = get_rect_for_sale(current_tile)
#					$UI/HUD/Dialog/VBoxContainer/Label.text = "Buy Expansion?"
#					paint_building(get_atlas_positions_array_from_dims(Vector2i(5,5),rect_for_sale),Color(0,0,1,0.5))
#					$UI/HUD/Dialog.visible = true
#					var callable = Callable(self,"buy_expansion")
#					connect_dialog_buttons({"position": rect_for_sale},callable)
	
	if event is InputEventMouseMotion:
		idle_mode = false
		mouse_pressing = Input.get_action_strength("ui_accept")
		if mouse_pressing:
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
		idle_mode = true
	
#	if idle_mode:
#	if event is InputEventMouseButton:
#		half_camera_rect = get_viewport_rect().size * zoom_factor * 0.5
#			if event.is_pressed():

#func has_point_in_for_sale_lands(point: Vector2i) -> bool:
#
#	for n in get_tree().get_nodes_in_group("expansions"):
#		print(n.has)
	


func place_building():
	pass

func cancel_build_mode():
	$Cells.visible = false
	place_valid = false
	build_mode = false
	get_node("UI/BuildingPreview").queue_free()
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
			$Cells.visible = true
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

func load_from_buildings_data_file() :
	var content: Array = file_manager.load_from_file("buildings_data") as Array
	buildings_data_array.clear()
	buildings_data_array.append_array(content)
	
	content = file_manager.load_from_file("lands_data") as Array
	own_lands_array.clear()
	own_lands_array.append_array(content)

func update_building_preview():
	var current_cell = $Base.local_to_map(get_global_mouse_position())
	var current_cell_in_px = Vector2i($Base.map_to_local(current_cell))
	$UI.update_building_preview(current_cell_in_px,Vector2i($CameraManager.position),"44ffffff")
#	prints(current_cell)

func init_build_mode(btn):
	build_mode = true
	idle_mode = false
	build_type = btn.name
	$Cells.visible = true
	$UI/HUD/BuildButtons.visible = false
	$UI/HUD/DoneButton.visible = false
	if build_type != "Expansion":
		$Base.modulate = Color(1,1,1,0.4)
		$UI.set_building_preview(build_type, get_global_mouse_position())
	else:
		show_lands_for_sale()
		has_lands_preview = true
		$UI/HUD/DoneButton.visible = true
		expanse_mode = true
		build_mode = false

func load_config():
	var content = file_manager.load_from_file("config")
	if content == "not_first_time":
		is_first_time = false

func show_lands_for_sale():
	$UI.modulate_ui(Color(1,1,1,0.4))
#	print(own_lands_array)
	for_sale_lands_array.clear()
	for l in own_lands_array:
		if absi(l.y%2)==1:
			for dir in odd_directions:
				if own_lands_array.has(dir + l):
					continue
				else:
					if !for_sale_lands_array.has(dir + l):
#						print(dir+l)
						for_sale_lands_array.append(dir + l)
		else:
			for dir in even_directions:
				if own_lands_array.has(dir + l):
					continue
				else:
					if !for_sale_lands_array.has(dir + l):
#						print(dir+l)
						for_sale_lands_array.append(dir + l)

#	print(for_sale_lands_array)
	
	for l in for_sale_lands_array:
		var b = load("res://scenes/expansion.tscn").instantiate()
		b.position = $Land.map_to_local(l)
		b.add_to_group("expansions")
		$ExpansionPreviews.add_child(b)
	if !GlobalSignal.pick_expansion.is_connected(Callable(self,"manage_expanse")):
		GlobalSignal.pick_expansion.connect(Callable(self,"manage_expanse"))

func manage_expanse(pos):
	if !has_painted_building:
		var exp_pos = $Base.local_to_map(pos)
		paint_building(exp_pos,Color(0,0,1,0.2))
#		GlobalSignal.pick_expansion.disconnect(Callable(self,"manage_expanse"))
		$UI/HUD/Dialog/VBoxContainer/Label.text = "Buy Expansion?"
		$UI/HUD/Dialog.visible = true
		var callable = Callable(self,"buy_expansion")
		connect_dialog_buttons({"position": exp_pos},callable)
#		print("wewe",$Base.local_to_map(pos))

func buy_expansion(btn_name,dict):
	if btn_name == "Yes":
		own_lands_array.append(dict["position"])
		for cell in iso_coords_5_5:
			$Land.set_cell(0,return_processed_iso_coords(dict["position"],cell),0,Vector2i(0,0))
		file_manager.save_to_file("lands_data", own_lands_array)
		if has_lands_preview:
			for l in $ExpansionPreviews.get_children():
				l.queue_free()
		show_lands_for_sale()
		desactivate_dialog_btns()
	elif btn_name == "No":
		desactivate_dialog_btns()
	

func desactivate_dialog_btns():
	$UI/HUD/Dialog.visible = false
	var painted_array = $PaintedBuildings.get_children()
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

func paint_building(base,color):
	for cell in iso_coords_5_5:
		var cell_white = load("res://scenes/white.tscn").instantiate()
		cell_white.position = $Base.map_to_local(return_processed_iso_coords(base,cell))
		cell_white.modulate = color
		$PaintedBuildings.add_child(cell_white)
#		print(g)
	has_painted_building = true

func return_processed_iso_coords(base,cell):
	if absi(base.y % 2) == 1:
		if cell.y % 2 == 1:
			base.x += 1
	return base + cell

func update_map():
	for cell in iso_coords_5_5:
		for land_base in own_lands_array:
			$Land.set_cell(0,return_processed_iso_coords(land_base,cell),0,Vector2i(0,0))

	var roads_array = []
	for item in buildings_data_array:
		if item["type"] == "Road":
			roads_array.append(item["base"])
		else:
			for cell in get_atlas_positions_array_from_dims(item["dims"],item["base"]):
				var sourse_id = BUILDING_TYPE[item["type"].to_upper()] if item["connected"] else BUILDING_TYPE[item["type"].to_upper()] + 2
				$Buildings.set_cell(0, cell, sourse_id, cell - item["base"])
	$Buildings.set_cells_terrain_connect(0,roads_array,0,0,false)

func get_atlas_positions_array_from_dims(dims,base) -> Array:
	var result = []
	for y in dims.y:
		for x in dims.x:
			result.append(base + Vector2i(x,y))
	return result

func connect_dialog_buttons(dict,func_name):
	for b in get_tree().get_nodes_in_group("dialog_buttons"):
		if !b.pressed.is_connected(func_name):
			b.pressed.connect(func_name.bind(b.name,dict))

func disconnect_dialog_buttons(func_name):
	if func_name != null:
		for b in get_tree().get_nodes_in_group("dialog_buttons"):
			if b.pressed.is_connected(func_name):
				b.pressed.disconnect(func_name)

func _on_done_button_pressed() -> void:
	if has_lands_preview:
		for preview in $ExpansionPreviews.get_children():
			preview.queue_free()
	$UI.modulate_ui(Color(1,1,1,1))
	has_lands_preview = false
	$Cells.visible = false
	has_painted_building = false
	
	idle_mode = true
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
	
	if GlobalSignal.pick_expansion.is_connected(Callable(self,"manage_expanse")):
		GlobalSignal.pick_expansion.disconnect(Callable(self,"manage_expanse"))
#	exp_to_buy_base = null
	
	var painted_array = $PaintedBuildings.get_children()
	if painted_array.size() > 0:
		for unit in painted_array:
			unit.queue_free()
