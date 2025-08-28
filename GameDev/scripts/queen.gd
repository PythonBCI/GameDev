extends "res://scripts/unit.gd"

# Queen specific properties
@export var egg_laying_rate: float = 10.0  # seconds between egg laying
@export var max_eggs_per_lay: int = 3
@export var egg_laying_cost: Dictionary = {"biomass": 1, "genetic_material": 1}

# Egg laying state
var egg_laying_timer: Timer
var eggs_laid: int = 0
var is_egg_laying: bool = false

# Override unit type and stats
func _ready():
	unit_type = UnitType.QUEEN
	speed = 24.0  # Slower than other units
	carry_capacity = 3
	health = 200
	max_health = 200
	super._ready()
	
	# Setup egg laying timer
	setup_egg_laying_timer()

func setup_egg_laying_timer():
	egg_laying_timer = Timer.new()
	egg_laying_timer.wait_time = egg_laying_rate
	egg_laying_timer.one_shot = false
	egg_laying_timer.timeout.connect(_on_egg_laying_timer_timeout)
	add_child(egg_laying_timer)
	egg_laying_timer.start()

# Queen behavior - prioritize egg laying, fallback to resource gathering
func check_for_tasks():
	# First priority: lay eggs if we have resources
	if not is_egg_laying and can_afford_eggs():
		start_egg_laying()
	
	# If not egg laying, gather resources
	if not is_egg_laying and not is_carrying and not gathering_target:
		find_nearest_resource()
	
	# If carrying resources, return to hive
	if is_carrying and not return_to_hive:
		return_to_hive = true
		move_to(hive_core.global_position)

func can_afford_eggs() -> bool:
	if not hive_core or not hive_core.has_method("get_total_resources"):
		return false
	
	var hive_resources = hive_core.get_total_resources()
	return hive_resources.can_afford(
		egg_laying_cost.get("biomass", 0),
		egg_laying_cost.get("genetic_material", 0)
	)

func start_egg_laying():
	if not can_afford_eggs():
		return
	
	is_egg_laying = true
	eggs_laid = 0
	change_state(UnitState.GATHERING)  # Use gathering state for egg laying
	
	# Start laying eggs
	lay_eggs()

func lay_eggs():
	if not can_afford_eggs() or eggs_laid >= max_eggs_per_lay:
		finish_egg_laying()
		return
	
	# Spend resources for egg
	if hive_core and hive_core.has_method("get_total_resources"):
		var hive_resources = hive_core.get_total_resources()
		hive_resources.spend_resources(
			egg_laying_cost.get("biomass", 0),
			egg_laying_cost.get("genetic_material", 0)
		)
		
		# Create larvae
		spawn_larvae()
		eggs_laid += 1
		
		# Continue laying if possible
		if eggs_laid < max_eggs_per_lay and can_afford_eggs():
			# Wait a bit before next egg
			var wait_timer = Timer.new()
			wait_timer.wait_time = 1.0
			wait_timer.one_shot = true
			wait_timer.timeout.connect(lay_eggs)
			add_child(wait_timer)
			wait_timer.start()
		else:
			finish_egg_laying()

func spawn_larvae():
	# Create a larvae unit at the queen's position
	var larvae_scene = load("res://scenes/units/larvae.tscn")
	if larvae_scene:
		var larvae = larvae_scene.instantiate()
		larvae.global_position = global_position
		
		# Add to the scene
		var units_container = get_node("/root/Main/Units")
		if units_container:
			units_container.add_child(larvae)
			larvae.add_to_group("hive_units")

func finish_egg_laying():
	is_egg_laying = false
	eggs_laid = 0
	change_state(UnitState.IDLE)

func _on_egg_laying_timer_timeout():
	# Timer triggered, check if we should lay eggs
	if not is_egg_laying and can_afford_eggs():
		start_egg_laying()

func find_nearest_resource():
	var resource_nodes = get_tree().get_nodes_in_group("resources")
	var nearest_distance = 200.0  # Queen has longer range
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
