class_name Enemy
extends CharacterBody2D

# Enemy properties
@export var health: int = 50
@export var max_health: int = 50
@export var prey_value: int = 3  # Converts to 3 biomass when defeated
@export var speed: float = 24.0  # Slower than harvesters

# Movement
var target_position: Vector2
var is_moving: bool = false
var movement_timer: Timer

# Visual components
@onready var sprite: Sprite2D = $Sprite2D

func _ready():
	setup_enemy()
	add_to_group("enemies")

func setup_enemy():
	# Setup random movement
	movement_timer = Timer.new()
	movement_timer.wait_time = randf_range(3.0, 8.0)
	movement_timer.one_shot = true
	movement_timer.timeout.connect(_on_movement_timeout)
	add_child(movement_timer)
	
	# Start movement
	start_random_movement()

func start_random_movement():
	if not is_moving:
		is_moving = true
		var random_direction = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized()
		var random_distance = randf_range(32, 128)
		target_position = global_position + (random_direction * random_distance)
		
		movement_timer.start()

func _physics_process(delta):
	if is_moving:
		var direction = (target_position - global_position).normalized()
		velocity = direction * speed
		move_and_slide()
		
		# Check if reached target
		if global_position.distance_to(target_position) < 8.0:
			is_moving = false
			movement_timer.start()

func take_damage(amount: int):
	health -= amount
	
	# Visual feedback
	if sprite:
		sprite.modulate = Color.RED
		var tween = create_tween()
		tween.tween_property(sprite, "modulate", Color.WHITE, 0.2)
	
	if health <= 0:
		die()

func die():
	# Remove from game
	queue_free()

func is_alive() -> bool:
	return health > 0

func get_prey_value() -> int:
	return prey_value

func _on_movement_timeout():
	start_random_movement()

func get_health() -> int:
	return health

func get_max_health() -> int:
	return max_health

func get_health_percentage() -> float:
	return float(health) / float(max_health)
