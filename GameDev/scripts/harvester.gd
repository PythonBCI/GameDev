class_name Harvester
extends Unit

# Harvester specific properties
var hunting_target: Node = null
var attack_damage: int = 25
var attack_range: float = 32.0
var attack_cooldown: float = 2.0
var can_attack: bool = true

func _ready():
	super._ready()
	unit_type = UnitType.HARVESTER
	speed = 48.0  # 48 pixels/second as per spec
	carry_capacity = 2
	health = 150
	max_health = 150
	
	# Add to hive units group
	add_to_group("hive_units")

func check_for_tasks():
	if is_carrying:
		# If carrying resources, return to hive
		if not return_to_hive:
			return_to_hive = true
			move_to(hive_core.global_position)
	else:
		# Look for enemies to hunt or resources to gather
		var nearest_enemy = find_nearest_enemy()
		if nearest_enemy:
			hunt_enemy(nearest_enemy)
		else:
			# Fall back to resource gathering
			find_nearest_resource()

func find_nearest_enemy() -> Node:
	var enemies = get_tree().get_nodes_in_group("enemies")
	var nearest_distance = INF
	var nearest_enemy = null
	
	for enemy in enemies:
		if enemy.has_method("is_alive") and enemy.is_alive():
			var distance = global_position.distance_to(enemy.global_position)
			if distance < nearest_distance:
				nearest_distance = distance
				nearest_enemy = enemy
	
	return nearest_enemy

func hunt_enemy(enemy: Node):
	hunting_target = enemy
	change_state(UnitState.ATTACKING)
	move_to(enemy.global_position)

func _on_movement_finished():
	if hunting_target and global_position.distance_to(hunting_target.global_position) <= attack_range:
		attack_enemy(hunting_target)
	elif return_to_hive and global_position.distance_to(hive_core.global_position) < 16.0:
		_on_hive_reached()
	elif gathering_target and global_position.distance_to(gathering_target.global_position) < 16.0:
		start_gathering(gathering_target)
	else:
		change_state(UnitState.IDLE)

func attack_enemy(enemy: Node):
	if not can_attack:
		return
	
	# Face the enemy
	var direction = (enemy.global_position - global_position).normalized()
	
	# Deal damage
	if enemy.has_method("take_damage"):
		enemy.take_damage(attack_damage)
	
	# Start attack cooldown
	can_attack = false
	var cooldown_timer = Timer.new()
	cooldown_timer.wait_time = attack_cooldown
	cooldown_timer.one_shot = true
	cooldown_timer.timeout.connect(_on_attack_cooldown_finished)
	add_child(cooldown_timer)
	cooldown_timer.start()
	
	# Check if enemy is dead
	if enemy.has_method("is_alive") and not enemy.is_alive():
		# Enemy defeated, collect resources
		collect_enemy_resources(enemy)
		hunting_target = null
		change_state(UnitState.IDLE)
	else:
		# Continue hunting
		change_state(UnitState.ATTACKING)

func _on_attack_cooldown_finished():
	can_attack = true

func collect_enemy_resources(enemy: Node):
	# Collect genetic material from defeated enemies
	if enemy.has_method("get_genetic_material"):
		var amount = enemy.get_genetic_material()
		add_carried_resource("genetic_material", amount)
	elif enemy.has_method("get_live_prey"):
		var amount = enemy.get_live_prey()
		add_carried_resource("live_prey", amount)
	else:
		# Default resource drop
		add_carried_resource("genetic_material", 1)

func complete_attack():
	# Attack completed, check if we should continue hunting
	if hunting_target and hunting_target.has_method("is_alive") and hunting_target.is_alive():
		# Continue hunting
		change_state(UnitState.ATTACKING)
	else:
		# Target defeated or lost, return to idle
		hunting_target = null
		change_state(UnitState.IDLE)

# Override resource gathering to include hunting behavior
func find_nearest_resource():
	var resources = get_tree().get_nodes_in_group("resources")
	var nearest_distance = INF
	nearest_resource = null
	
	for resource in resources:
		if resource.has_method("can_be_gathered") and resource.can_be_gathered():
			var distance = global_position.distance_to(resource.global_position)
			if distance < nearest_distance:
				nearest_distance = distance
				nearest_resource = resource
	
	if nearest_resource:
		move_to(nearest_resource.global_position)
		gathering_target = nearest_resource

func _on_resource_reached():
	if gathering_target and not is_carrying:
		start_gathering(gathering_target)

func start_gathering(resource_node: Node):
	gathering_target = resource_node
	change_state(UnitState.GATHERING)

func complete_gathering():
	if gathering_target and gathering_target.has_method("can_be_gathered"):
		if gathering_target.can_be_gathered():
			var resource_type = gathering_target.get_resource_type_name()
			var amount = min(1, gathering_target.get_resource_amount())
			
			if amount > 0:
				add_carried_resource(resource_type, amount)
				return_to_hive = true
				move_to(hive_core.global_position)
			else:
				# Resource depleted, find another
				gathering_target = null
				change_state(UnitState.IDLE)
		else:
			change_state(UnitState.IDLE)
	else:
		change_state(UnitState.IDLE)

func _on_hive_reached():
	if is_carrying:
		# Deposit resources
		for resource_type in carried_resources:
			var amount = carried_resources[resource_type]
			if hive_core and hive_core.has_method("add_resource"):
				hive_core.add_resource(resource_type, amount)
		
		# Clear carried resources
		carried_resources.clear()
		is_carrying = false
		return_to_hive = false
		
		# Return to idle state
		change_state(UnitState.IDLE)
