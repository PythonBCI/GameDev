class_name ForestClearing
extends StaticBody2D

# Forest properties
@export var tree_density: float = 0.8
@export var animal_spawn_rate: float = 45.0
@export var max_animals: int = 3

# Animal spawning
var animal_spawn_timer: Timer
var current_animals: int = 0

func _ready():
	# Setup animal spawning
	setup_animal_spawning()
	
	# Add to groups
	add_to_group("forests")
	add_to_group("animal_habitats")
	
	# Spawn initial trees
	spawn_trees()

func setup_animal_spawning():
	animal_spawn_timer = Timer.new()
	animal_spawn_timer.wait_time = animal_spawn_rate
	animal_spawn_timer.one_shot = false
	animal_spawn_timer.timeout.connect(_on_animal_spawn_timeout)
	add_child(animal_spawn_timer)
	animal_spawn_timer.start()

func spawn_trees():
	# Spawn decorative trees around the clearing
	var tree_count = int(randf_range(3, 6))
	
	for i in range(tree_count):
		var tree = StaticBody2D.new()
		tree.add_to_group("trees")
		
		# Add tree sprite
		var sprite = Sprite2D.new()
		var texture = GradientTexture2D.new()
		var gradient = Gradient.new()
		gradient.colors = PackedColorArray([Color(0.2, 0.4, 0.1), Color(0.1, 0.2, 0.05)])
		texture.gradient = gradient
		texture.width = 24
		texture.height = 32
		sprite.texture = texture
		tree.add_child(sprite)
		
		# Position tree randomly in clearing
		var random_offset = Vector2(randf_range(-30, 30), randf_range(-20, 20))
		tree.global_position = global_position + random_offset
		
		# Add to scene
		get_parent().add_child(tree)

func _on_animal_spawn_timeout():
	if current_animals < max_animals:
		spawn_animal()

func spawn_animal():
	# Randomly choose animal type
	var animal_types = ["deer", "rabbit", "squirrel"]
	var animal_type = animal_types[randi() % animal_types.size()]
	
	var animal = StaticBody2D.new()
	animal.add_to_group("animals")
	animal.add_to_group(animal_type)
	
	# Add animal sprite
	var sprite = Sprite2D.new()
	var texture = GradientTexture2D.new()
	var gradient = Gradient.new()
	
			match animal_type:
			"deer":
				gradient.colors = PackedColorArray([Color(0.6, 0.4, 0.2), Color(0.4, 0.3, 0.1)])
				texture.width = 20
				texture.height = 16
			"rabbit":
				gradient.colors = PackedColorArray([Color(0.8, 0.6, 0.4), Color(0.6, 0.4, 0.2)])
				texture.width = 12
				texture.height = 8
			"squirrel":
				gradient.colors = PackedColorArray([Color(0.6, 0.4, 0.2), Color(0.4, 0.3, 0.1)])
				texture.width = 10
				texture.height = 6
	
	texture.gradient = gradient
	sprite.texture = texture
	animal.add_child(sprite)
	
	# Add collision
	var collision = CollisionShape2D.new()
	var shape = CircleShape2D.new()
	shape.radius = 8.0
	collision.shape = shape
	animal.add_child(collision)
	
	# Position animal randomly in clearing
	var random_offset = Vector2(randf_range(-25, 25), randf_range(-15, 15))
	animal.global_position = global_position + random_offset
	
	# Add to scene
	get_parent().add_child(animal)
	current_animals += 1

func get_animal_count() -> int:
	return current_animals

func on_animal_died():
	current_animals -= 1
	if current_animals < 0:
		current_animals = 0
