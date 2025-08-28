extends "res://scripts/unit.gd"

# Larvae specific properties
@export var growth_time: float = 30.0  # seconds to grow into worker drone
@export var growth_progress: float = 0.0

# Growth state
var growth_timer: Timer
var is_growing: bool = true

# Override unit type and stats
func _ready():
	unit_type = UnitType.LARVAE
	speed = 16.0  # Very slow
	carry_capacity = 0  # Can't carry resources
	health = 50
	max_health = 50
	super._ready()
	
	# Setup growth timer
	setup_growth_timer()

func setup_growth_timer():
	growth_timer = Timer.new()
	growth_timer.wait_time = 1.0  # Check every second
	growth_timer.one_shot = false
	growth_timer.timeout.connect(_on_growth_timer_timeout)
	add_child(growth_timer)
	growth_timer.start()

# Larvae behavior - just grow, can't gather resources
func check_for_tasks():
	# Larvae only grow, they don't gather resources or move around
	pass

func _on_growth_timer_timeout():
	if not is_growing:
		return
	
	growth_progress += 1.0
	
	if growth_progress >= growth_time:
		transform_into_worker_drone()

func transform_into_worker_drone():
	is_growing = false
	
	# Create a worker drone at the larvae's position
	var worker_drone_scene = load("res://scenes/units/worker_drone.tscn")
	if worker_drone_scene:
		var worker_drone = worker_drone_scene.instantiate()
		worker_drone.global_position = global_position
		
		# Add to the scene
		var units_container = get_node("/root/Main/Units")
		if units_container:
			units_container.add_child(worker_drone)
			worker_drone.add_to_group("hive_units")
		
		# Remove the larvae
		queue_free()

# Override resource gathering methods - larvae can't gather
func find_nearest_resource():
	pass

func complete_gathering():
	pass

func get_total_carried() -> int:
	return 0

# Override damage to make larvae more fragile
func take_damage(amount: int):
	health -= amount * 2  # Larvae take double damage
	if health <= 0:
		die()

# Larvae don't return to hive
func _on_hive_reached():
	pass
