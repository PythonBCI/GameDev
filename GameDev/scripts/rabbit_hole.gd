class_name RabbitHole
extends StaticBody2D

# Rabbit hole properties
@export var rabbit_spawn_rate: float = 60.0
@export var max_rabbits: int = 2
@export var rabbit_lifespan: float = 120.0

# Rabbit spawning
var rabbit_spawn_timer: Timer
var current_rabbits: int = 0

func _ready():
	# Setup rabbit spawning
	setup_rabbit_spawning()
	
	# Add to groups
	add_to_group("rabbit_holes")
	add_to_group("animal_habitats")
	
	# Spawn initial rabbit
	spawn_rabbit()

func setup_rabbit_spawning():
	rabbit_spawn_timer = Timer.new()
	rabbit_spawn_timer.wait_time = rabbit_spawn_rate
	rabbit_spawn_timer.one_shot = false
	rabbit_spawn_timer.timeout.connect(_on_rabbit_spawn_timeout)
	add_child(rabbit_spawn_timer)
	rabbit_spawn_timer.start()

func _on_rabbit_spawn_timeout():
	if current_rabbits < max_rabbits:
		spawn_rabbit()

func spawn_rabbit():
	var rabbit = StaticBody2D.new()
	rabbit.add_to_group("rabbits")
	rabbit.add_to_group("animals")
	
			# Add rabbit sprite
		var sprite = Sprite2D.new()
		var texture = GradientTexture2D.new()
		var gradient = Gradient.new()
		gradient.colors = PackedColorArray([Color(0.8, 0.6, 0.4), Color(0.6, 0.4, 0.2)])
		texture.gradient = gradient
	texture.width = 12
	texture.height = 8
	sprite.texture = texture
	rabbit.add_child(sprite)
	
	# Add collision
	var collision = CollisionShape2D.new()
	var shape = CircleShape2D.new()
	shape.radius = 6.0
	collision.shape = shape
	rabbit.add_child(collision)
	
	# Position rabbit near hole
	var random_offset = Vector2(randf_range(-8, 8), randf_range(-8, 8))
	rabbit.global_position = global_position + random_offset
	
	# Add to scene
	get_parent().add_child(rabbit)
	current_rabbits += 1
	
	# Set lifespan timer
	var lifespan_timer = Timer.new()
	lifespan_timer.wait_time = rabbit_lifespan
	lifespan_timer.one_shot = true
	lifespan_timer.timeout.connect(_on_rabbit_lifespan_timeout.bind(rabbit))
	rabbit.add_child(lifespan_timer)
	lifespan_timer.start()

func _on_rabbit_lifespan_timeout(rabbit: Node):
	# Rabbit dies of old age
	rabbit.queue_free()
	current_rabbits -= 1
	if current_rabbits < 0:
		current_rabbits = 0

func get_rabbit_count() -> int:
	return current_rabbits

func on_rabbit_died():
	current_rabbits -= 1
	if current_rabbits < 0:
		current_rabbits = 0
