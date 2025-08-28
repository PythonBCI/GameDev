extends "res://scripts/unit.gd"

# Worker Drone specific properties
@export var gathering_speed: float = 1.5
@export var resource_detection_range: float = 150.0
@export var gathering_time: float = 2.0

# AI state
var current_task: String = "idle"
var target_resource: Node = null
var is_gathering: bool = false
var gathering_timer: Timer

# Override unit type and stats
func _ready():
	unit_type = UnitType.WORKER_DRONE
	speed = 32.0
	carry_capacity = 1
	health = 100
	max_health = 100
	super._ready()
	
	# Setup gathering timer
	setup_gathering_timer()
	
	# Add to groups
	add_to_group("worker_drones")
	add_to_group("hive_units")

func setup_gathering_timer():
	gathering_timer = Timer.new()
	gathering_timer.wait_time = gathering_time
	gathering_timer.one_shot = true
	gathering_timer.timeout.connect(_on_gathering_complete)
	add_child(gathering_timer)

# Enhanced AI behavior
func check_for_tasks():
	match current_task:
		"idle":
			# Look for resources to gather
			if not is_carrying and not target_resource:
				find_nearest_resource()
			elif is_carrying:
				return_to_hive()
		"gathering":
			# Continue gathering
			pass
		"returning":
			# Continue returning to hive
			pass

func find_nearest_resource():
	var resource_nodes = get_tree().get_nodes_in_group("resources")
	var nearest_distance = resource_detection_range
	target_resource = null
	
	for resource in resource_nodes:
		if resource.has_method("can_be_gathered") and resource.can_be_gathered():
			var distance = global_position.distance_to(resource.global_position)
			if distance < nearest_distance:
				nearest_distance = distance
				target_resource = resource
	
	if target_resource:
		current_task = "gathering"
		move_to(target_resource.global_position)
		print("Worker drone found resource at: ", target_resource.global_position)

func return_to_hive():
	if not hive_core:
		return
	
	current_task = "returning"
	var return_to_hive_flag = true
	move_to(hive_core.global_position)

func _on_movement_finished():
	if current_task == "gathering" and target_resource:
		# Reached resource, start gathering
		start_gathering()
	elif current_task == "returning":
		# Reached hive, deposit resources
		deposit_resources()

func start_gathering():
	if not target_resource or not target_resource.has_method("can_be_gathered"):
		return
	
	if target_resource.can_be_gathered():
		is_gathering = true
		change_state(UnitState.GATHERING)
		gathering_timer.start()
		print("Worker drone started gathering")
	else:
		# Resource can't be gathered, find another
		target_resource = null
		current_task = "idle"

func _on_gathering_complete():
	if target_resource and target_resource.has_method("gather_resource"):
		# Collect the resource
		var resource_type = target_resource.resource_type
		var amount = min(target_resource.gather_amount, carry_capacity)
		
		if amount > 0:
			target_resource.gather_resource(amount)
			add_carried_resource(resource_type, amount)
			print("Worker drone collected ", amount, " ", resource_type)
			
			# Clear target and return to hive
			target_resource = null
			is_gathering = false
			return_to_hive()
		else:
			# Resource depleted, find another
			target_resource = null
			is_gathering = false
			current_task = "idle"

func deposit_resources():
	if not hive_core or not hive_core.has_method("add_resource"):
		return
	
	# Deposit all carried resources
	for resource_type in carried_resources:
		var amount = carried_resources[resource_type]
		hive_core.add_resource(resource_type, amount)
		print("Worker drone deposited ", amount, " ", resource_type)
	
	# Clear carried resources
	carried_resources.clear()
	is_carrying = false
	var return_to_hive_flag = false
	current_task = "idle"
	
	# Look for new resources
	find_nearest_resource()

func _on_resource_reached():
	if current_task == "gathering" and target_resource:
		start_gathering()

func _on_hive_reached():
	if current_task == "returning":
		deposit_resources()

# Override movement to slow down when carrying
func update_movement(delta):
	if is_carrying:
		# Move slower when carrying resources
		var adjusted_speed = speed * 0.5
		if path.size() > 0 and current_path_index < path.size():
			var target = path[current_path_index]
			var direction = (target - global_position).normalized()
			velocity = direction * adjusted_speed
			
			move_and_slide()
			
			# Check if we've reached the current waypoint
			if global_position.distance_to(target) < 8.0:
				current_path_index += 1
				if current_path_index >= path.size():
					_on_movement_finished()
	else:
		# Normal movement
		super.update_movement(delta)
