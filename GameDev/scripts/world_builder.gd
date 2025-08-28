

class_name WorldBuilder
extends Node

# World building tools for the alien colony game
# This provides the ability to place units and structures interactively

# Building modes
enum BuildMode {NONE, UNIT, STRUCTURE, ENVIRONMENT}
var current_build_mode: BuildMode = BuildMode.NONE
var current_build_type: String = ""

# Building costs
var unit_costs = {
	"worker_drone": {"biomass": 1},
	"harvester": {"biomass": 2},
	"queen": {"biomass": 5, "genetic_material": 2},
	"larvae": {"secretions": 1}
}

var structure_costs = {
	"nest": {"biomass": 10},
	"spire": {"minerals": 3},
	"nursery": {"minerals": 5, "biomass": 2},
	"creep_node": {"biomass": 1}
}

var environment_costs = {
	"pond": {"minerals": 2},
	"forest": {"biomass": 3},
	"animal_habitat": {"biomass": 2}
}

# References
@onready var game_manager: Node = get_node("/root/Main/GameManager")
@onready var hive_core: Node = get_node("/root/Main/Structures/HiveCore")
@onready var corruption_system: Node = get_node("/root/Main/CorruptionSystem")

# Building preview
var build_preview: Sprite2D
var can_build: bool = false

func _ready():
	# Find references
	setup_build_preview()
	setup_input()

func setup_build_preview():
	build_preview = Sprite2D.new()
	build_preview.modulate = Color(0, 1, 0, 0.5)
	build_preview.visible = false
	add_child(build_preview)

func setup_input():
	# Make sure input is enabled
	set_process_input(true)

func _input(event):
	if event is InputEventMouseMotion:
		update_build_preview(event.position)
	
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			handle_left_click(event.position)
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			handle_right_click()

func update_build_preview(mouse_pos: Vector2):
	if current_build_mode == BuildMode.NONE:
		build_preview.visible = false
		return
	
	build_preview.visible = true
	build_preview.global_position = mouse_pos
	
	# Check if we can build here
	can_build = check_build_location(mouse_pos)
	
	# Update preview color
	if can_build:
		build_preview.modulate = Color(0, 1, 0, 0.5)
	else:
		build_preview.modulate = Color(1, 0, 0, 0.5)

func check_build_location(pos: Vector2) -> bool:
	# Check if position is on corrupted ground (required for structures)
	if current_build_mode == BuildMode.STRUCTURE:
		if corruption_system and not corruption_system.is_position_corrupted(pos):
			return false
	
	# Check if position is too close to existing structures
	var structures = get_tree().get_nodes_in_group("structures")
	for structure in structures:
		if structure.global_position.distance_to(pos) < 64.0:
			return false
	
	# Check if position is on water
	if is_position_on_water(pos):
		return false
	
	return true

func is_position_on_water(pos: Vector2) -> bool:
	var ponds = get_tree().get_nodes_in_group("ponds")
	for pond in ponds:
		if pond.global_position.distance_to(pos) < 48.0:
			return true
	return false

func handle_left_click(pos: Vector2):
	if current_build_mode == BuildMode.NONE:
		return
	
	if can_build:
		place_building(pos)
		clear_build_mode()

func handle_right_click():
	clear_build_mode()

func start_building_mode(mode: BuildMode, build_type: String):
	current_build_mode = mode
	current_build_type = build_type
	
	# Update preview sprite based on type
	update_preview_sprite(build_type)
	
	print("Started building mode: ", mode, " - ", build_type)

func update_preview_sprite(build_type: String):
	# Set preview sprite based on build type
	var texture: Texture2D
	
	match build_type:
		"nest":
			texture = create_nest_preview()
		"spire":
			texture = create_spire_preview()
		"nursery":
			texture = create_nursery_preview()
		"creep_node":
			texture = create_creep_node_preview()
		"worker_drone":
			texture = create_worker_preview()
		"harvester":
			texture = create_harvester_preview()
		"queen":
			texture = create_queen_preview()
		"larvae":
			texture = create_larvae_preview()
		_:
			texture = create_default_preview()
	
	build_preview.texture = texture

func create_nest_preview() -> Texture2D:
	var texture = GradientTexture2D.new()
	var gradient = Gradient.new()
	gradient.colors = PackedColorArray(Color(0.6, 0.2, 0.8), Color(0.4, 0.1, 0.6))
	texture.gradient = gradient
	texture.width = 32
	texture.height = 32
	return texture

func create_spire_preview() -> Texture2D:
	var texture = GradientTexture2D.new()
	var gradient = Gradient.new()
	gradient.colors = PackedColorArray(Color(0.8, 0.6, 0.2), Color(0.6, 0.4, 0.1))
	texture.gradient = gradient
	texture.width = 24
	texture.height = 40
	return texture

func create_nursery_preview() -> Texture2D:
	var texture = GradientTexture2D.new()
	var gradient = Gradient.new()
	gradient.colors = PackedColorArray(Color(0.2, 0.8, 0.6), Color(0.1, 0.6, 0.4))
	texture.gradient = gradient
	texture.width = 40
	texture.height = 32
	return texture

func create_creep_node_preview() -> Texture2D:
	var texture = GradientTexture2D.new()
	var gradient = Gradient.new()
	gradient.colors = PackedColorArray(Color(0.8, 0.2, 0.8), Color(0.6, 0.1, 0.6))
	texture.gradient = gradient
	texture.width = 16
	texture.height = 16
	return texture

func create_worker_preview() -> Texture2D:
	var texture = GradientTexture2D.new()
	var gradient = Gradient.new()
	gradient.colors = PackedColorArray(Color(0.2, 0.6, 0.8), Color(0.1, 0.4, 0.6))
	texture.gradient = gradient
	texture.width = 16
	texture.height = 16
	return texture

func create_harvester_preview() -> Texture2D:
	var texture = GradientTexture2D.new()
	var gradient = Gradient.new()
	gradient.colors = PackedColorArray(Color(0.8, 0.4, 0.2), Color(0.6, 0.3, 0.1))
	texture.gradient = gradient
	texture.width = 20
	texture.height = 16
	return texture

func create_queen_preview() -> Texture2D:
	var texture = GradientTexture2D.new()
	var gradient = Gradient.new()
	gradient.colors = PackedColorArray(Color(0.8, 0.2, 0.6), Color(0.6, 0.1, 0.4))
	texture.gradient = gradient
	texture.width = 24
	texture.height = 20
	return texture

func create_larvae_preview() -> Texture2D:
	var texture = GradientTexture2D.new()
	var gradient = Gradient.new()
	gradient.colors = PackedColorArray(Color(0.6, 0.8, 0.2), Color(0.4, 0.6, 0.1))
	texture.gradient = gradient
	texture.width = 12
	texture.height = 12
	return texture

func create_default_preview() -> Texture2D:
	var texture = GradientTexture2D.new()
	var gradient = Gradient.new()
	gradient.colors = PackedColorArray(Color(0.5, 0.5, 0.5), Color(0.3, 0.3, 0.3))
	texture.gradient = gradient
	texture.width = 16
	texture.height = 16
	return texture

func place_building(pos: Vector2):
	if current_build_mode == BuildMode.UNIT:
		place_unit(pos)
	elif current_build_mode == BuildMode.STRUCTURE:
		place_structure(pos)
	elif current_build_mode == BuildMode.ENVIRONMENT:
		place_environment(pos)

func place_unit(pos: Vector2):
	if not hive_core:
		return
	
	# Check if we can afford the unit
	if not can_afford_unit(current_build_type):
		print("Cannot afford unit: ", current_build_type)
		return
	
	# Spawn the unit
	var unit_scene = load("res://scenes/units/" + current_build_type + ".tscn")
	if unit_scene:
		var unit_instance = unit_scene.instantiate()
		unit_instance.global_position = pos
		
		# Add to units container
		var units_container = get_node("/root/Main/Units")
		if units_container:
			units_container.add_child(unit_instance)
			
			# Spend resources
			spend_unit_resources(current_build_type)
			
			print("Placed unit: ", current_build_type, " at ", pos)

func place_structure(pos: Vector2):
	if not hive_core:
		return
	
	# Check if we can afford the structure
	if not can_afford_structure(current_build_type):
		print("Cannot afford structure: ", current_build_type)
		return
	
	# Create the structure
	var structure: Node
	
	match current_build_type:
		"nest":
			structure = create_nest(pos)
		"spire":
			structure = create_spire(pos)
		"nursery":
			structure = create_nursery(pos)
		"creep_node":
			structure = create_creep_node(pos)
		_:
			print("Unknown structure type: ", current_build_type)
			return
	
	if structure:
		# Add to structures container
		var structures_container = get_node("/root/Main/Structures")
		if structures_container:
			structures_container.add_child(structure)
			
			# Spend resources
			spend_structure_resources(current_build_type)
			
			print("Placed structure: ", current_build_type, " at ", pos)

func create_nest(pos: Vector2) -> Node:
	var nest = StaticBody2D.new()
	nest.script = load("res://scripts/nest.gd")
	nest.global_position = pos
	
	# Add sprite
	var sprite = Sprite2D.new()
	var texture = GradientTexture2D.new()
	var gradient = Gradient.new()
	gradient.colors = PackedColorArray(Color(0.6, 0.2, 0.8), Color(0.4, 0.1, 0.6))
	texture.gradient = gradient
	texture.width = 32
	texture.height = 32
	sprite.texture = texture
	nest.add_child(sprite)
	
	# Add collision
	var collision = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = Vector2(28, 28)
	collision.shape = shape
	nest.add_child(collision)
	
	return nest

func create_spire(pos: Vector2) -> Node:
	var spire = StaticBody2D.new()
	spire.global_position = pos
	
	# Add sprite
	var sprite = Sprite2D.new()
	var texture = GradientTexture2D.new()
	var gradient = Gradient.new()
	gradient.colors = PackedColorArray(Color(0.8, 0.6, 0.2), Color(0.6, 0.4, 0.1))
	texture.gradient = gradient
	texture.width = 24
	texture.height = 40
	sprite.texture = texture
	spire.add_child(sprite)
	
	# Add collision
	var collision = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = Vector2(20, 36)
	collision.shape = shape
	spire.add_child(collision)
	
	return spire

func create_nursery(pos: Vector2) -> Node:
	var nursery = StaticBody2D.new()
	nursery.global_position = pos
	
	# Add sprite
	var sprite = Sprite2D.new()
	var texture = GradientTexture2D.new()
	var gradient = Gradient.new()
	gradient.colors = PackedColorArray(Color(0.2, 0.8, 0.6), Color(0.1, 0.6, 0.4))
	texture.gradient = gradient
	texture.width = 40
	texture.height = 32
	sprite.texture = texture
	nursery.add_child(sprite)
	
	# Add collision
	var collision = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = Vector2(36, 28)
	collision.shape = shape
	nursery.add_child(collision)
	
	return nursery

func create_creep_node(pos: Vector2) -> Node:
	var creep_node = StaticBody2D.new()
	creep_node.global_position = pos
	
	# Add sprite
	var sprite = Sprite2D.new()
	var texture = GradientTexture2D.new()
	var gradient = Gradient.new()
	gradient.colors = PackedColorArray(Color(0.8, 0.2, 0.8), Color(0.6, 0.1, 0.6))
	texture.gradient = gradient
	texture.width = 16
	texture.height = 16
	sprite.texture = texture
	sprite.add_child(sprite)
	
	# Add collision
	var collision = CollisionShape2D.new()
	var shape = CircleShape2D.new()
	shape.radius = 8.0
	collision.shape = shape
	creep_node.add_child(collision)
	
	return creep_node

func place_environment(pos: Vector2):
	# Place environmental features
	pass

func can_afford_unit(unit_type: String) -> bool:
	if not hive_core or not hive_core.has_method("get_total_resources"):
		return false
	
	var costs = unit_costs.get(unit_type, {})
	var biomass_cost = costs.get("biomass", 0)
	var genetic_cost = costs.get("genetic_material", 0)
	var secretions_cost = costs.get("secretions", 0)
	
	var resources = hive_core.get_total_resources()
	return resources.can_afford(biomass_cost, 0, genetic_cost, 0, secretions_cost, 0)

func can_afford_structure(structure_type: String) -> bool:
	if not hive_core or not hive_core.has_method("get_total_resources"):
		return false
	
	var costs = structure_costs.get(structure_type, {})
	var biomass_cost = costs.get("biomass", 0)
	var minerals_cost = costs.get("minerals", 0)
	
	var resources = hive_core.get_total_resources()
	return resources.can_afford(biomass_cost, 0, 0, minerals_cost, 0, 0)

func spend_unit_resources(unit_type: String):
	if not hive_core or not hive_core.has_method("get_total_resources"):
		return
	
	var costs = unit_costs.get(unit_type, {})
	var biomass_cost = costs.get("biomass", 0)
	var genetic_cost = costs.get("genetic_material", 0)
	var secretions_cost = costs.get("secretions", 0)
	
	var resources = hive_core.get_total_resources()
	resources.spend_resources(biomass_cost, 0, genetic_cost, 0, secretions_cost, 0)

func spend_structure_resources(structure_type: String):
	if not hive_core or not hive_core.has_method("get_total_resources"):
		return
	
	var costs = structure_costs.get(structure_type, {})
	var biomass_cost = costs.get("biomass", 0)
	var minerals_cost = costs.get("minerals", 0)
	
	var resources = hive_core.get_total_resources()
	resources.spend_resources(biomass_cost, 0, 0, minerals_cost, 0, 0)

func clear_build_mode():
	current_build_mode = BuildMode.NONE
	current_build_type = ""
	build_preview.visible = false

func get_world_2d() -> World2D:
	return get_viewport().world_2d
