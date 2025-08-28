class_name Queen
extends Unit

# Queen specific properties
var egg_laying_timer: Timer
var egg_laying_rate: float = 10.0  # Lay eggs every 10 seconds
var max_eggs_per_lay: int = 3
var egg_laying_cost: int = 2  # Secretions cost per egg

func _ready():
	super._ready()
	unit_type = UnitType.QUEEN
	speed = 24.0  # 24 pixels/second as per spec
	carry_capacity = 3
	health = 300
	max_health = 300
	
	# Add to hive units group
	add_to_group("hive_units")
	
	# Setup egg laying
	setup_egg_laying()

func setup_egg_laying():
	egg_laying_timer = Timer.new()
	egg_laying_timer.wait_time = egg_laying_rate
	egg_laying_timer.autostart = true
	egg_laying_timer.timeout.connect(_on_egg_laying_timeout)
	add_child(egg_laying_timer)

func check_for_tasks():
	if is_carrying:
		# If carrying resources, return to hive
		if not return_to_hive:
			return_to_hive = true
			move_to(hive_core.global_position)
	else:
		# Queens primarily lay eggs and manage the hive
		# They can also gather resources if needed
		if should_lay_eggs():
			lay_eggs()
		else:
			# Look for resources to gather
			find_nearest_resource()

func should_lay_eggs() -> bool:
	# Check if we have enough secretions and are near the hive
	if not hive_core:
		return false
	
	var distance_to_hive = global_position.distance_to(hive_core.global_position)
	if distance_to_hive > 64:  # Must be close to hive to lay eggs
		return false
	
	# Check if we have enough secretions
	if hive_core.has_method("get_resource_amount"):
		var secretions = hive_core.get_resource_amount("secretions")
		return secretions >= egg_laying_cost
	return false

func lay_eggs():
	# Move to hive if not already there
	if global_position.distance_to(hive_core.global_position) > 32:
		move_to(hive_core.global_position)
		return
	
	# Lay eggs
	var eggs_to_lay = min(max_eggs_per_lay, 3)  # Max 3 eggs per laying
	
	if hive_core.has_method("get_resource_amount"):
		var secretions = hive_core.get_resource_amount("secretions")
		eggs_to_lay = min(eggs_to_lay, secretions / egg_laying_cost)
		
		if eggs_to_lay > 0:
			# Spend secretions and add eggs
			if hive_core.has_method("add_resource"):
				hive_core.add_resource("eggs", eggs_to_lay)
				hive_core.add_resource("secretions", -eggs_to_lay * egg_laying_cost)
				
				print("Queen laid ", eggs_to_lay, " eggs")
				
				# Start egg laying cooldown
				egg_laying_timer.start()

func _on_egg_laying_timeout():
	# Reset egg laying timer
	egg_laying_timer.start()

func _on_movement_finished():
	if return_to_hive and global_position.distance_to(hive_core.global_position) < 16.0:
		_on_hive_reached()
	elif gathering_target and global_position.distance_to(gathering_target.global_position) < 16.0:
		start_gathering(gathering_target)
	else:
		change_state(UnitState.IDLE)

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

# Override resource gathering for queens
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
