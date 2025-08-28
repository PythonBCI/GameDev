extends "res://scripts/unit.gd"

# Harvester specific properties
@export var attack_damage: int = 25
@export var attack_range: float = 64.0
@export var detection_range: float = 120.0
@export var attack_cooldown: float = 1.5

# Combat state
var current_target: Node = null
var last_attack_time: float = 0.0
var is_attacking: bool = false

# Override unit type and stats
func _ready():
	unit_type = UnitType.HARVESTER
	speed = 40.0  # Faster than worker drone
	carry_capacity = 2
	health = 150
	max_health = 150
	super._ready()

# Harvester behavior - prioritize combat, fallback to resource gathering
func check_for_tasks():
	# First priority: attack nearby enemies
	if not current_target or not is_target_valid(current_target):
		find_nearest_enemy()
	
	# If no enemies, gather resources
	if not current_target and not is_carrying and not gathering_target:
		find_nearest_resource()
	
	# If carrying resources, return to hive
	if is_carrying and not return_to_hive:
		return_to_hive = true
		move_to(hive_core.global_position)

func find_nearest_enemy():
	var enemies = get_tree().get_nodes_in_group("enemies")
	var nearest_distance = detection_range
	current_target = null
	
	for enemy in enemies:
		if enemy.has_method("is_alive") and enemy.is_alive():
			var distance = global_position.distance_to(enemy.global_position)
			if distance < nearest_distance:
				nearest_distance = distance
				current_target = enemy
	
	if current_target:
		move_to(current_target.global_position)

func find_nearest_resource():
	var resource_nodes = get_tree().get_nodes_in_group("resources")
	var nearest_distance = 150.0
	nearest_resource = null
	
	for resource in resource_nodes:
		if resource.has_method("can_be_gathered") and resource.can_be_gathered():
			var distance = global_position.distance_to(resource.global_position)
			if distance < nearest_distance:
				nearest_distance = distance
				nearest_resource = resource
	
	if nearest_resource:
		gathering_target = nearest_resource
		move_to(nearest_resource.global_position)

func is_target_valid(target: Node) -> bool:
	return target and target.has_method("is_alive") and target.is_alive() and \
		   global_position.distance_to(target.global_position) <= detection_range

func _physics_process(delta):
	super._physics_process(delta)
	
	# Check if we should attack
	if current_target and is_target_valid(current_target):
		var distance = global_position.distance_to(current_target.global_position)
		if distance <= attack_range:
			attack_target(current_target)
		elif distance > detection_range:
			current_target = null

func attack_target(target: Node):
	if not target or not target.has_method("take_damage"):
		return
	
	var current_time = Time.get_time_dict_from_system()["second"]
	if current_time - last_attack_time >= attack_cooldown:
		# Deal damage
		target.take_damage(attack_damage)
		last_attack_time = current_time
		
		# Change to attacking state
		change_state(UnitState.ATTACKING)
		
		# Check if target died
		if target.has_method("is_alive") and not target.is_alive():
			# Collect genetic material and live prey
			collect_from_dead_enemy(target)
			current_target = null

func collect_from_dead_enemy(enemy: Node):
	if enemy.has_method("drop_genetic_material"):
		var genetic_amount = enemy.drop_genetic_material()
		if genetic_amount > 0:
			add_carried_resource("genetic_material", genetic_amount)
	
	if enemy.has_method("drop_live_prey"):
		var prey_amount = enemy.drop_live_prey()
		if prey_amount > 0:
			add_carried_resource("live_prey", prey_amount)

func complete_attack():
	# Return to idle state after attack
	change_state(UnitState.IDLE)

func complete_gathering():
	if gathering_target and gathering_target.has_method("can_be_gathered"):
		if gathering_target.can_be_gathered():
			var resource_type = gathering_target.resource_type
			var amount = min(gathering_target.gather_amount, carry_capacity - get_total_carried())
			
			if amount > 0:
				gathering_target.gather_resource(amount)
				add_carried_resource(resource_type, amount)
				gathering_target = null
				return_to_hive = true
				move_to(hive_core.global_position)
			else:
				gathering_target = null
				find_nearest_resource()
		else:
			gathering_target = null
			find_nearest_resource()

func get_total_carried() -> int:
	var total = 0
	for resource_type in carried_resources:
		total += carried_resources[resource_type]
	return total

func _on_hive_reached():
	if is_carrying:
		if hive_core and hive_core.has_method("add_resource"):
			for resource_type in carried_resources:
				var amount = carried_resources[resource_type]
				hive_core.add_resource(resource_type, amount)
			
			carried_resources.clear()
			is_carrying = false
			return_to_hive = false
			change_state(UnitState.IDLE)
