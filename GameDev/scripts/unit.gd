class_name Unit
extends CharacterBody2D

enum UnitType {WORKER_DRONE, HARVESTER, QUEEN, LARVAE}
enum UnitState {IDLE, MOVING, GATHERING, ATTACKING, CARRYING, DEAD}

@export var unit_type: UnitType
@export var unit_state: UnitState = UnitState.IDLE
@export var speed: float = 32.0  # pixels per second
@export var carry_capacity: int = 1
@export var health: int = 100
@export var max_health: int = 100

# AI and pathfinding
var target_position: Vector2
var path: Array[Vector2] = []
var current_path_index: int = 0
var navigation_agent: NavigationAgent2D

# Resource carrying
var carried_resources: Dictionary = {}
var is_carrying: bool = false

# Resource gathering
var nearest_resource: Node = null
var gathering_target: Node = null
var return_to_hive: bool = false

# Animation
@onready var sprite: Sprite2D = $Sprite2D
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var animation_player: AnimationPlayer = $AnimationPlayer

# Timers
var action_timer: Timer
var idle_timer: Timer

# References
var game_manager: Node
var hive_core: Node

func _ready():
	setup_navigation()
	setup_timers()
	setup_animations()
	
	# Find references
	game_manager = get_node("/root/Main/GameManager")
	hive_core = get_node("/root/Main/Structures/HiveCore")
	
	# Start in idle state
	change_state(UnitState.IDLE)

func setup_navigation():
	navigation_agent = NavigationAgent2D.new()
	add_child(navigation_agent)
	navigation_agent.max_speed = speed
	navigation_agent.path_max_distance = 1000.0

func setup_timers():
	action_timer = Timer.new()
	action_timer.one_shot = true
	add_child(action_timer)
	
	idle_timer = Timer.new()
	idle_timer.one_shot = true
	add_child(idle_timer)
	
	action_timer.timeout.connect(_on_action_timer_timeout)
	idle_timer.timeout.connect(_on_idle_timer_timeout)

func setup_animations():
	if animated_sprite:
		animated_sprite.play("idle")

func change_state(new_state: UnitState):
	unit_state = new_state
	
	match new_state:
		UnitState.IDLE:
			play_animation("idle")
			start_idle_timer()
		UnitState.MOVING:
			play_animation("movement")
		UnitState.GATHERING:
			play_animation("action")
			start_action_timer(2.0)  # 2 second gathering time
		UnitState.ATTACKING:
			play_animation("action")
			start_action_timer(3.0)  # 3 second combat time
		UnitState.CARRYING:
			play_animation("action")
		UnitState.DEAD:
			play_animation("death")
			start_action_timer(0.6)  # Death animation duration

func play_animation(anim_name: String):
	if animated_sprite and animated_sprite.has_animation(anim_name):
		animated_sprite.play(anim_name)

func start_action_timer(duration: float):
	action_timer.wait_time = duration
	action_timer.start()

func start_idle_timer():
	idle_timer.wait_time = randf_range(1.0, 3.0)
	idle_timer.start()

func _physics_process(delta):
	match unit_state:
		UnitState.MOVING:
			update_movement(delta)
		UnitState.IDLE:
			# Check for new tasks
			check_for_tasks()

func update_movement(delta):
	if path.size() == 0 or current_path_index >= path.size():
		change_state(UnitState.IDLE)
		return
	
	var target = path[current_path_index]
	var direction = (target - global_position).normalized()
	velocity = direction * speed
	
	move_and_slide()
	
	# Check if we've reached the current waypoint
	if global_position.distance_to(target) < 8.0:  # 8 pixel threshold
		current_path_index += 1
		if current_path_index >= path.size():
			change_state(UnitState.IDLE)

func move_to(target: Vector2):
	target_position = target
	path = get_path_to_target(target)
	current_path_index = 0
	
	if path.size() > 0:
		change_state(UnitState.MOVING)
	else:
		change_state(UnitState.IDLE)

func get_path_to_target(target: Vector2) -> Array[Vector2]:
	navigation_agent.target_position = target
	await get_tree().physics_frame
	
	if navigation_agent.is_navigation_finished():
		return []
	
	var path_points = navigation_agent.get_current_navigation_path()
	return path_points

func check_for_tasks():
	# This will be overridden by specific unit types
	pass

func take_damage(amount: int):
	health -= amount
	if health <= 0:
		die()

func is_alive() -> bool:
	return health > 0

func die():
	change_state(UnitState.DEAD)
	# Drop carried resources
	if is_carrying:
		drop_resources()
	
	# Remove from game after death animation
	action_timer.timeout.connect(_on_death_complete)

func drop_resources():
	# This will be implemented to drop resources at current position
	pass

func _on_action_timer_timeout():
	match unit_state:
		UnitState.GATHERING:
			complete_gathering()
		UnitState.ATTACKING:
			complete_attack()
		UnitState.DEAD:
			_on_death_complete()

func _on_idle_timer_timeout():
	# Generate random movement or check for tasks
	check_for_tasks()

func _on_death_complete():
	queue_free()

func complete_gathering():
	# This will be overridden by specific unit types
	pass

func complete_attack():
	# This will be overridden by specific unit types
	pass

func can_carry_more() -> bool:
	var total_carried = 0
	for resource_type in carried_resources:
		total_carried += carried_resources[resource_type]
	return total_carried < carry_capacity

func add_carried_resource(resource_type: String, amount: int):
	if can_carry_more():
		if resource_type in carried_resources:
			carried_resources[resource_type] += amount
		else:
			carried_resources[resource_type] = amount
		is_carrying = true
		change_state(UnitState.CARRYING)

func remove_carried_resource(resource_type: String, amount: int):
	if resource_type in carried_resources:
		carried_resources[resource_type] -= amount
		if carried_resources[resource_type] <= 0:
			carried_resources.erase(resource_type)
		
		if carried_resources.size() == 0:
			is_carrying = false
			change_state(UnitState.IDLE)
