class_name Larvae
extends Unit

enum GrowthStage {STAGE_1, STAGE_2, STAGE_3, READY_TO_PUPATE}

# Larvae specific properties
@export var growth_stage: GrowthStage = GrowthStage.STAGE_1
var growth_timer: Timer
var growth_time_per_stage: float = 15.0  # 15 seconds per stage as per spec
var total_growth_time: float = 45.0  # 3 stages * 15 seconds
var current_growth_progress: float = 0.0

# Movement toward nursery
var nearest_nursery: Node = null
var moving_to_nursery: bool = false

func _ready():
	super._ready()
	unit_type = UnitType.LARVAE
	speed = 8.0  # 8 pixels/second as per spec
	carry_capacity = 0  # Larvae can't carry resources
	
	setup_growth_system()

func setup_growth_system():
	growth_timer = Timer.new()
	growth_timer.wait_time = growth_time_per_stage
	growth_timer.autostart = true
	growth_timer.timeout.connect(_on_growth_stage_complete)
	add_child(growth_timer)

func check_for_tasks():
	if growth_stage == GrowthStage.READY_TO_PUPATE:
		# Find nearest nursery to pupate
		find_nearest_nursery()
	elif not moving_to_nursery:
		# Random movement while growing
		random_movement()

func find_nearest_nursery():
	var nurseries = get_tree().get_nodes_in_group("nurseries")
	var nearest_distance = INF
	nearest_nursery = null
	
	for nursery in nurseries:
		var distance = global_position.distance_to(nursery.global_position)
		if distance < nearest_distance:
			nearest_distance = distance
			nearest_nursery = nursery
	
	if nearest_nursery:
		move_to(nearest_nursery.global_position)
		moving_to_nursery = true

func random_movement():
	# Simple random movement within a small radius
	var random_direction = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized()
	var random_distance = randf_range(16, 64)  # 16-64 pixels
	var target = global_position + (random_direction * random_distance)
	
	move_to(target)

func _on_growth_stage_complete():
	advance_growth_stage()

func advance_growth_stage():
	match growth_stage:
		GrowthStage.STAGE_1:
			growth_stage = GrowthStage.STAGE_2
			play_animation("stage_2")
		GrowthStage.STAGE_2:
			growth_stage = GrowthStage.STAGE_3
			play_animation("stage_3")
		GrowthStage.STAGE_3:
			growth_stage = GrowthStage.READY_TO_PUPATE
			play_animation("stage_3")  # Keep stage 3 animation
	
	# Update sprite based on growth stage
	update_larvae_appearance()
	
	# Reset timer for next stage
	if growth_stage != GrowthStage.READY_TO_PUPATE:
		growth_timer.start()

func update_larvae_appearance():
	# This will be called to update the visual appearance based on growth stage
	# The actual sprite changes will be handled by the AnimatedSprite2D
	pass

func _on_nursery_reached():
	if growth_stage == GrowthStage.READY_TO_PUPATE and nearest_nursery:
		# Start pupation process
		start_pupation()

func start_pupation():
	# This will trigger the evolution into a new unit type
	# For now, just remove the larvae
	queue_free()

func _on_movement_finished():
	if moving_to_nursery and nearest_nursery:
		if global_position.distance_to(nearest_nursery.global_position) < 16.0:
			_on_nursery_reached()
		else:
			moving_to_nursery = false
			change_state(UnitState.IDLE)
	else:
		change_state(UnitState.IDLE)

func get_growth_progress() -> float:
	return current_growth_progress / total_growth_time

func get_growth_stage() -> GrowthStage:
	return growth_stage

func is_ready_to_pupate() -> bool:
	return growth_stage == GrowthStage.READY_TO_PUPATE

func accelerate_growth(acceleration_factor: float):
	# Called by nursery structures to speed up growth
	growth_timer.wait_time = growth_time_per_stage / acceleration_factor
	if growth_timer.is_stopped():
		growth_timer.start()
