class_name OpposingWorker
extends "res://scripts/unit.gd"

# Opposing worker properties
@export var attack_damage: int = 15
@export var attack_range: float = 32.0
@export var detection_range: float = 120.0

# AI state
var current_target: Node = null
var is_attacking: bool = false
var last_attack_time: float = 0.0
var attack_cooldown: float = 2.0

# Override unit type and stats
func _ready():
	unit_type = UnitType.OPPOSING_WORKER
	speed = 28.0
	health = 80
	max_health = 80
	super._ready()
	
	# Add to groups
	add_to_group("opposing_workers")
	add_to_group("enemies")
	
	# Set color to red
	if has_node("Sprite2D"):
		get_node("Sprite2D").modulate = Color(0.8, 0.2, 0.2)

# Enhanced AI behavior for opposing units
func check_for_tasks():
	if current_target and is_target_valid(current_target):
		# Continue attacking current target
		attack_target(current_target)
	elif not current_target:
		# Look for new targets
		find_target()

func find_target():
	# Look for player units or structures
	var potential_targets: Array[Node] = []
	
	# Add player units
	var player_units = get_tree().get_nodes_in_group("hive_units")
	potential_targets.append_array(player_units)
	
	# Add player structures
	var player_structures = get_tree().get_nodes_in_group("hive_cores")
	player_structures.append_array(get_tree().get_nodes_in_group("nests"))
	potential_targets.append_array(player_structures)
	
	# Find closest target
	var nearest_distance = detection_range
	current_target = null
	
	for target in potential_targets:
		if target != self and is_target_valid(target):
			var distance = global_position.distance_to(target.global_position)
			if distance < nearest_distance:
				nearest_distance = distance
				current_target = target
	
	if current_target:
		print("Opposing worker found target: ", current_target.name)
		move_to(current_target.global_position)

func is_target_valid(target: Node) -> bool:
	if not target or not is_instance_valid(target):
		return false
	
	# Check if target is still alive
	if target.has_method("get_health"):
		return target.get_health() > 0
	elif target.has_method("health"):
		return target.health > 0
	
	return true

func attack_target(target: Node):
	if not is_target_valid(target):
		current_target = null
		return
	
	var distance = global_position.distance_to(target.global_position)
	
	if distance <= attack_range:
		# In attack range, perform attack
		var current_time = Time.get_time_dict_from_system()["unix"]
		if current_time - last_attack_time >= attack_cooldown:
			perform_attack(target)
			last_attack_time = current_time
	else:
		# Move towards target
		move_to(target.global_position)

func perform_attack(target: Node):
	if not target.has_method("take_damage"):
		return
	
	# Deal damage to target
	target.take_damage(attack_damage)
	print("Opposing worker attacked ", target.name, " for ", attack_damage, " damage!")
	
	# Check if target is destroyed
	if target.has_method("get_health") and target.get_health() <= 0:
		print("Opposing worker destroyed ", target.name, "!")
		current_target = null
	elif target.has_method("health") and target.health <= 0:
		print("Opposing worker destroyed ", target.name, "!")
		current_target = null

func _on_movement_finished():
	if current_target and is_target_valid(current_target):
		# Reached target, start attacking
		attack_target(current_target)
	else:
		# Target invalid, find new one
		current_target = null
		find_target()

func take_damage(amount: int):
	health -= amount
	
	if health <= 0:
		die()
	else:
		# Become more aggressive when damaged
		if not current_target:
			find_target()

func die():
	# Notify opposing hive
	var opposing_hives = get_tree().get_nodes_in_group("opposing_hives")
	for hive in opposing_hives:
		if hive.has_method("on_unit_died"):
			hive.on_unit_died()
	
	# Remove from scene
	queue_free()

func is_alien() -> bool:
	return true
