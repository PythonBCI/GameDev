class_name Harvester
extends Unit

# Harvester specific properties
var hunting_target: Node = null
var patrol_radius: float = 128.0
var patrol_center: Vector2
var is_patrolling: bool = false
var attack_damage: int = 5

func _ready():
	super._ready()
	unit_type = UnitType.HARVESTER
	speed = 48.0  # 48 pixels/second as per spec
	carry_capacity = 1
	patrol_center = global_position

func check_for_tasks():
	if is_carrying:
		# If carrying prey, return to hive
		return_to_hive()
	elif hunting_target:
		# Attack current target
		attack_target(hunting_target)
	else:
		# Look for prey or patrol
		look_for_prey()

func look_for_prey():
	var enemies = get_tree().get_nodes_in_group("enemies")
	var nearest_distance = INF
	hunting_target = null
	
	for enemy in enemies:
		if enemy.is_alive():
			var distance = global_position.distance_to(enemy.global_position)
			if distance < nearest_distance and distance < 200.0:  # 200 pixel detection range
				nearest_distance = distance
				hunting_target = enemy
	
	if hunting_target:
		move_to(hunting_target.global_position)
	else:
		# No prey found, patrol
		start_patrol()

func start_patrol():
	if not is_patrolling:
		is_patrolling = true
		var patrol_target = patrol_center + Vector2(
			randf_range(-patrol_radius, patrol_radius),
			randf_range(-patrol_radius, patrol_radius)
		)
		move_to(patrol_target)

func attack_target(target: Node):
	if global_position.distance_to(target.global_position) < 32.0:  # Attack range
		change_state(UnitState.ATTACKING)
		# Face the target
		look_at(target.global_position)
	else:
		# Move closer to target
		move_to(target.global_position)

func complete_attack():
	if hunting_target and hunting_target.is_alive():
		# Deal damage
		hunting_target.take_damage(attack_damage)
		
		# Check if target is defeated
		if not hunting_target.is_alive():
			# Convert to prey and carry
			convert_to_prey(hunting_target)
			hunting_target = null
		else:
			# Continue attacking
			change_state(UnitState.IDLE)
	else:
		hunting_target = null
		change_state(UnitState.IDLE)

func convert_to_prey(defeated_enemy: Node):
	# Convert defeated enemy to live prey
	var prey_value = defeated_enemy.get_prey_value()
	add_carried_resource("live_prey", prey_value)
	
	# Remove the defeated enemy
	defeated_enemy.queue_free()

func return_to_hive():
	if not is_carrying:
		return
	
	move_to(hive_core.global_position)

func _on_hive_reached():
	if is_carrying and "live_prey" in carried_resources:
		# Convert live prey to biomass at hive
		var prey_amount = carried_resources["live_prey"]
		hive_core.add_resource("live_prey", prey_amount)
		
		# Clear carried resources
		carried_resources.clear()
		is_carrying = false
		
		# Return to idle state
		change_state(UnitState.IDLE)

func _on_movement_finished():
	if is_carrying and global_position.distance_to(hive_core.global_position) < 16.0:
		_on_hive_reached()
	elif hunting_target and global_position.distance_to(hunting_target.global_position) < 32.0:
		attack_target(hunting_target)
	else:
		change_state(UnitState.IDLE)

func _on_patrol_finished():
	is_patrolling = false
	change_state(UnitState.IDLE)
