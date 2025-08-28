class_name Nest
extends StaticBody2D

# Nest properties
@export var health: int = 50
@export var max_health: int = 50
@export var spawn_interval: float = 15.0
@export var max_units: int = 5
@export var spawn_cost: int = 1

# Spawning
var spawn_timer: Timer
var current_units: int = 0
var unit_scenes: Dictionary = {}

# Corruption
var corruption_system: Node

func _ready():
	# Setup spawning
	setup_spawning()
	
	# Load unit scenes
	load_unit_scenes()
	
	# Add to groups
	add_to_group("nests")
	add_to_group("structures")
	add_to_group("corruption_sources")
	
	# Get corruption system
	corruption_system = get_node("/root/Main/CorruptionSystem")
	
	# Start corruption
	if corruption_system:
		corruption_system.add_corruption_source(self)

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
	# Auto-spawn worker drones if we have space and resources
	if current_units < max_units:
		spawn_unit("worker_drone")

func spawn_unit(unit_type: String) -> bool:
	if current_units >= max_units:
		return false
	
	if unit_type in unit_scenes:
		var unit_scene = unit_scenes[unit_type]
		var unit_instance = unit_scene.instantiate()
		
		# Set spawn position (slightly offset from nest)
		var spawn_offset = Vector2(randf_range(-16, 16), randf_range(-16, 16))
		unit_instance.global_position = global_position + spawn_offset
		
		# Add to units container
		var units_container = get_node("/root/Main/Units")
		if units_container:
			units_container.add_child(unit_instance)
			current_units += 1
			
			# Add to hive units group
			unit_instance.add_to_group("hive_units")
			
			print("Nest spawned ", unit_type, "! Total units: ", current_units)
			return true
	
	return false

func take_damage(amount: int):
	health -= amount
	if health <= 0:
		die()

func die():
	# Remove from corruption sources
	if corruption_system:
		corruption_system.remove_corruption_source(self)
	
	# Remove from scene
	queue_free()

func get_current_units_count() -> int:
	return current_units

func get_max_units() -> int:
	return max_units

func on_unit_died():
	current_units -= 1
	if current_units < 0:
		current_units = 0
