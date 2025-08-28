class_name HumanCamp
extends StaticBody2D

# Human camp properties
@export var health: int = 100
@export var max_health: int = 100
@export var human_spawn_rate: float = 20.0
@export var max_humans: int = 4
@export var detection_range: float = 200.0

# Human spawning
var human_spawn_timer: Timer
var current_humans: int = 0
var human_scenes: Dictionary = {}

# Combat
var nearby_aliens: Array[Node] = []
var is_under_attack: bool = false

func _ready():
	# Setup human spawning
	setup_human_spawning()
	
	# Load human scenes
	load_human_scenes()
	
	# Add to groups
	add_to_group("human_camps")
	add_to_group("enemy_structures")
	
	# Spawn initial humans
	spawn_humans(2)

func setup_human_spawning():
	human_spawn_timer = Timer.new()
	human_spawn_timer.wait_time = human_spawn_rate
	human_spawn_timer.one_shot = false
	human_spawn_timer.timeout.connect(_on_human_spawn_timeout)
	add_child(human_spawn_timer)
	human_spawn_timer.start()

func load_human_scenes():
	# For now, create simple human units
	# In a full game, you'd load actual human scene files
	pass

func _on_human_spawn_timeout():
	if current_humans < max_humans and not is_under_attack:
		spawn_human()

func spawn_humans(count: int):
	for i in range(count):
		if current_humans < max_humans:
			spawn_human()

func spawn_human():
	var human = CharacterBody2D.new()
	human.add_to_group("humans")
	human.add_to_group("enemies")
	
	# Add human sprite
	var sprite = Sprite2D.new()
	var texture = GradientTexture2D.new()
	var gradient = Gradient.new()
	gradient.colors = PackedColorArray(Color(0.8, 0.6, 0.4), Color(0.6, 0.4, 0.2))
	texture.gradient = gradient
	texture.width = 16
	texture.height = 24
	sprite.texture = texture
	human.add_child(sprite)
	
	# Add collision
	var collision = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = Vector2(12, 20)
	collision.shape = shape
	human.add_child(collision)
	
	# Position human near camp
	var random_offset = Vector2(randf_range(-16, 16), randf_range(-16, 16))
	human.global_position = global_position + random_offset
	
	# Add to scene
	get_parent().add_child(human)
	current_humans += 1
	
	# Setup human AI
	setup_human_ai(human)

func setup_human_ai(human: CharacterBody2D):
	# Simple patrol behavior
	var patrol_timer = Timer.new()
	patrol_timer.wait_time = randf_range(3.0, 8.0)
	patrol_timer.one_shot = true
	patrol_timer.timeout.connect(_on_patrol_timeout.bind(human))
	human.add_child(patrol_timer)
	patrol_timer.start()

func _on_patrol_timeout(human: CharacterBody2D):
	# Move human to random position near camp
	var random_offset = Vector2(randf_range(-32, 32), randf_range(-32, 32))
	var target_pos = global_position + random_offset
	
	# Simple movement (in a full game, use NavigationAgent2D)
	var direction = (target_pos - human.global_position).normalized()
	human.global_position += direction * 16.0
	
	# Continue patrolling
	var patrol_timer = Timer.new()
	patrol_timer.wait_time = randf_range(3.0, 8.0)
	patrol_timer.one_shot = true
	patrol_timer.timeout.connect(_on_patrol_timeout.bind(human))
	human.add_child(patrol_timer)
	patrol_timer.start()

func take_damage(amount: int):
	health -= amount
	is_under_attack = true
	
	# Stop spawning when under attack
	human_spawn_timer.stop()
	
	if health <= 0:
		die()

func die():
	# Remove all humans
	var humans = get_tree().get_nodes_in_group("humans")
	for human in humans:
		if human.get_parent() == get_parent():
			human.queue_free()
	
	# Remove camp
	queue_free()

func get_human_count() -> int:
	return current_humans

func on_human_died():
	current_humans -= 1
	if current_humans < 0:
		current_humans = 0
	
	# Resume spawning if not under attack
	if current_humans < max_humans and not is_under_attack:
		human_spawn_timer.start()

func _on_area_2d_body_entered(body):
	if body.has_method("is_alien") and body.is_alien():
		nearby_aliens.append(body)
		is_under_attack = true
		human_spawn_timer.stop()

func _on_area_2d_body_exited(body):
	if nearby_aliens.has(body):
		nearby_aliens.erase(body)
	
	if nearby_aliens.size() == 0:
		is_under_attack = false
		if current_humans < max_humans:
			human_spawn_timer.start()
