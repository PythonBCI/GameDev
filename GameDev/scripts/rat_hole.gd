class_name RatHole
extends StaticBody2D

# Rat hole properties
@export var rat_spawn_rate: float = 45.0
@export var max_rats: int = 3
@export var rat_lifespan: float = 90.0

# Rat spawning
var rat_spawn_timer: Timer
var current_rats: int = 0

func _ready():
	# Setup rat spawning
	setup_rat_spawning()
	
	# Add to groups
	add_to_group("rat_holes")
	add_to_group("animal_habitats")
	
	# Spawn initial rat
	spawn_rat()

func setup_rat_spawning():
	rat_spawn_timer = Timer.new()
	rat_spawn_timer.wait_time = rat_spawn_rate
	rat_spawn_timer.one_shot = false
	rat_spawn_timer.timeout.connect(_on_rat_spawn_timeout)
	add_child(rat_spawn_timer)
	rat_spawn_timer.start()

func _on_rat_spawn_timeout():
	if current_rats < max_rats:
		spawn_rat()

func spawn_rat():
	var rat = StaticBody2D.new()
	rat.add_to_group("rats")
	rat.add_to_group("animals")
	
			# Add rat sprite
		var sprite = Sprite2D.new()
		var texture = GradientTexture2D.new()
		var gradient = Gradient.new()
		gradient.colors = PackedColorArray([Color(0.4, 0.3, 0.2), Color(0.2, 0.1, 0.05)])
		texture.gradient = gradient
	texture.width = 10
	texture.height = 6
	sprite.texture = texture
	rat.add_child(sprite)
	
	# Add collision
	var collision = CollisionShape2D.new()
	var shape = CircleShape2D.new()
	shape.radius = 5.0
	collision.shape = shape
	rat.add_child(collision)
	
	# Position rat near hole
	var random_offset = Vector2(randf_range(-8, 8), randf_range(-8, 8))
	rat.global_position = global_position + random_offset
	
	# Add to scene
	get_parent().add_child(rat)
	current_rats += 1
	
	# Set lifespan timer
	var lifespan_timer = Timer.new()
	lifespan_timer.wait_time = rat_lifespan
	lifespan_timer.one_shot = true
	lifespan_timer.timeout.connect(_on_rat_lifespan_timeout.bind(rat))
	rat.add_child(lifespan_timer)
	lifespan_timer.start()

func _on_rat_lifespan_timeout(rat: Node):
	# Rat dies of old age
	rat.queue_free()
	current_rats -= 1
	if current_rats < 0:
		current_rats = 0

func get_rat_count() -> int:
	return current_rats

func on_rat_died():
	current_rats -= 1
	if current_rats < 0:
		current_rats = 0
