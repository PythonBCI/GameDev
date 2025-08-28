class_name HiveCore
extends Structure

# Hive Core specific properties
@export var unit_spawn_timer: Timer
@export var unit_spawn_rate: float = 5.0  # Spawn unit every 5 seconds
@export var max_units: int = 20

# Resource storage
var resources: GameResources
var current_units: int = 0

# Unit spawning
var spawn_position: Vector2
var unit_scenes: Dictionary = {}

func _ready():
	super._ready()
	structure_type = StructureType.HIVE_CORE
	health = 200
	max_health = 200
	is_constructed = true  # Hive Core starts constructed
	
	setup_hive_core()
	add_to_group("hive_core")

func setup_hive_core():
	# Initialize resource storage
	resources = GameResources.new()
	
	# Set spawn position (slightly offset from core)
	spawn_position = global_position + Vector2(32, 0)
	
	# Setup unit spawning
	setup_unit_spawning()
	
	# Load unit scenes
	load_unit_scenes()

func setup_unit_spawning():
	unit_spawn_timer = Timer.new()
	unit_spawn_timer.wait_time = unit_spawn_rate
	unit_spawn_timer.autostart = true
	unit_spawn_timer.timeout.connect(_on_unit_spawn_timeout)
	add_child(unit_spawn_timer)

func load_unit_scenes():
	# Load unit scene files
	unit_scenes["worker_drone"] = preload("res://scenes/units/worker_drone.tscn")
	unit_scenes["harvester"] = preload("res://scenes/units/harvester.tscn")
	unit_scenes["queen"] = preload("res://scenes/units/queen.tscn")
	unit_scenes["larvae"] = preload("res://scenes/units/larvae.tscn")

func on_construction_complete():
	# Hive Core starts constructed, so this won't be called initially
	pass

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

func _on_unit_spawn_timeout():
	# Auto-spawn worker drones if we have resources
	if resources.can_afford(biomass_cost=1):
		spawn_unit("worker_drone")
		resources.spend_resources(biomass_cost=1)
	
	# Also spawn a worker drone if we have less than 3 units
	if current_units < 3 and resources.can_afford(biomass_cost=1):
		spawn_unit("worker_drone")
		resources.spend_resources(biomass_cost=1)

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
	return {
		"biomass": str(resources.biomass) + "/" + str(resources.BIOMASS_LIMIT),
		"live_prey": str(resources.live_prey) + "/" + str(resources.LIVE_PREY_LIMIT),
		"genetic_material": str(resources.genetic_material) + "/" + str(resources.GENETIC_MATERIAL_LIMIT),
		"minerals": str(resources.minerals) + "/" + str(resources.MINERALS_LIMIT),
		"secretions": str(resources.secretions) + "/" + str(resources.SECRETIONS_LIMIT),
		"eggs": str(resources.eggs) + "/" + str(resources.EGGS_LIMIT)
	}

func on_unit_died():
	current_units -= 1
	if current_units < 0:
		current_units = 0
