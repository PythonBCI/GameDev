class_name Queen
extends Unit

# Queen specific properties
var egg_production_timer: Timer
var egg_production_rate: float = 10.0  # 1 egg per 10 seconds
var buff_radius: float = 128.0  # 128 pixels as per spec
var buff_timer: Timer
var buff_duration: float = 5.0
var buff_cooldown: float = 15.0

# Buff system
var buffed_units: Array[Node] = []
var is_buffing: bool = false

func _ready():
	super._ready()
	unit_type = UnitType.QUEEN
	speed = 0.0  # Stationary as per spec
	carry_capacity = 0  # Queen doesn't carry resources
	
	setup_queen_systems()

func setup_queen_systems():
	# Egg production timer
	egg_production_timer = Timer.new()
	egg_production_timer.wait_time = egg_production_rate
	egg_production_timer.autostart = true
	egg_production_timer.timeout.connect(_on_egg_production_timeout)
	add_child(egg_production_timer)
	
	# Buff timer
	buff_timer = Timer.new()
	buff_timer.wait_time = buff_cooldown
	buff_timer.autostart = true
	buff_timer.timeout.connect(_on_buff_cooldown_timeout)
	add_child(buff_timer)

func check_for_tasks():
	# Queen is stationary, so no movement tasks
	# Just check if buff can be activated
	if not is_buffing and buff_timer.is_stopped():
		activate_area_buff()

func activate_area_buff():
	if not game_manager.resources.can_afford(secretions_cost=5):
		return
	
	# Spend secretions for buff
	game_manager.resources.spend_resources(secretions_cost=5)
	
	is_buffing = true
	change_state(UnitState.ATTACKING)  # Use action animation for buff
	
	# Find units in buff radius
	var units = get_tree().get_nodes_in_group("hive_units")
	for unit in units:
		if global_position.distance_to(unit.global_position) <= buff_radius:
			apply_buff_to_unit(unit)
	
	# Start buff duration timer
	var buff_duration_timer = Timer.new()
	buff_duration_timer.wait_time = buff_duration
	buff_duration_timer.one_shot = true
	buff_duration_timer.timeout.connect(_on_buff_duration_timeout)
	add_child(buff_duration_timer)
	buff_duration_timer.start()

func apply_buff_to_unit(unit: Node):
	if unit.has_method("apply_queen_buff"):
		unit.apply_queen_buff()
		buffed_units.append(unit)

func remove_buff_from_unit(unit: Node):
	if unit.has_method("remove_queen_buff"):
		unit.remove_queen_buff()
		buffed_units.erase(unit)

func _on_buff_duration_timeout():
	# Remove buffs from all units
	for unit in buffed_units:
		remove_buff_from_unit(unit)
	
	buffed_units.clear()
	is_buffing = false
	change_state(UnitState.IDLE)
	
	# Start cooldown
	buff_timer.start()

func _on_buff_cooldown_timeout():
	# Buff is ready again
	pass

func _on_egg_production_timeout():
	# Check if we can produce an egg
	if game_manager.resources.can_afford(biomass_cost=2, genetic_material_cost=1):
		# Spend resources
		game_manager.resources.spend_resources(biomass_cost=2, genetic_material_cost=1)
		
		# Add egg to hive
		game_manager.resources.add_eggs(1)
		
		# Play egg laying animation
		change_state(UnitState.ATTACKING)
		
		# Return to idle after animation
		var animation_timer = Timer.new()
		animation_timer.wait_time = 0.4  # 0.4 second action duration
		animation_timer.one_shot = true
		animation_timer.timeout.connect(_on_egg_laying_complete)
		add_child(animation_timer)
		animation_timer.start()
	else:
		# Not enough resources, wait longer
		egg_production_timer.wait_time = egg_production_rate * 2

func _on_egg_laying_complete():
	change_state(UnitState.IDLE)

func get_buff_radius() -> float:
	return buff_radius

func is_buff_active() -> bool:
	return is_buffing

func get_buffed_units_count() -> int:
	return buffed_units.size()
