class_name GameManager
extends Node

# Game state
enum GameState {PLAYING, VICTORY, DEFEAT, PAUSED}

@export var current_game_state: GameState = GameState.PLAYING
@export var game_time: float = 0.0
@export var victory_time: float = 300.0  # 300 seconds for victory condition

# Resources and economy
var resources: GameResources
var hive_core: HiveCore

# Game systems (placeholder nodes for now)
var pheromone_system: Node
var creep_system: Node
var evolution_system: Node

# UI references
var ui: Node
var resource_display: Node
var building_buttons: Node
var game_status: Node

# Timers
var game_timer: Timer
var secretion_timer: Timer

func _ready():
	setup_game_systems()
	start_game()

func setup_game_systems():
	# Initialize resources
	resources = GameResources.new()
	
	# Find hive core
	hive_core = get_node("../Structures/HiveCore")
	
	# Setup placeholder systems
	setup_placeholder_systems()
	
	# Setup timers
	setup_timers()
	
	# Setup UI
	setup_ui()

func setup_placeholder_systems():
	# Create placeholder systems for now
	pheromone_system = Node.new()
	pheromone_system.name = "PheromoneSystem"
	add_child(pheromone_system)
	
	creep_system = Node.new()
	creep_system.name = "CreepSystem"
	add_child(creep_system)
	
	evolution_system = Node.new()
	evolution_system.name = "EvolutionSystem"
	add_child(evolution_system)

func setup_timers():
	# Main game timer
	game_timer = Timer.new()
	game_timer.wait_time = 1.0  # Update every second
	game_timer.autostart = true
	game_timer.timeout.connect(_on_game_tick)
	add_child(game_timer)
	
	# Secretion generation timer
	secretion_timer = Timer.new()
	secretion_timer.wait_time = 30.0  # Generate secretions every 30 seconds
	secretion_timer.autostart = true
	secretion_timer.timeout.connect(_on_secretion_generation)
	add_child(secretion_timer)

func setup_ui():
	# Find UI elements
	ui = get_node("../UI")
	if ui:
		resource_display = ui.get_node("ResourceDisplay")
		building_buttons = ui.get_node("BuildingButtons")
		game_status = ui.get_node("GameStatus")

func start_game():
	current_game_state = GameState.PLAYING
	game_time = 0.0
	
	# Initialize starting resources
	resources.add_biomass(10)
	resources.add_minerals(5)
	
	# Start game systems
	start_secretion_generation()

func start_secretion_generation():
	secretion_timer.start()

func _on_game_tick():
	if current_game_state != GameState.PLAYING:
		return
	
	game_time += 1.0
	
	# Check victory/defeat conditions
	check_victory_conditions()
	check_defeat_conditions()
	
	# Update UI
	update_ui()

func _on_secretion_generation():
	if current_game_state == GameState.PLAYING:
		# Generate secretions for all living units
		generate_secretions()

func generate_secretions():
	var units = get_tree().get_nodes_in_group("hive_units")
	for unit in units:
		if unit.has_method("is_alive") and unit.is_alive():
			resources.add_secretions(1)

func check_victory_conditions():
	# Check territory control (creep covers 75% of playable area)
	if creep_system and creep_system.has_method("get_creep_coverage"):
		if creep_system.get_creep_coverage() >= 0.75:
			trigger_victory("Territory Control Achieved!")
			return
	
	# Check population goal (50+ active units)
	if hive_core and hive_core.has_method("get_current_units_count"):
		if hive_core.get_current_units_count() >= 50:
			trigger_victory("Population Goal Achieved!")
			return
	
	# Check survival time (300 seconds)
	if game_time >= victory_time:
		trigger_victory("Survival Goal Achieved!")

func check_defeat_conditions():
	if not hive_core:
		return
	
	# Check hive core destruction
	if hive_core.health <= 0:
		trigger_defeat("Hive Core Destroyed!")
		return
	
	# Check population collapse
	if hive_core.has_method("get_current_units_count"):
		if hive_core.get_current_units_count() < 3:
			trigger_defeat("Population Collapsed!")
			return
	
	# Check resource depletion
	if is_resources_depleted():
		trigger_defeat("Resources Exhausted!")

func is_resources_depleted() -> bool:
	# Check if all resource nodes are depleted and insufficient stockpile
	var resource_nodes = get_tree().get_nodes_in_group("resources")
	var all_depleted = true
	
	for node in resource_nodes:
		if node.has_method("is_fully_depleted") and not node.is_fully_depleted():
			all_depleted = false
			break
	
	if all_depleted:
		# Check if we have enough resources to survive
		return not resources.can_afford(biomass_cost=5, minerals_cost=3)
	
	return false

func trigger_victory(message: String):
	current_game_state = GameState.VICTORY
	show_game_end_screen(message, true)

func trigger_defeat(message: String):
	current_game_state = GameState.DEFEAT
	show_game_end_screen(message, false)

func show_game_end_screen(message: String, is_victory: bool):
	if game_status and game_status.has_method("show_game_end"):
		game_status.show_game_end(message, is_victory)
	
	# Pause game
	get_tree().paused = true

func update_ui():
	if resource_display and resource_display.has_method("update_resource_display"):
		resource_display.update_resource_display(resources)
	
	if game_status and game_status.has_method("update_game_time"):
		game_status.update_game_time(game_time)
		if hive_core and hive_core.has_method("get_current_units_count"):
			game_status.update_unit_count(hive_core.get_current_units_count())

func pause_game():
	if current_game_state == GameState.PLAYING:
		current_game_state = GameState.PAUSED
		get_tree().paused = true

func resume_game():
	if current_game_state == GameState.PAUSED:
		current_game_state = GameState.PLAYING
		get_tree().paused = false

func restart_game():
	# Reset game state
	get_tree().paused = false
	get_tree().reload_current_scene()

func get_current_resources() -> GameResources:
	return resources

func get_game_time() -> float:
	return game_time

func get_game_state() -> GameState:
	return current_game_state

func is_game_active() -> bool:
	return current_game_state == GameState.PLAYING

func get_victory_time_remaining() -> float:
	return max(0, victory_time - game_time)
