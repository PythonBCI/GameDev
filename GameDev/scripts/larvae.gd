class_name Larvae
extends Unit

# Larvae specific properties
var growth_timer: Timer
var growth_time: float = 30.0  # 30 seconds to grow into a worker drone
var growth_progress: float = 0.0
var is_growing: bool = true

func _ready():
	super._ready()
	unit_type = UnitType.LARVAE
	speed = 16.0  # 16 pixels/second as per spec
	carry_capacity = 0  # Larvae can't carry resources
	health = 50
	max_health = 50
	
	# Add to hive units group
	add_to_group("hive_units")
	
	# Setup growth
	setup_growth()

func setup_growth():
	growth_timer = Timer.new()
	growth_timer.wait_time = 0.1  # Update every 0.1 seconds
	growth_timer.timeout.connect(_on_growth_tick)
	add_child(growth_timer)
	growth_timer.start()

func check_for_tasks():
	# Larvae don't do much except grow
	# They can move around slowly but don't gather resources
	if not is_growing:
		# If fully grown, find a place to transform
		find_transformation_spot()

func find_transformation_spot():
	# Look for a spot near the hive to transform
	if hive_core:
		var target_position = hive_core.global_position + Vector2(
			randf_range(-32, 32),
			randf_range(-32, 32)
		)
		move_to(target_position)

func _on_growth_tick():
	if not is_growing:
		return
	
	growth_progress += 0.1 / growth_time
	
	if growth_progress >= 1.0:
		complete_growth()

func complete_growth():
	is_growing = false
	growth_timer.stop()
	
	print("Larvae has grown into a worker drone!")
	
	# Transform into a worker drone
	transform_into_worker_drone()

func transform_into_worker_drone():
	# Create a new worker drone at this position
	var worker_drone_scene = load("res://scenes/units/worker_drone.tscn")
	if worker_drone_scene:
		var worker_drone = worker_drone_scene.instantiate()
		worker_drone.global_position = global_position
		
		# Add to the same parent
		var parent = get_parent()
		if parent:
			parent.add_child(worker_drone)
			
			# Remove this larvae
			queue_free()
	else:
		print("Failed to load worker drone scene for transformation")

func _on_movement_finished():
	# Larvae don't have complex movement tasks
	change_state(UnitState.IDLE)

# Override resource gathering - larvae can't gather resources
func find_nearest_resource():
	# Larvae don't gather resources
	pass

func start_gathering(resource_node: Node):
	# Larvae don't gather resources
	pass

func complete_gathering():
	# Larvae don't gather resources
	pass

func _on_resource_reached():
	# Larvae don't gather resources
	pass

func _on_hive_reached():
	# Larvae don't carry resources
	pass

# Override damage to make larvae more fragile
func take_damage(amount: int):
	health -= amount * 2  # Larvae take double damage
	if health <= 0:
		die()

func get_growth_progress() -> float:
	return growth_progress

func is_fully_grown() -> bool:
	return growth_progress >= 1.0
