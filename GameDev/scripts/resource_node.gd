class_name ResourceNode
extends StaticBody2D

enum ResourceType {BIOMASS, MINERALS, LIVE_PREY, GENETIC_MATERIAL}

@export var resource_type: ResourceType
@export var resource_amount: int = 10
@export var max_resource_amount: int = 10
@export var collection_time: float = 2.0  # Time to collect one unit
@export var respawn_time: float = 30.0  # Time to respawn when depleted

# Visual components
@onready var sprite: Sprite2D = $Sprite2D
@onready var progress_bar: ProgressBar = $ProgressBar

# Collection state
var is_being_collected: bool = false
var current_collector: Node = null
var collection_progress: float = 0.0
var collection_timer: Timer

# Respawn system
var is_depleted: bool = false
var respawn_timer: Timer

func _ready():
	setup_resource_node()
	add_to_group("resources")
	
	# Set resource type based on parent node name
	if get_parent().name == "Resources":
		if name.contains("Biomass"):
			resource_type = ResourceType.BIOMASS
		elif name.contains("Minerals"):
			resource_type = ResourceType.MINERALS

func setup_resource_node():
	# Setup collection timer
	collection_timer = Timer.new()
	collection_timer.wait_time = 0.1  # Update every 0.1 seconds
	collection_timer.timeout.connect(_on_collection_tick)
	add_child(collection_timer)
	
	# Setup respawn timer
	respawn_timer = Timer.new()
	respawn_timer.wait_time = respawn_time
	respawn_timer.one_shot = true
	respawn_timer.timeout.connect(_on_respawn_timeout)
	add_child(respawn_timer)
	
	# Initialize visual components
	if progress_bar:
		progress_bar.visible = false
		progress_bar.max_value = max_resource_amount
		progress_bar.value = resource_amount

func can_be_gathered() -> bool:
	return not is_depleted and resource_amount > 0 and not is_being_collected

func gather_resource() -> int:
	if can_be_gathered():
		start_collection(get_tree().get_nodes_in_group("hive_units")[0] if get_tree().get_nodes_in_group("hive_units").size() > 0 else null)
		return 1
	return 0

func start_collection(collector: Node):
	if not can_be_gathered():
		return false
	
	is_being_collected = true
	current_collector = collector
	collection_progress = 0.0
	collection_timer.start()
	
	if progress_bar:
		progress_bar.visible = true
	
	return true

func stop_collection():
	is_being_collected = false
	current_collector = null
	collection_timer.stop()
	
	if progress_bar:
		progress_bar.visible = false

func _on_collection_tick():
	if not is_being_collected:
		return
	
	collection_progress += 0.1 / collection_time
	
	if progress_bar:
		progress_bar.value = resource_amount - collection_progress
	
	if collection_progress >= 1.0:
		complete_collection()

func complete_collection():
	# Give one resource unit to collector
	if current_collector and current_collector.has_method("add_carried_resource"):
		var resource_name = get_resource_type_name()
		current_collector.add_carried_resource(resource_name, 1)
	
	# Reduce resource amount
	resource_amount -= 1
	
	# Reset collection state
	stop_collection()
	
	# Check if depleted
	if resource_amount <= 0:
		deplete_resource()

func deplete_resource():
	is_depleted = true
	
	# Change appearance
	if sprite:
		sprite.modulate.a = 0.3  # Make it look depleted
	
	# Start respawn timer
	respawn_timer.start()
	
	# Hide progress bar
	if progress_bar:
		progress_bar.visible = false

func _on_respawn_timeout():
	# Respawn the resource
	resource_amount = max_resource_amount
	is_depleted = false
	
	# Restore appearance
	if sprite:
		sprite.modulate.a = 1.0
	
	# Update progress bar
	if progress_bar:
		progress_bar.value = resource_amount

func get_resource_type_name() -> String:
	match resource_type:
		ResourceType.BIOMASS:
			return "biomass"
		ResourceType.MINERALS:
			return "minerals"
		ResourceType.LIVE_PREY:
			return "live_prey"
		ResourceType.GENETIC_MATERIAL:
			return "genetic_material"
		_:
			return "unknown"

func get_resource_amount() -> int:
	return resource_amount

func get_max_resource_amount() -> int:
	return max_resource_amount

func is_fully_depleted() -> bool:
	return is_depleted

func get_collection_progress() -> float:
	return collection_progress

func get_collection_time() -> float:
	return collection_time

func get_respawn_time_remaining() -> float:
	if respawn_timer.is_stopped():
		return 0.0
	return respawn_timer.time_left
