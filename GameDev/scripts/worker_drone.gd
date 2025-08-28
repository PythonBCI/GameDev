class_name WorkerDrone
extends Unit

# Worker Drone specific properties
var nearest_resource: Node = null
var gathering_target: Node = null
var return_to_hive: bool = false

func _ready():
	super._ready()
	unit_type = UnitType.WORKER_DRONE
	speed = 32.0  # 32 pixels/second as per spec
	carry_capacity = 1
	
	# Add to hive units group
	add_to_group("hive_units")

func check_for_tasks():
	if is_carrying:
		# If carrying resources, return to hive
		if not return_to_hive:
			return_to_hive = true
			move_to(hive_core.global_position)
	else:
		# Look for resources to gather
		find_nearest_resource()

func find_nearest_resource():
	var resources = get_tree().get_nodes_in_group("resources")
	var nearest_distance = INF
	nearest_resource = null
	
	for resource in resources:
		if resource.can_be_gathered():
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
	if gathering_target and gathering_target.can_be_gathered():
		var resource_type = gathering_target.get_resource_type_name()
		var amount = gathering_target.get_resource_amount()
		
		if amount > 0:
			add_carried_resource(resource_type, 1)
			return_to_hive = true
			move_to(hive_core.global_position)
		else:
			# Resource depleted, find another
			gathering_target = null
			change_state(UnitState.IDLE)
	else:
		change_state(UnitState.IDLE)

func _on_hive_reached():
	if is_carrying:
		# Deposit resources
		for resource_type in carried_resources:
			var amount = carried_resources[resource_type]
			hive_core.add_resource(resource_type, amount)
		
		# Clear carried resources
		carried_resources.clear()
		is_carrying = false
		return_to_hive = false
		
		# Return to idle state
		change_state(UnitState.IDLE)

func _on_movement_finished():
	if return_to_hive and global_position.distance_to(hive_core.global_position) < 16.0:
		_on_hive_reached()
	elif gathering_target and global_position.distance_to(gathering_target.global_position) < 16.0:
		start_gathering(gathering_target)
	else:
		change_state(UnitState.IDLE)
