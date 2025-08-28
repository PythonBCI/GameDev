class_name Enemy
extends CharacterBody2D

# Enemy properties
@export var health: int = 100
@export var max_health: int = 100
@export var speed: float = 24.0
@export var damage: int = 15
@export var attack_range: float = 32.0
@export var detection_range: float = 128.0

# AI state
enum EnemyState {IDLE, PATROLLING, CHASING, ATTACKING, FLEEING}
var current_state: EnemyState = EnemyState.IDLE

# Movement and targeting
var target_position: Vector2
var patrol_center: Vector2
var patrol_radius: float = 64.0
var current_target: Node = null
var is_alive: bool = true

# Timers
var patrol_timer: Timer
var attack_cooldown_timer: Timer
var can_attack: bool = true

# Navigation
var navigation_agent: NavigationAgent2D

func _ready():
	setup_enemy()
	add_to_group("enemies")

func setup_enemy():
	# Set patrol center to current position
	patrol_center = global_position
	
	# Setup navigation
	setup_navigation()
	
	# Setup timers
	setup_timers()
	
	# Start patrolling
	start_patrol()

func setup_navigation():
	navigation_agent = NavigationAgent2D.new()
	add_child(navigation_agent)
	navigation_agent.max_speed = speed
	navigation_agent.path_max_distance = 1000.0

func setup_timers():
	# Patrol timer
	patrol_timer = Timer.new()
	patrol_timer.wait_time = 3.0
	patrol_timer.one_shot = true
	patrol_timer.timeout.connect(_on_patrol_timeout)
	add_child(patrol_timer)
	
	# Attack cooldown timer
	attack_cooldown_timer = Timer.new()
	attack_cooldown_timer.wait_time = 2.0
	attack_cooldown_timer.one_shot = true
	attack_cooldown_timer.timeout.connect(_on_attack_cooldown_finished)
	add_child(attack_cooldown_timer)

func start_patrol():
	current_state = EnemyState.PATROLLING
	
	# Choose random patrol point
	var random_angle = randf() * TAU
	var random_distance = randf_range(16, patrol_radius)
	target_position = patrol_center + Vector2(
		cos(random_angle) * random_distance,
		sin(random_angle) * random_distance
	)
	
	# Move to patrol point
	move_to(target_position)
	
	# Start patrol timer
	patrol_timer.start()

func _physics_process(delta):
	match current_state:
		EnemyState.PATROLLING:
			update_patrol(delta)
		EnemyState.CHASING:
			update_chase(delta)
		EnemyState.ATTACKING:
			update_attack(delta)
		EnemyState.FLEEING:
			update_flee(delta)

func update_patrol(delta):
	# Check for nearby hive units
	var nearby_units = find_nearby_units()
	if nearby_units.size() > 0:
		# Switch to chase mode
		current_target = nearby_units[0]
		current_state = EnemyState.CHASING
		return
	
	# Continue patrolling
	if global_position.distance_to(target_position) < 16.0:
		# Reached patrol point, choose new one
		start_patrol()

func update_chase(delta):
	if not current_target or not current_target.has_method("is_alive") or not current_target.is_alive():
		# Target lost or dead, return to patrol
		current_target = null
		start_patrol()
		return
	
	var distance_to_target = global_position.distance_to(current_target.global_position)
	
	if distance_to_target <= attack_range:
		# Close enough to attack
		current_state = EnemyState.ATTACKING
		attack_target(current_target)
	elif distance_to_target > detection_range * 1.5:
		# Target too far, return to patrol
		current_target = null
		start_patrol()
	else:
		# Continue chasing
		move_to(current_target.global_position)

func update_attack(delta):
	if not current_target or not current_target.has_method("is_alive") or not current_target.is_alive():
		# Target dead, return to patrol
		current_target = null
		start_patrol()
		return
	
	var distance_to_target = global_position.distance_to(current_target.global_position)
	
	if distance_to_target > attack_range:
		# Target moved away, chase again
		current_state = EnemyState.CHASING
	else:
		# Stay in attack mode
		pass

func update_flee(delta):
	# Move away from current position
	var flee_direction = (global_position - patrol_center).normalized()
	var flee_target = global_position + flee_direction * 64
	
	move_to(flee_target)
	
	# After fleeing, return to patrol
	var flee_timer = Timer.new()
	flee_timer.wait_time = 5.0
	flee_timer.one_shot = true
	flee_timer.timeout.connect(_on_flee_finished)
	add_child(flee_timer)
	flee_timer.start()

func find_nearby_units() -> Array:
	var units = get_tree().get_nodes_in_group("hive_units")
	var nearby_units = []
	
	for unit in units:
		if unit.has_method("is_alive") and unit.is_alive():
			var distance = global_position.distance_to(unit.global_position)
			if distance <= detection_range:
				nearby_units.append(unit)
	
	# Sort by distance
	nearby_units.sort_custom(func(a, b): 
		return global_position.distance_to(a.global_position) < global_position.distance_to(b.global_position)
	)
	
	return nearby_units

func attack_target(target: Node):
	if not can_attack:
		return
	
	# Deal damage to target
	if target.has_method("take_damage"):
		target.take_damage(damage)
	
	# Start attack cooldown
	can_attack = false
	attack_cooldown_timer.start()
	
	print("Enemy attacked target for ", damage, " damage")

func move_to(target: Vector2):
	navigation_agent.target_position = target
	await get_tree().physics_frame
	
	if not navigation_agent.is_navigation_finished():
		var next_position = navigation_agent.get_next_path_position()
		var direction = (next_position - global_position).normalized()
		velocity = direction * speed
		move_and_slide()

func take_damage(amount: int):
	health -= amount
	
	if health <= 0:
		die()
	else:
		# Take damage, consider fleeing if health is low
		if health < max_health * 0.3:  # Less than 30% health
			current_state = EnemyState.FLEEING

func die():
	is_alive = false
	print("Enemy defeated!")
	
	# Drop resources (if any)
	drop_resources()
	
	# Remove from game
	queue_free()

func drop_resources():
	# Enemies can drop genetic material or live prey
	# This will be handled by the harvester units when they collect the enemy
	pass

func _on_patrol_timeout():
	# Choose new patrol point
	start_patrol()

func _on_attack_cooldown_finished():
	can_attack = true

func _on_flee_finished():
	# Return to patrol after fleeing
	start_patrol()

# Resource methods for harvesters to collect
func get_genetic_material() -> int:
	return 1  # Default drop

func get_live_prey() -> int:
	return 1  # Default drop

func get_prey_value() -> int:
	return 1  # Default value
