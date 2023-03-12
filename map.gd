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
var place_valid = false

const LIMIT = 200
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

var ortho = [
	Vector2i(-2, 4), Vector2i(-1, 2), Vector2i(-2, 3), Vector2i(-1, 4), Vector2i(-2, 5), 
	Vector2i(-1, 6), Vector2i(0, 0), Vector2i(-1, 1), Vector2i(0, 2), Vector2i(-1, 3), 
	Vector2i(0, 4), Vector2i(-1, 5), Vector2i(0, 6), Vector2i(-1, 7), Vector2i(0, 8), 
	Vector2i(0, 1), Vector2i(1, 2), Vector2i(0, 3), Vector2i(1, 4), Vector2i(0, 5), 
	Vector2i(1, 6), Vector2i(0, 7), Vector2i(1, 3), Vector2i(2, 4), Vector2i(1, 5)
	]


#var ortho = [
#	Vector2i(10, 4), Vector2i(11, 2), Vector2i(10, 3), Vector2i(11, 4), Vector2i(10, 5),
#	Vector2i(11, 6), Vector2i(12, 0), Vector2i(11, 1), Vector2i(12, 2), Vector2i(11, 3), 
#	Vector2i(12, 4), Vector2i(11, 5), Vector2i(12, 6), Vector2i(11, 7), Vector2i(12, 8), 
#	Vector2i(12, 1), Vector2i(13, 2), Vector2i(12, 3), Vector2i(13, 4), Vector2i(12, 5), 
#	Vector2i(13, 6), Vector2i(12, 7), Vector2i(13, 3), Vector2i(14, 4), Vector2i(13, 5), 
#	Vector2i(12, 9), Vector2i(13, 7), Vector2i(13, 8), Vector2i(13, 9), Vector2i(13, 10), 
#	Vector2i(13, 11), Vector2i(14, 5), Vector2i(14, 6), Vector2i(14, 7), Vector2i(14, 8), 
#	Vector2i(14, 9), Vector2i(14, 10), Vector2i(14, 11), Vector2i(14, 12), Vector2i(14, 13), 
#	Vector2i(15, 6), Vector2i(15, 7), Vector2i(15, 8), Vector2i(15, 9), Vector2i(15, 10), 
#	Vector2i(15, 11), Vector2i(15, 12), Vector2i(16, 8), Vector2i(16, 9), Vector2i(16, 10)
#	]


func _ready() -> void:
	$CameraManager.limit_bottom = 4 * LIMIT # 2000
	$CameraManager.limit_left = -4 * LIMIT # -2000
	$CameraManager.limit_right = 6 * LIMIT # 3000
	$CameraManager.limit_top = -3 * LIMIT # -1500
	
#	for v in ortho:
#		print(v)
#		var d_1 = Vector2i(10,0)
#		var d_2 = Vector2i(12,5)
#		var d_3 = Vector2i(7,5)
#		var d_4 = Vector2i(10,10)
#		var d_5 = Vector2i(5,10)
#		var d_6 = Vector2i(7,15)
#		if v.y % 2 == 1:
#			d_2.x += 1#Vector2i(13,5)
#			d_3.x += 1#Vector2i(8,5)
#			d_6.x += 1#Vector2i(8,15)
#		$Land.set_cell(0,v + d_1,0,Vector2i(0,0))
#		$Land.set_cell(0,v + d_2,0,Vector2i(0,0))
#		$Land.set_cell(0,v + d_3,0,Vector2i(0,0))
#		$Land.set_cell(0,v + d_4,0,Vector2i(0,0))
#		$Land.set_cell(0,v + d_5,0,Vector2i(0,0))
#		$Land.set_cell(0,v + d_6,0,Vector2i(0,0))
#		await get_tree().create_timer(.1).timeout
	
#	var d = Vector2i(-2,6)
#	var d = Vector2i(3,4)
#	var d = Vector2i(3,7)
#	if v.y % 2 == 1:
#		d = Vector2i(4,7)
#	var d = Vector2i(-8,9)
#	if v.y % 2 == 1:
#		d = Vector2i(-7,9)
	
#	load_config()
#	if is_first_time:
#		build_main_hall()
#	else:
#		load_from_buildings_data_file()
	build_main_hall()
	update_map()
	default_cursor = load("res://default_cursor_32.png")
	move_cursor = load("res://move_cursor_32.png")
	sell_cursor = load("res://sell_cursor_32.png")
	DisplayServer.cursor_set_custom_image(default_cursor)
	for b in get_tree().get_nodes_in_group("menu_buttons"):
		b.pressed.connect(init_menu_mode.bind(b))
	for b in get_tree().get_nodes_in_group("build_buttons"):
		b.pressed.connect(init_build_mode.bind(b))

func _process(_delta: float) -> void:
	print(idle_mode,build_mode)
	if build_mode or drag_mode:
		update_building_preview()

func _unhandled_input(event: InputEvent) -> void:
	
	# mouse_drag
#	print($CameraManager.position)
	if event is InputEventMouseMotion:
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
#			offset += $CameraManager.position
	
#	if idle_mode:
#	if event is InputEventMouseButton:
#		half_camera_rect = get_viewport_rect().size * zoom_factor * 0.5
#			if event.is_pressed():
				
#	print(event)
#	var current_cell = $Base.local_to_map(get_global_mouse_position())
#	print(current_cell)

func init_menu_mode(btn):
	match btn.name:
		"BuilderButton":
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
		Vector2i(7, 15)
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
#	prints(current_cell,current_cell_in_px)

func init_build_mode(btn):
	build_mode = true
	idle_mode = false
	build_type = btn.name
	$UI/HUD/BuildButtons.visible = false
	$UI.set_building_preview(build_type, get_global_mouse_position())

func load_config():
	var content = file_manager.load_from_file("config")
	if content == "not_first_time":
		is_first_time = false

func update_map():
	
	for v in ortho:
		for land in own_lands_array:
			if land.y%2==1:
				if v.y%2==1:
					land.x += 1
			$Land.set_cell(0,v + land,0,Vector2i(0,0))

#		$Land.set_pattern(0,land,$Land.tile_set.get_pattern(0))
	
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


func _on_done_button_pressed() -> void:
	pass # Replace with function body.
