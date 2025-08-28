class_name ResourceNode
extends StaticBody2D

# Resource properties
@export var resource_type: String = "biomass"
@export var resource_amount: int = 10
@export var max_resource_amount: int = 10
@export var respawn_time: float = 30.0
@export var collection_time: float = 2.0

# Visual properties
@export var glow_intensity: float = 1.0
@export var pulse_speed: float = 2.0

# State
var is_depleted: bool = false
var is_being_collected: bool = false
var collection_progress: float = 0.0
var respawn_timer: Timer

# Corruption bonus
var corruption_bonus: int = 0
var is_on_corrupted_ground: bool = false

# References
@onready var sprite: Sprite2D = $Sprite2D
@onready var collection_area: Area2D = $CollectionArea
@onready var progress_bar: ProgressBar = $ProgressBar

func _ready():
	# Setup respawn timer
	setup_respawn_timer()
	
	# Setup collection area
	setup_collection_area()
	
	# Setup progress bar
	setup_progress_bar()
	
	# Add to groups
	add_to_group("resources")
	add_to_group("resource_nodes")
	
	# Start visual effects
	start_visual_effects()

func setup_respawn_timer():
	respawn_timer = Timer.new()
	respawn_timer.wait_time = respawn_time
	respawn_timer.one_shot = true
	respawn_timer.timeout.connect(_on_respawn_timeout)
	add_child(respawn_timer)

func setup_collection_area():
	if not collection_area:
		collection_area = Area2D.new()
		add_child(collection_area)
		
		var collision_shape = CollisionShape2D.new()
		var shape = CircleShape2D.new()
		shape.radius = 16.0
		collision_shape.shape = shape
		collection_area.add_child(collision_shape)

func setup_progress_bar():
	if not progress_bar:
		progress_bar = ProgressBar.new()
		progress_bar.max_value = 1.0
		progress_bar.value = 0.0
		progress_bar.visible = false
		progress_bar.custom_minimum_size = Vector2(32, 4)
		progress_bar.position = Vector2(-16, -24)
		add_child(progress_bar)

func start_visual_effects():
	# Start pulsing glow effect
	var tween = create_tween()
	tween.set_loops()
	tween.tween_property(sprite, "modulate:a", 0.7, 1.0 / pulse_speed)
	tween.tween_property(sprite, "modulate:a", 1.0, 1.0 / pulse_speed)

func can_be_gathered() -> bool:
	return not is_depleted and resource_amount > 0 and not is_being_collected

func get_resource_type_name() -> String:
	return resource_type

func get_resource_amount() -> int:
	return resource_amount + corruption_bonus

func get_gather_amount() -> int:
	return 1  # Units collect 1 at a time

func gather_resource(amount: int):
	if not can_be_gathered():
		return false
	
	# Start collection process
	is_being_collected = true
	collection_progress = 0.0
	progress_bar.visible = true
	
	# Show collection progress
	var tween = create_tween()
	tween.tween_property(progress_bar, "value", 1.0, collection_time)
	tween.tween_callback(_on_collection_complete)
	
	return true

func _on_collection_complete():
	if resource_amount > 0:
		# Reduce resource amount
		resource_amount -= 1
		
		# Check if depleted
		if resource_amount <= 0:
			deplete_resource()
		else:
			# Reset for next collection
			is_being_collected = false
			progress_bar.visible = false
			progress_bar.value = 0.0

func deplete_resource():
	is_depleted = true
	is_being_collected = false
	progress_bar.visible = false
	
	# Hide the resource
	sprite.modulate.a = 0.3
	
	# Start respawn timer
	respawn_timer.start()
	
	print("Resource depleted, respawning in ", respawn_time, " seconds")

func _on_respawn_timeout():
	# Respawn the resource
	respawn_resource()

func respawn_resource():
	# Reset resource
	resource_amount = max_resource_amount
	is_depleted = false
	is_being_collected = false
	collection_progress = 0.0
	
	# Show the resource again
	sprite.modulate.a = 1.0
	
	# Move to random position within map bounds
	var new_position = Vector2(
		randf_range(100, 1180),
		randf_range(100, 620)
	)
	global_position = new_position
	
	print("Resource respawned at: ", new_position)

func is_fully_depleted() -> bool:
	return is_depleted

func check_corruption_bonus():
	# Check if this resource is on corrupted ground
	var space_state = get_world_2d().direct_space_state
	var query = PhysicsPointQueryParameters2D.new()
	query.position = global_position
	query.collision_mask = 2  # Corruption layer
	
	var result = space_state.intersect_point(query)
	is_on_corrupted_ground = result.size() > 0
	
	if is_on_corrupted_ground:
		corruption_bonus = 1
		# Visual effect for corruption bonus
		sprite.modulate = Color(0.8, 1.0, 0.8, 1.0)  # Slightly brighter green
	else:
		corruption_bonus = 0
		# Reset to normal color
		sprite.modulate = Color(1, 1, 1, 1)

func _on_collection_area_body_entered(body):
	if body.has_method("_on_resource_reached"):
		body._on_resource_reached()

func _on_collection_area_body_exited(body):
	# Reset collection if unit leaves
	if body.has_method("_on_resource_reached"):
		is_being_collected = false
		collection_progress = 0.0
		progress_bar.visible = false
		progress_bar.value = 0.0
