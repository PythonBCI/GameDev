class_name Structure
extends StaticBody2D

enum StructureType {HIVE_CORE, SPIRE, NURSERY, CREEP_NODE, EVOLUTION_CHAMBER}

@export var structure_type: StructureType
@export var health: int = 100
@export var max_health: int = 100
@export var is_constructed: bool = false

# Construction costs
@export var biomass_cost: int = 0
@export var live_prey_cost: int = 0
@export var genetic_material_cost: int = 0
@export var minerals_cost: int = 0
@export var secretions_cost: int = 0
@export var eggs_cost: int = 0

# Construction system
var construction_progress: float = 0.0
var construction_time: float = 5.0
var construction_timer: Timer

# Visual components
@onready var sprite: Sprite2D = $Sprite2D
@onready var progress_bar: ProgressBar = $ProgressBar

func _ready():
	setup_construction_system()
	add_to_group("structures")

func setup_construction_system():
	construction_timer = Timer.new()
	construction_timer.wait_time = 0.1  # Update every 0.1 seconds
	construction_timer.timeout.connect(_on_construction_tick)
	add_child(construction_timer)
	
	# Start construction if not already constructed
	if not is_constructed:
		start_construction()

func start_construction():
	construction_progress = 0.0
	construction_timer.start()
	
	# Set initial appearance
	if sprite:
		sprite.modulate.a = 0.5  # Semi-transparent during construction
	
	if progress_bar:
		progress_bar.visible = true
		progress_bar.value = 0

func _on_construction_tick():
	construction_progress += 0.1 / construction_time
	
	if progress_bar:
		progress_bar.value = construction_progress * 100
	
	if construction_progress >= 1.0:
		complete_construction()

func complete_construction():
	is_constructed = true
	construction_timer.stop()
	
	# Set final appearance
	if sprite:
		sprite.modulate.a = 1.0  # Fully opaque
	
	if progress_bar:
		progress_bar.visible = false
	
	# Initialize structure-specific functionality
	on_construction_complete()

func on_construction_complete():
	# Override in derived classes
	pass

func take_damage(amount: int):
	if not is_constructed:
		return
	
	health -= amount
	if health <= 0:
		destroy()

func destroy():
	# Remove from game
	queue_free()

func get_construction_cost() -> Dictionary:
	return {
		"biomass": biomass_cost,
		"live_prey": live_prey_cost,
		"genetic_material": genetic_material_cost,
		"minerals": minerals_cost,
		"secretions": secretions_cost,
		"eggs": eggs_cost
	}

func can_afford_construction() -> bool:
	var game_manager = get_node("/root/Main/GameManager")
	if game_manager and game_manager.resources:
		return game_manager.resources.can_afford(
			biomass_cost, live_prey_cost, genetic_material_cost,
			minerals_cost, secretions_cost, eggs_cost
		)
	return false

func spend_construction_resources() -> bool:
	var game_manager = get_node("/root/Main/GameManager")
	if game_manager and game_manager.resources:
		return game_manager.resources.spend_resources(
			biomass_cost, live_prey_cost, genetic_material_cost,
			minerals_cost, secretions_cost, eggs_cost
		)
	return false

func get_health_percentage() -> float:
	return float(health) / float(max_health)

func is_fully_constructed() -> bool:
	return is_constructed

func get_structure_type() -> StructureType:
	return structure_type
