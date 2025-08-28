class_name Pond
extends StaticBody2D

# Pond properties
@export var water_amount: int = 100
@export var max_water: int = 100
@export var fish_spawn_rate: float = 30.0
@export var max_fish: int = 5

# Fish spawning
var fish_spawn_timer: Timer
var current_fish: int = 0

func _ready():
	# Setup fish spawning
	setup_fish_spawning()
	
	# Add to groups
	add_to_group("ponds")
	add_to_group("water_sources")

func setup_fish_spawning():
	fish_spawn_timer = Timer.new()
	fish_spawn_timer.wait_time = fish_spawn_rate
	fish_spawn_timer.one_shot = false
	fish_spawn_timer.timeout.connect(_on_fish_spawn_timeout)
	add_child(fish_spawn_timer)
	fish_spawn_timer.start()

func _on_fish_spawn_timeout():
	if current_fish < max_fish:
		spawn_fish()

func spawn_fish():
	# Create a simple fish resource
	var fish = StaticBody2D.new()
	fish.add_to_group("fish")
	
			# Add sprite
		var sprite = Sprite2D.new()
		var texture = GradientTexture2D.new()
		var gradient = Gradient.new()
		gradient.colors = PackedColorArray([Color(0.8, 0.6, 0.2), Color(0.6, 0.4, 0.1)])
		texture.gradient = gradient
	texture.width = 16
	texture.height = 8
	sprite.texture = texture
	fish.add_child(sprite)
	
	# Add collision
	var collision = CollisionShape2D.new()
	var shape = CircleShape2D.new()
	shape.radius = 8.0
	collision.shape = shape
	fish.add_child(collision)
	
	# Position fish randomly in pond
	var random_offset = Vector2(randf_range(-32, 32), randf_range(-32, 32))
	fish.global_position = global_position + random_offset
	
	# Add to scene
	get_parent().add_child(fish)
	current_fish += 1

func get_water_amount() -> int:
	return water_amount

func consume_water(amount: int) -> int:
	var consumed = min(amount, water_amount)
	water_amount -= consumed
	return consumed

func add_water(amount: int):
	water_amount = min(water_amount + amount, max_water)
