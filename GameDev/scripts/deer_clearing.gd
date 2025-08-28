class_name DeerClearing
extends StaticBody2D

# Deer clearing properties
@export var deer_spawn_rate: float = 90.0
@export var max_deer: int = 2
@export var deer_lifespan: float = 180.0

# Deer spawning
var deer_spawn_timer: Timer
var current_deer: int = 0

func _ready():
	# Setup deer spawning
	setup_deer_spawning()
	
	# Add to groups
	add_to_group("deer_clearings")
	add_to_group("animal_habitats")
	
	# Spawn initial deer
	spawn_deer()

func setup_deer_spawning():
	deer_spawn_timer = Timer.new()
	deer_spawn_timer.wait_time = deer_spawn_rate
	deer_spawn_timer.one_shot = false
	deer_spawn_timer.timeout.connect(_on_deer_spawn_timeout)
	add_child(deer_spawn_timer)
	deer_spawn_timer.start()

func _on_deer_spawn_timeout():
	if current_deer < max_deer:
		spawn_deer()

func spawn_deer():
	var deer = StaticBody2D.new()
	deer.add_to_group("deer")
	deer.add_to_group("animals")
	
			# Add deer sprite
		var sprite = Sprite2D.new()
		var texture = GradientTexture2D.new()
		var gradient = Gradient.new()
		gradient.colors = PackedColorArray([Color(0.6, 0.4, 0.2), Color(0.4, 0.3, 0.1)])
		texture.gradient = gradient
	texture.width = 20
	texture.height = 16
	sprite.texture = texture
	deer.add_child(sprite)
	
	# Add collision
	var collision = CollisionShape2D.new()
	var shape = CircleShape2D.new()
	shape.radius = 10.0
	collision.shape = shape
	deer.add_child(collision)
	
	# Position deer randomly in clearing
	var random_offset = Vector2(randf_range(-20, 20), randf_range(-15, 15))
	deer.global_position = global_position + random_offset
	
	# Add to scene
	get_parent().add_child(deer)
	current_deer += 1
	
	# Set lifespan timer
	var lifespan_timer = Timer.new()
	lifespan_timer.wait_time = deer_lifespan
	lifespan_timer.one_shot = true
	lifespan_timer.timeout.connect(_on_deer_lifespan_timeout.bind(deer))
	deer.add_child(lifespan_timer)
	lifespan_timer.start()

func _on_deer_lifespan_timeout(deer: Node):
	# Deer dies of old age
	deer.queue_free()
	current_deer -= 1
	if current_deer < 0:
		current_deer = 0

func get_deer_count() -> int:
	return current_deer

func on_deer_died():
	current_deer -= 1
	if current_deer < 0:
		current_deer = 0
