extends Node

class_name Utils

var ort_directions = [
	Vector2i.UP,
	Vector2i.RIGHT,
	Vector2i.DOWN,
	Vector2i.LEFT
	]

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

func get_neighbors_for_position(pos) -> Array:
	var result = []
	for dir in ort_directions:
		result.append(pos + dir)
	return result

#func get_build_dims():
#	match build_type:
#		"Main_Hall":
#			return Vector2i(6,7)
#		"Resa":
#			return Vector2i(2,2)
#		"Work":
#			return Vector2i(2,2)
#		"Road":
#			return Vector2i(1,1)

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

func trans_iso_to_ortho(iso: Vector2i):
	var result = Vector2i()
#	iso -= Vector2i(10,0)
	var whole = iso.y / 2
	var remainder = iso.y % 2
	result.x = whole + remainder + iso.x
	result.y = iso.y - result.x
#	prints(whole,remainder,result,iso)
	if remainder == -1:
		result += Vector2i(1,-1)
	return result #+ Vector2i(10,0)

#func get_item_from_buildings_data_array_by_position(pos):
#	for item in buildings_data_array:
#		for cell in get_atlas_positions_array_from_dims(item["dims"],item["base"]):
#			if cell == pos:
#				return item

func get_atlas_positions_array_from_dims(dims,base) -> Array:
	var result = []
	for y in dims.y:
		for x in dims.x:
			result.append(base + Vector2i(x,y))
	return result

func _get_atlas(map: TileMap, type: int):
	return map.tile_set.get_source(type)

func _get_atlas_array(atlas: TileSetAtlasSource) -> Array:
	var result = []
	var cells = atlas.get_atlas_grid_size()
	for cell in cells.x * cells.y:
		result.append(atlas.get_tile_id(cell))
	return result
