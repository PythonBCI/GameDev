class_name CorruptionSystem
extends Node

# Corruption properties
@export var spread_interval: float = 5.0
@export var spread_range: int = 1
@export var max_corruption_percentage: float = 0.75

# Corruption layer
@onready var corruption_layer: TileMap = get_node("/root/Main/CorruptionLayer")
@onready var game_manager: Node = get_node("/root/Main/GameManager")

# Corruption sources (hive cores and nests)
var corruption_sources: Array[Node] = []
var corruption_tiles: Array[Vector2i] = []

# Spread timer
var spread_timer: Timer

func _ready():
	# Setup spread timer
	setup_spread_timer()
	
	# Find initial corruption sources
	find_corruption_sources()
	
	# Start corruption from hive core
	start_corruption_from_hive_core()

func setup_spread_timer():
	spread_timer = Timer.new()
	spread_timer.wait_time = spread_interval
	spread_timer.one_shot = false
	spread_timer.timeout.connect(_on_spread_timer_timeout)
	add_child(spread_timer)
	spread_timer.start()

func find_corruption_sources():
	# Find all hive cores and nests
	var hive_cores = get_tree().get_nodes_in_group("hive_cores")
	var nests = get_tree().get_nodes_in_group("nests")
	
	corruption_sources.clear()
	corruption_sources.append_array(hive_cores)
	corruption_sources.append_array(nests)

func start_corruption_from_hive_core():
	var hive_core = get_node("/root/Main/Structures/HiveCore")
	if hive_core:
		# Create 3x3 corruption around hive core
		var core_pos = hive_core.global_position
		var tile_pos = world_to_tile(core_pos)
		
		for x in range(-1, 2):
			for y in range(-1, 2):
				var tile = Vector2i(tile_pos.x + x, tile_pos.y + y)
				add_corruption_tile(tile)

func _on_spread_timer_timeout():
	spread_corruption()
	update_corruption_display()

func spread_corruption():
	var new_corruption_tiles: Array[Vector2i] = []
	
	# Spread from existing corruption tiles
	for tile in corruption_tiles:
		var neighbors = get_neighbor_tiles(tile)
		for neighbor in neighbors:
			if not corruption_tiles.has(neighbor) and not new_corruption_tiles.has(neighbor):
				# Check if neighbor is valid for corruption
				if can_corrupt_tile(neighbor):
					new_corruption_tiles.append(neighbor)
	
	# Add new corruption tiles
	for tile in new_corruption_tiles:
		add_corruption_tile(tile)
	
	# Check victory condition
	check_victory_condition()

func get_neighbor_tiles(tile: Vector2i) -> Array[Vector2i]:
	var neighbors: Array[Vector2i] = []
	
	for x in range(-spread_range, spread_range + 1):
		for y in range(-spread_range, spread_range + 1):
			if x != 0 or y != 0:
				var neighbor = Vector2i(tile.x + x, tile.y + y)
				neighbors.append(neighbor)
	
	return neighbors

func can_corrupt_tile(tile: Vector2i) -> bool:
	# Check if tile is within world bounds
	if tile.x < -62 or tile.x > 62 or tile.y < -37 or tile.y > 37:
		return false
	
	# Check if tile is already corrupted
	if corruption_tiles.has(tile):
		return false
	
	# Check if tile is on water (ponds)
	var world_pos = tile_to_world(tile)
	if is_position_on_water(world_pos):
		return false
	
	return true

func is_position_on_water(world_pos: Vector2) -> bool:
	# Check if position overlaps with ponds
	var ponds = get_tree().get_nodes_in_group("ponds")
	for pond in ponds:
		if pond.global_position.distance_to(world_pos) < 48.0:
			return true
	return false

func add_corruption_tile(tile: Vector2i):
	if not corruption_tiles.has(tile):
		corruption_tiles.append(tile)
		
		# Set tile in corruption layer
		if corruption_layer:
			corruption_layer.set_cell(0, tile, 0, Vector2i(0, 0))

func remove_corruption_tile(tile: Vector2i):
	if corruption_tiles.has(tile):
		corruption_tiles.erase(tile)
		
		# Remove tile from corruption layer
		if corruption_layer:
			corruption_layer.set_cell(0, tile, -1)

func world_to_tile(world_pos: Vector2) -> Vector2i:
	var tile_size = 16
	return Vector2i(
		int(world_pos.x / tile_size),
		int(world_pos.y / tile_size)
	)

func tile_to_world(tile: Vector2i) -> Vector2:
	var tile_size = 16
	return Vector2(
		tile.x * tile_size + tile_size / 2,
		tile.y * tile_size + tile_size / 2
	)

func get_corruption_coverage() -> float:
	var total_tiles = 125 * 75  # World size in tiles
	return float(corruption_tiles.size()) / float(total_tiles)

func check_victory_condition():
	var coverage = get_corruption_coverage()
	if coverage >= max_corruption_percentage:
		# Victory! Corrupted enough of the map
		if game_manager and game_manager.has_method("trigger_victory"):
			game_manager.trigger_victory("Map corruption victory!")

func update_corruption_display():
	var coverage = get_corruption_coverage()
	var percentage = int(coverage * 100)
	
	# Update UI
	var corruption_label = get_node("/root/Main/UI/GameStatus/CorruptionLabel")
	if corruption_label:
		corruption_label.text = "Corruption: " + str(percentage) + "%"

func add_corruption_source(source: Node):
	if not corruption_sources.has(source):
		corruption_sources.append(source)
		
		# Start corruption from new source
		var source_pos = source.global_position
		var tile_pos = world_to_tile(source_pos)
		
		# Create corruption around source
		for x in range(-1, 2):
			for y in range(-1, 2):
				var tile = Vector2i(tile_pos.x + x, tile_pos.y + y)
				add_corruption_tile(tile)

func remove_corruption_source(source: Node):
	if corruption_sources.has(source):
		corruption_sources.erase(source)

func get_corruption_bonus_at_position(world_pos: Vector2) -> float:
	var tile_pos = world_to_tile(world_pos)
	if corruption_tiles.has(tile_pos):
		return 0.25  # 25% speed bonus on corrupted ground
	return 0.0

func is_position_corrupted(world_pos: Vector2) -> bool:
	var tile_pos = world_to_tile(world_pos)
	return corruption_tiles.has(tile_pos)
