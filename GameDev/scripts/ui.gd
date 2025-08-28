class_name UI
extends Control

# UI References
@onready var resource_display: Control = $ResourceDisplay
@onready var game_status: Control = $GameStatus
@onready var building_buttons: Control = $BuildingButtons

# Resource Labels
@onready var biomass_label: Label = $ResourceDisplay/BiomassLabel
@onready var minerals_label: Label = $ResourceDisplay/MineralsLabel
@onready var genetic_material_label: Label = $ResourceDisplay/GeneticMaterialLabel
@onready var secretions_label: Label = $ResourceDisplay/SecretionsLabel
@onready var eggs_label: Label = $ResourceDisplay/EggsLabel

# Game Status Labels
@onready var time_label: Label = $GameStatus/TimeLabel
@onready var units_label: Label = $GameStatus/UnitsLabel

# Game Manager Reference
var game_manager: Node
var hive_core: Node

func _ready():
	# Find game manager
	game_manager = get_node("/root/Main/GameManager")
	hive_core = get_node("/root/Main/Structures/HiveCore")
	
	# Setup UI
	setup_ui()
	
	# Connect building button signals
	connect_building_buttons()
	
	# Start update timer
	var update_timer = Timer.new()
	update_timer.wait_time = 0.5  # Update every 0.5 seconds
	update_timer.one_shot = false
	update_timer.timeout.connect(_on_update_timer_timeout)
	add_child(update_timer)
	update_timer.start()

func setup_ui():
	# Initialize labels with default values
	update_resource_display(GameResources.new())
	update_game_time(0)
	update_unit_count(0)

func connect_building_buttons():
	if building_buttons and building_buttons.has_node("VBoxContainer"):
		var buttons = building_buttons.get_node("VBoxContainer")
		
		# Connect unit buttons
		if buttons.has_node("WorkerDroneButton"):
			buttons.get_node("WorkerDroneButton").pressed.connect(_on_worker_drone_button_pressed)
		if buttons.has_node("HarvesterButton"):
			buttons.get_node("HarvesterButton").pressed.connect(_on_harvester_button_pressed)
		if buttons.has_node("QueenButton"):
			buttons.get_node("QueenButton").pressed.connect(_on_queen_button_pressed)
		if buttons.has_node("LarvaeButton"):
			buttons.get_node("LarvaeButton").pressed.connect(_on_larvae_button_pressed)
		
		# Connect structure buttons
		if buttons.has_node("SpireButton"):
			buttons.get_node("SpireButton").pressed.connect(_on_spire_button_pressed)
		if buttons.has_node("NurseryButton"):
			buttons.get_node("NurseryButton").pressed.connect(_on_nursery_button_pressed)
		if buttons.has_node("CreepNodeButton"):
			buttons.get_node("CreepNodeButton").pressed.connect(_on_creep_node_button_pressed)

func _on_update_timer_timeout():
	# Update resource display
	if hive_core and hive_core.has_method("get_total_resources"):
		var resources = hive_core.get_total_resources()
		update_resource_display(resources)
	
	# Update unit count
	if hive_core and hive_core.has_method("get_current_units_count"):
		var unit_count = hive_core.get_current_units_count()
		update_unit_count(unit_count)
	
	# Update game time
	if game_manager and game_manager.has_method("get_game_time"):
		var game_time = game_manager.get_game_time()
		update_game_time(game_time)

func update_resource_display(resources: GameResources):
	if not resources:
		return
	
	biomass_label.text = "Biomass: " + str(resources.biomass) + "/" + str(resources.BIOMASS_LIMIT)
	minerals_label.text = "Minerals: " + str(resources.minerals) + "/" + str(resources.MINERALS_LIMIT)
	genetic_material_label.text = "Genetic: " + str(resources.genetic_material) + "/" + str(resources.GENETIC_MATERIAL_LIMIT)
	secretions_label.text = "Secretions: " + str(resources.secretions) + "/" + str(resources.SECRETIONS_LIMIT)
	eggs_label.text = "Eggs: " + str(resources.eggs) + "/" + str(resources.EGGS_LIMIT)
	
	# Color coding for low resources
	if resources.biomass < 5:
		biomass_label.modulate = Color(1, 0.5, 0.5)  # Red tint for low biomass
	else:
		biomass_label.modulate = Color(1, 1, 1)  # Normal color

func update_game_time(seconds: float):
	var minutes = int(seconds) / 60
	var remaining_seconds = int(seconds) % 60
	time_label.text = "Time: " + str(minutes) + ":" + str(remaining_seconds).pad_zeros(2)

func update_unit_count(count: int):
	units_label.text = "Units: " + str(count) + "/20"
	
	# Color coding for unit count
	if count >= 18:
		units_label.modulate = Color(1, 0.5, 0.5)  # Red tint for near capacity
	elif count >= 15:
		units_label.modulate = Color(1, 1, 0.5)  # Yellow tint for warning
	else:
		units_label.modulate = Color(1, 1, 1)  # Normal color

func show_game_end(message: String, is_victory: bool):
	# Create game end overlay
	var overlay = ColorRect.new()
	overlay.color = Color(0, 0, 0, 0.8)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(overlay)
	
	# Create message container
	var message_container = VBoxContainer.new()
	message_container.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	add_child(message_container)
	
	# Create title label
	var title_label = Label.new()
	if is_victory:
		title_label.text = "VICTORY!"
	else:
		title_label.text = "DEFEAT!"
	title_label.add_theme_font_size_override("font_size", 48)
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message_container.add_child(title_label)
	
	# Create message label
	var message_label = Label.new()
	message_label.text = message
	message_label.add_theme_font_size_override("font_size", 24)
	message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message_container.add_child(message_label)
	
	# Create restart button
	var restart_button = Button.new()
	restart_button.text = "Restart Game"
	restart_button.pressed.connect(_on_restart_button_pressed)
	message_container.add_child(restart_button)

func _on_restart_button_pressed():
	get_tree().reload_current_scene()

# Button signal handlers
func _on_worker_drone_button_pressed():
	print("Worker Drone button pressed")
	if game_manager and game_manager.has_method("get_world_builder"):
		var world_builder = game_manager.get_world_builder()
		if world_builder:
			world_builder.start_building_mode(world_builder.BuildMode.UNIT, "worker_drone")

func _on_harvester_button_pressed():
	print("Harvester button pressed")
	if game_manager and game_manager.has_method("get_world_builder"):
		var world_builder = game_manager.get_world_builder()
		if world_builder:
			world_builder.start_building_mode(world_builder.BuildMode.UNIT, "harvester")

func _on_queen_button_pressed():
	print("Queen button pressed")
	if game_manager and game_manager.has_method("get_world_builder"):
		var world_builder = game_manager.get_world_builder()
		if world_builder:
			world_builder.start_building_mode(world_builder.BuildMode.UNIT, "queen")

func _on_larvae_button_pressed():
	print("Larvae button pressed")
	if game_manager and game_manager.has_method("get_world_builder"):
		var world_builder = game_manager.get_world_builder()
		if world_builder:
			world_builder.start_building_mode(world_builder.BuildMode.UNIT, "larvae")

func _on_spire_button_pressed():
	print("Spire button pressed")
	if game_manager and game_manager.has_method("get_world_builder"):
		var world_builder = game_manager.get_world_builder()
		if world_builder:
			world_builder.start_building_mode(world_builder.BuildMode.STRUCTURE, "spire")

func _on_nursery_button_pressed():
	print("Nursery button pressed")
	if game_manager and game_manager.has_method("get_world_builder"):
		var world_builder = game_manager.get_world_builder()
		if world_builder:
			world_builder.start_building_mode(world_builder.BuildMode.STRUCTURE, "nursery")

func _on_creep_node_button_pressed():
	print("Creep Node button pressed")
	if game_manager and game_manager.has_method("get_world_builder"):
		var world_builder = game_manager.get_world_builder()
		if world_builder:
			world_builder.start_building_mode(world_builder.BuildMode.STRUCTURE, "creep_node")
