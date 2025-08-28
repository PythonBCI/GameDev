class_name OpposingHiveCore
extends StaticBody2D

# Opposing hive properties
@export var health: int = 150
@export var max_health: int = 150
@export var max_units: int = 15
@export var spawn_interval: float = 12.0
@export var aggression_level: float = 0.7

# Spawning
var spawn_timer: Timer
var current_units: int = 0
var unit_scenes: Dictionary = {}

# AI behavior
var target_hive: Node
var is_aggressive: bool = false
var last_attack_time: float = 0.0
var attack_cooldown: float = 30.0

func _ready():
	# Setup spawning
	setup_spawning()
	
	# Load unit scenes
	load_unit_scenes()
	
	# Add to groups
	add_to_group("opposing_hives")
	add_to_group("enemy_structures")
	
	# Find target hive
	find_target_hive()
	
	# Start aggressive behavior
	start_aggressive_behavior()

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

func find_target_hive():
	# Find the player's hive core
	var player_hive = get_node("/root/Main/Structures/HiveCore")
	if player_hive:
		target_hive = player_hive

func start_aggressive_behavior():
	# Start aggressive behavior after a delay
	var aggression_timer = Timer.new()
	aggression_timer.wait_time = 60.0  # Start aggressive after 1 minute
	aggression_timer.one_shot = true
	aggression_timer.timeout.connect(_on_aggression_start)
	add_child(aggression_timer)
	aggression_timer.start()

func _on_aggression_start():
	is_aggressive = true
	print("Opposing hive has become aggressive!")

func _on_spawn_timer_timeout():
	# Auto-spawn units if we have space
	if current_units < max_units:
		spawn_unit("worker_drone")
		
		# If aggressive, send units to attack
		if is_aggressive and target_hive:
			send_units_to_attack()

func spawn_unit(unit_type: String) -> bool:
	if current_units >= max_units:
		return false
	
	if unit_type in unit_scenes:
		var unit_scene = unit_scenes[unit_type]
		var unit_instance = unit_scene.instantiate()
		
		# Set spawn position
		var spawn_offset = Vector2(randf_range(-24, 24), randf_range(-24, 24))
		unit_instance.global_position = global_position + spawn_offset
		
		# Add to units container
		var units_container = get_node("/root/Main/Units")
		if units_container:
			units_container.add_child(unit_instance)
			current_units += 1
			
			# Add to opposing units group
			unit_instance.add_to_group("opposing_units")
			unit_instance.add_to_group("enemies")
			
			# Set unit color to red
			if unit_instance.has_node("Sprite2D"):
				unit_instance.get_node("Sprite2D").modulate = Color(0.8, 0.2, 0.2)
			
			return true
	
	return false

func send_units_to_attack():
	if not target_hive or not is_aggressive:
		return
	
	var current_time = Time.get_time_dict_from_system()["unix"]
	if current_time - last_attack_time < attack_cooldown:
		return
	
	# Find nearby opposing units
	var opposing_units = get_tree().get_nodes_in_group("opposing_units")
	var attack_force: Array[Node] = []
	
	for unit in opposing_units:
		if unit.global_position.distance_to(global_position) < 100.0:
			attack_force.append(unit)
	
	# Send attack force
	if attack_force.size() >= 3:
		for unit in attack_force:
			if unit.has_method("attack_target"):
				unit.attack_target(target_hive)
		
		last_attack_time = current_time
		print("Opposing hive sending attack force of ", attack_force.size(), " units!")

func take_damage(amount: int):
	health -= amount
	
	# Become more aggressive when damaged
	if health < max_health * 0.5 and not is_aggressive:
		is_aggressive = true
		print("Opposing hive is enraged!")
	
	if health <= 0:
		die()

func die():
	# Remove all opposing units
	var opposing_units = get_tree().get_nodes_in_group("opposing_units")
	for unit in opposing_units:
		if unit.get_parent() == get_node("/root/Main/Units"):
			unit.queue_free()
	
	# Remove hive
	queue_free()

func get_current_units_count() -> int:
	return current_units

func get_max_units() -> int:
	return max_units

func on_unit_died():
	current_units -= 1
	if current_units < 0:
		current_units = 0

func is_aggressive() -> bool:
	return is_aggressive
