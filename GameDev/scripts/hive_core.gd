extends StaticBody2D

# Hive core properties
@export var health: int = 100
@export var max_health: int = 100
@export var max_units: int = 20
@export var spawn_position: Vector2 = Vector2(0, 0)

# Resources
@onready var resources: GameResources = GameResources.new()
var current_units: int = 0

# Spawning
var spawn_timer: Timer
var spawn_interval: float = 10.0
var spawn_cost: int = 5

# Unit scenes
var unit_scenes: Dictionary = {}

func _ready():
	# Initialize resources
	resources.biomass = 10
	resources.minerals = 5
	
	# Setup spawn position
	spawn_position = global_position + Vector2(32, 0)
	
	# Setup spawning
	setup_spawning()
	
	# Load unit scenes
	load_unit_scenes()
	
	# Add to groups
	add_to_group("hive_cores")
	add_to_group("structures")

func setup_spawning():
	spawn_timer = Timer.new()
	spawn_timer.wait_time = spawn_interval
	spawn_timer.one_shot = false
	spawn_timer.timeout.connect(_on_spawn_timer_timeout)
	add_child(spawn_timer)
	spawn_timer.start()

func load_unit_scenes():
	# Load unit scene files
	var worker_drone_scene = load("res://scenes/units/worker_drone.tscn")
	if worker_drone_scene:
		unit_scenes["worker_drone"] = worker_drone_scene

func _on_spawn_timer_timeout():
	# Auto-spawn worker drones if we have resources and space
	if current_units < max_units and resources.can_afford(spawn_cost, 0, 0, 0, 0, 0):
		spawn_unit("worker_drone")
		resources.spend_resources(spawn_cost, 0, 0, 0, 0, 0)

func spawn_unit(unit_type: String) -> bool:
	if current_units >= max_units:
		return false
	
	if unit_type in unit_scenes:
		var unit_scene = unit_scenes[unit_type]
		var unit_instance = unit_scene.instantiate()
		
		# Set spawn position
		unit_instance.global_position = spawn_position
		
		# Add to units container
		var units_container = get_node("/root/Main/Units")
		if units_container:
			units_container.add_child(unit_instance)
			current_units += 1
			
			# Add to hive units group
			unit_instance.add_to_group("hive_units")
			
			return true
	
	return false

func manual_spawn_unit(unit_type: String) -> bool:
	# Manual spawning costs more
	var cost = spawn_cost * 2
	if resources.can_afford(cost, 0, 0, 0, 0, 0):
		if spawn_unit(unit_type):
			resources.spend_resources(cost, 0, 0, 0, 0, 0)
			return true
	return false

func add_resource(resource_type: String, amount: int) -> bool:
	match resource_type:
		"biomass":
			return resources.add_biomass(amount)
		"live_prey":
			return resources.add_live_prey(amount)
		"genetic_material":
			return resources.add_genetic_material(amount)
		"minerals":
			return resources.add_minerals(amount)
		"secretions":
			return resources.add_secretions(amount)
		"eggs":
			return resources.add_eggs(amount)
		_:
			return false

func get_resource_amount(resource_type: String) -> int:
	match resource_type:
		"biomass":
			return resources.biomass
		"live_prey":
			return resources.live_prey
		"genetic_material":
			return resources.genetic_material
		"minerals":
			return resources.minerals
		"secretions":
			return resources.secretions
		"eggs":
			return resources.eggs
		_:
			return 0

func get_total_resources() -> GameResources:
	return resources

func get_current_units_count() -> int:
	return current_units

func get_max_units() -> int:
	return max_units

func is_victory_condition_met() -> bool:
	# Check if we have 50+ units (victory condition)
	return current_units >= 50

func is_defeat_condition_met() -> bool:
	# Check if hive core is destroyed or population collapsed
	return health <= 0 or current_units < 3

func get_resource_storage_info() -> Dictionary:
	var biomass_info = str(resources.biomass) + "/" + str(resources.BIOMASS_LIMIT)
	var live_prey_info = str(resources.live_prey) + "/" + str(resources.LIVE_PREY_LIMIT)
	var genetic_info = str(resources.genetic_material) + "/" + str(resources.GENETIC_MATERIAL_LIMIT)
	var minerals_info = str(resources.minerals) + "/" + str(resources.MINERALS_LIMIT)
	var secretions_info = str(resources.secretions) + "/" + str(resources.SECRETIONS_LIMIT)
	var eggs_info = str(resources.eggs) + "/" + str(resources.EGGS_LIMIT)
	
	return {
		"biomass": biomass_info,
		"live_prey": live_prey_info,
		"genetic_material": genetic_info,
		"minerals": minerals_info,
		"secretions": secretions_info,
		"eggs": eggs_info
	}

func on_unit_died():
	current_units -= 1
	if current_units < 0:
		current_units = 0

func take_damage(amount: int):
	health -= amount
	if health <= 0:
		die()

func die():
	# Game over if hive core is destroyed
	get_tree().change_scene_to_file("res://scenes/game_over.tscn")

func _input_event(viewport, event, shape_idx):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		# Click hive core to manually spawn units
		if resources.can_afford(spawn_cost * 2, 0, 0, 0, 0, 0):
			manual_spawn_unit("worker_drone")
			print("Manual spawn triggered! Units: ", current_units)
