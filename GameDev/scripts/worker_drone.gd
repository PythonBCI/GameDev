extends "res://scripts/unit.gd"

# Worker Drone specific properties
@export var gathering_speed: float = 1.5
@export var resource_detection_range: float = 100.0

# Override unit type
func _ready():
	unit_type = UnitType.WORKER_DRONE
	super._ready()

# Worker drone specific behavior
func check_for_tasks():
	# Look for nearby resources to gather
	if not is_carrying and not gathering_target:
		find_nearest_resource()
	
	# If we have resources, return to hive
	if is_carrying and not return_to_hive:
		return_to_hive = true
		move_to(hive_core.global_position)

func find_nearest_resource():
	var resource_nodes = get_tree().get_nodes_in_group("resources")
	var nearest_distance = resource_detection_range
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

func complete_gathering():
	if gathering_target and gathering_target.has_method("can_be_gathered"):
		if gathering_target.can_be_gathered():
			# Gather the resource
			var resource_type = gathering_target.resource_type
			var amount = min(gathering_target.gather_amount, carry_capacity - get_total_carried())
			
			if amount > 0:
				gathering_target.gather_resource(amount)
				add_carried_resource(resource_type, amount)
				gathering_target = null
				return_to_hive = true
				move_to(hive_core.global_position)
			else:
				# Resource depleted, find another
				gathering_target = null
				find_nearest_resource()
		else:
			# Resource can't be gathered, find another
			gathering_target = null
			find_nearest_resource()

func get_total_carried() -> int:
	var total = 0
	for resource_type in carried_resources:
		total += carried_resources[resource_type]
	return total

func _on_resource_reached():
	if gathering_target and gathering_target.has_method("can_be_gathered"):
		if gathering_target.can_be_gathered():
			change_state(UnitState.GATHERING)
		else:
			gathering_target = null
			find_nearest_resource()

func _on_hive_reached():
	if is_carrying:
		# Deposit resources
		if hive_core and hive_core.has_method("add_resource"):
			for resource_type in carried_resources:
				var amount = carried_resources[resource_type]
				hive_core.add_resource(resource_type, amount)
			
			# Clear carried resources
			carried_resources.clear()
			is_carrying = false
			return_to_hive = false
			
			# Look for new resources
			change_state(UnitState.IDLE)
			find_nearest_resource()
