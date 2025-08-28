

class_name WorldBuilder
extends Node

# World building tools for the alien colony game
# This provides the ability to place units and structures interactively

# Building modes
enum BuildMode {NONE, UNIT, STRUCTURE, RESOURCE, ENEMY}
var current_build_mode: BuildMode = BuildMode.NONE

# Current selection for building
var selected_unit_type: String = ""
var selected_structure_type: String = ""
var selected_resource_type: String = ""

# Building costs
var unit_costs = {
	"worker_drone": {"biomass": 1},
	"harvester": {"biomass": 2},
	"queen": {"biomass": 5, "genetic_material": 2},
	"larvae": {"secretions": 1}
}

var structure_costs = {
	"spire": {"minerals": 3},
	"nursery": {"minerals": 5, "biomass": 2},
	"creep_node": {"biomass": 1}
}

var resource_costs = {
	"biomass": {"minerals": 1},
	"minerals": {"biomass": 1}
}

# References
var game_manager: GameManager
var hive_core: HiveCore
var units_container: Node2D
var structures_container: Node2D
var resources_container: Node2D
var enemies_container: Node2D

# Building preview
var build_preview: Sprite2D
var can_build: bool = false

func _ready():
	# Find references
	game_manager = get_node("../GameManager")
	hive_core = get_node("../Structures/HiveCore")
	units_container = get_node("../Units")
	structures_container = get_node("../Structures")
	resources_container = get_node("../Resources")
	enemies_container = get_node("../Enemies")
	
	# Setup build preview
	setup_build_preview()
	
	# Connect UI button signals
	connect_building_buttons()

func setup_build_preview():
	build_preview = Sprite2D.new()
	build_preview.modulate = Color(1, 1, 1, 0.5)
	build_preview.visible = false
	add_child(build_preview)

func connect_building_buttons():
	var ui = get_node("../UI")
	if ui and ui.has_node("BuildingButtons"):
		var buttons = ui.get_node("BuildingButtons/VBoxContainer")
		
		# Connect unit buttons
		if buttons.has_node("WorkerDroneButton"):
			buttons.get_node("WorkerDroneButton").pressed.connect(_on_worker_drone_button_pressed)
		if buttons.has_node("HarvesterButton"):
			buttons.get_node("HarvesterButton").pressed.connect(_on_harvester_button_pressed)
		if buttons.has_node("QueenButton"):
			buttons.get_node("QueenButton").pressed.connect(_on_queen_button_pressed)
		if buttons.has_node("LarvaeButton"):
			buttons.get_node("LarvaeButton").pressed.connect(_on_larvae_button_pressed)
		
		# Connect structure buttons
		if buttons.has_node("SpireButton"):
			buttons.get_node("SpireButton").pressed.connect(_on_spire_button_pressed)
		if buttons.has_node("NurseryButton"):
			buttons.get_node("NurseryButton").pressed.connect(_on_nursery_button_pressed)
		if buttons.has_node("CreepNodeButton"):
			buttons.get_node("CreepNodeButton").pressed.connect(_on_creep_node_button_pressed)

func _input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			handle_building_click(event.position)
		elif event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			cancel_building()
	
	elif event is InputEventMouseMotion:
		update_build_preview(event.position)

func handle_building_click(position: Vector2):
	if current_build_mode == BuildMode.NONE:
		return
	
	match current_build_mode:
		BuildMode.UNIT:
			place_unit(selected_unit_type, position)
		BuildMode.STRUCTURE:
			place_structure(selected_structure_type, position)
		BuildMode.RESOURCE:
			place_resource(selected_resource_type, position)
		BuildMode.ENEMY:
			place_enemy(position)
	
	# Reset building mode
	cancel_building()

func update_build_preview(position: Vector2):
	if current_build_mode == BuildMode.NONE:
		return
	
	build_preview.global_position = position
	
	# Check if we can build here
	can_build = check_build_position(position)
	build_preview.modulate = Color(0, 1, 0, 0.5) if can_build else Color(1, 0, 0, 0.5)

func check_build_position(position: Vector2) -> bool:
	# Check if position is valid for building
	# Not too close to hive core, not overlapping with other objects
	
	if hive_core and position.distance_to(hive_core.global_position) < 64:
		return false
	
	# Check for overlapping objects
	var space_state = get_world_2d().direct_space_state
	var query = PhysicsPointQueryParameters2D.new()
	query.position = position
	query.collision_mask = 1
	
	var result = space_state.intersect_point(query)
	return result.size() == 0

func place_unit(unit_type: String, position: Vector2):
	if not can_afford_unit(unit_type):
		print("Cannot afford to build ", unit_type)
		return
	
	# Load and instantiate unit
	var unit_scene = load("res://scenes/units/" + unit_type + ".tscn")
	if unit_scene:
		var unit_instance = unit_scene.instantiate()
		unit_instance.global_position = position
		units_container.add_child(unit_instance)
		
		# Add to hive units group
		unit_instance.add_to_group("hive_units")
		
		# Spend resources
		spend_unit_resources(unit_type)
		
		print("Placed ", unit_type, " at ", position)
	else:
		print("Failed to load unit scene: ", unit_type)

func place_structure(structure_type: String, position: Vector2):
	if not can_afford_structure(structure_type):
		print("Cannot afford to build ", structure_type)
		return
	
	# Create structure based on type
	var structure: StaticBody2D
	
	match structure_type:
		"spire":
			structure = create_spire()
		"nursery":
			structure = create_nursery()
		"creep_node":
			structure = create_creep_node()
		_:
			print("Unknown structure type: ", structure_type)
			return
	
	if structure:
		structure.global_position = position
		structures_container.add_child(structure)
		
		# Spend resources
		spend_structure_resources(structure_type)
		
		print("Placed ", structure_type, " at ", position)

func place_resource(resource_type: String, position: Vector2):
	if not can_afford_resource(resource_type):
		print("Cannot afford to create ", resource_type, " node")
		return
	
	# Create resource node
	var resource_node = create_resource_node(resource_type)
	if resource_node:
		resource_node.global_position = position
		resources_container.add_child(resource_node)
		
		# Spend resources
		spend_resource_resources(resource_type)
		
		print("Placed ", resource_type, " node at ", position)

func place_enemy(position: Vector2):
	# Create enemy (for testing purposes)
	var enemy_scene = load("res://scenes/enemies/basic_enemy.tscn")
	if enemy_scene:
		var enemy_instance = enemy_scene.instantiate()
		enemy_instance.global_position = position
		enemies_container.add_child(enemy_instance)
		
		print("Placed enemy at ", position)

# Unit creation functions
func create_spire() -> StaticBody2D:
	var spire = StaticBody2D.new()
	spire.add_to_group("structures")
	
	# Add collision shape
	var collision = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = Vector2(24, 24)
	collision.shape = shape
	spire.add_child(collision)
	
	# Add sprite
	var sprite = Sprite2D.new()
	sprite.modulate = Color(0.4, 0.8, 0.4, 1)
	sprite.texture = create_gradient_texture(24, 24, Color(0.4, 0.8, 0.4), Color(0.2, 0.6, 0.2))
	spire.add_child(sprite)
	
	return spire

func create_nursery() -> StaticBody2D:
	var nursery = StaticBody2D.new()
	nursery.add_to_group("structures")
	
	# Add collision shape
	var collision = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = Vector2(32, 32)
	collision.shape = shape
	nursery.add_child(collision)
	
	# Add sprite
	var sprite = Sprite2D.new()
	sprite.modulate = Color(0.8, 0.4, 0.4, 1)
	sprite.texture = create_gradient_texture(32, 32, Color(0.8, 0.4, 0.4), Color(0.6, 0.2, 0.2))
	nursery.add_child(sprite)
	
	return nursery

func create_creep_node() -> StaticBody2D:
	var creep_node = StaticBody2D.new()
	creep_node.add_to_group("structures")
	
	# Add collision shape
	var collision = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = Vector2(16, 16)
	collision.shape = shape
	creep_node.add_child(collision)
	
	# Add sprite
	var sprite = Sprite2D.new()
	sprite.modulate = Color(0.6, 0.2, 0.8, 1)
	sprite.texture = create_gradient_texture(16, 16, Color(0.6, 0.2, 0.8), Color(0.4, 0.1, 0.6))
	creep_node.add_child(sprite)
	
	return creep_node

func create_resource_node(resource_type: String) -> StaticBody2D:
	var resource_node = StaticBody2D.new()
	resource_node.add_to_group("resources")
	
	# Add collision shape
	var collision = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = Vector2(16, 16)
	collision.shape = shape
	resource_node.add_child(collision)
	
	# Add sprite with appropriate color
	var sprite = Sprite2D.new()
	match resource_type:
		"biomass":
			sprite.modulate = Color(0.2, 0.8, 0.2, 1)
			sprite.texture = create_gradient_texture(16, 16, Color(0.2, 0.8, 0.2), Color(0.1, 0.6, 0.1))
		"minerals":
			sprite.modulate = Color(0.6, 0.6, 0.6, 1)
			sprite.texture = create_gradient_texture(16, 16, Color(0.6, 0.6, 0.6), Color(0.4, 0.4, 0.4))
	resource_node.add_child(sprite)
	
	# Add resource node script
	var script = load("res://scripts/resource_node.gd")
	if script:
		resource_node.set_script(script)
	
	return resource_node

func create_gradient_texture(width: int, height: int, color1: Color, color2: Color) -> GradientTexture2D:
	var gradient = Gradient.new()
	gradient.colors = PackedColorArray([color1, color2])
	
	var texture = GradientTexture2D.new()
	texture.gradient = gradient
	texture.width = width
	texture.height = height
	
	return texture

# Resource checking and spending functions
func can_afford_unit(unit_type: String) -> bool:
	if not game_manager or not game_manager.resources:
		return false
	
	var costs = unit_costs.get(unit_type, {})
	return game_manager.resources.can_afford(
		biomass_cost=costs.get("biomass", 0),
		genetic_material_cost=costs.get("genetic_material", 0),
		secretions_cost=costs.get("secretions", 0)
	)

func can_afford_structure(structure_type: String) -> bool:
	if not game_manager or not game_manager.resources:
		return false
	
	var costs = structure_costs.get(structure_type, {})
	return game_manager.resources.can_afford(
		biomass_cost=costs.get("biomass", 0),
		minerals_cost=costs.get("minerals", 0)
	)

func can_afford_resource(resource_type: String) -> bool:
	if not game_manager or not game_manager.resources:
		return false
	
	var costs = resource_costs.get(resource_type, {})
	return game_manager.resources.can_afford(
		biomass_cost=costs.get("biomass", 0),
		minerals_cost=costs.get("minerals", 0)
	)

func spend_unit_resources(unit_type: String):
	if not game_manager or not game_manager.resources:
		return
	
	var costs = unit_costs.get(unit_type, {})
	game_manager.resources.spend_resources(
		biomass_cost=costs.get("biomass", 0),
		genetic_material_cost=costs.get("genetic_material", 0),
		secretions_cost=costs.get("secretions", 0)
	)

func spend_structure_resources(structure_type: String):
	if not game_manager or not game_manager.resources:
		return
	
	var costs = structure_costs.get(structure_type, {})
	game_manager.resources.spend_resources(
		biomass_cost=costs.get("biomass", 0),
		minerals_cost=costs.get("minerals", 0)
	)

func spend_resource_resources(resource_type: String):
	if not game_manager or not game_manager.resources:
		return
	
	var costs = resource_costs.get(resource_type, {})
	game_manager.resources.spend_resources(
		biomass_cost=costs.get("biomass", 0),
		minerals_cost=costs.get("minerals", 0)
	)

# Button signal handlers
func _on_worker_drone_button_pressed():
	start_building_mode(BuildMode.UNIT, "worker_drone")

func _on_harvester_button_pressed():
	start_building_mode(BuildMode.UNIT, "harvester")

func _on_queen_button_pressed():
	start_building_mode(BuildMode.UNIT, "queen")

func _on_larvae_button_pressed():
	start_building_mode(BuildMode.UNIT, "larvae")

func _on_spire_button_pressed():
	start_building_mode(BuildMode.STRUCTURE, "spire")

func _on_nursery_button_pressed():
	start_building_mode(BuildMode.STRUCTURE, "nursery")

func _on_creep_node_button_pressed():
	start_building_mode(BuildMode.STRUCTURE, "creep_node")

func start_building_mode(mode: BuildMode, type: String):
	current_build_mode = mode
	
	match mode:
		BuildMode.UNIT:
			selected_unit_type = type
			build_preview.texture = create_gradient_texture(16, 16, Color(0.2, 0.6, 0.8), Color(0.1, 0.4, 0.6))
		BuildMode.STRUCTURE:
			selected_structure_type = type
			var size: int
			if type == "spire":
				size = 24
			elif type == "nursery":
				size = 32
			else:
				size = 16
			build_preview.texture = create_gradient_texture(size, size, Color(0.4, 0.8, 0.4), Color(0.2, 0.6, 0.2))
		BuildMode.RESOURCE:
			selected_resource_type = type
			build_preview.texture = create_gradient_texture(16, 16, Color(0.2, 0.8, 0.2), Color(0.1, 0.6, 0.1))
	
	build_preview.visible = true
	print("Building mode: ", type)

func cancel_building():
	current_build_mode = BuildMode.NONE
	selected_unit_type = ""
	selected_structure_type = ""
	selected_resource_type = ""
	build_preview.visible = false
	print("Building cancelled")

# Utility function to get world 2D
func get_world_2d() -> World2D:
	return get_viewport().world_2d
