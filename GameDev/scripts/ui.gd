class_name UI
extends Control

# UI References
@onready var resource_display: Control = $ResourceDisplay
@onready var game_status: Control = $GameStatus
@onready var building_buttons: Control = $BuildingButtons

# Resource Labels
@onready var biomass_label: Label = $ResourceDisplay/BiomassLabel
@onready var minerals_label: Label = $ResourceDisplay/MineralsLabel

# Game Status Labels
@onready var unit_count_label: Label = $GameStatus/UnitCountLabel
@onready var corruption_label: Label = $GameStatus/CorruptionLabel
@onready var nests_label: Label = $GameStatus/NestsLabel

# Building Buttons
@onready var worker_drone_button: Button = $BuildingButtons/WorkerDroneButton
@onready var nest_button: Button = $BuildingButtons/NestButton
@onready var restart_button: Button = $BuildingButtons/RestartButton

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
	update_unit_count(0)
	update_corruption_display(0)
	update_nests_display(0)

func connect_building_buttons():
	# Connect unit buttons
	if worker_drone_button:
		worker_drone_button.pressed.connect(_on_worker_drone_button_pressed)
	if nest_button:
		nest_button.pressed.connect(_on_nest_button_pressed)
	if restart_button:
		restart_button.pressed.connect(_on_restart_button_pressed)

func _on_update_timer_timeout():
	# Update resource display
	if hive_core and hive_core.has_method("get_total_resources"):
		var resources = hive_core.get_total_resources()
		update_resource_display(resources)
	
	# Update unit count
	if hive_core and hive_core.has_method("get_current_units_count"):
		var unit_count = hive_core.get_current_units_count()
		update_unit_count(unit_count)
	
	# Update corruption display
	if game_manager and game_manager.has_method("get_corruption_percentage"):
		var corruption = game_manager.get_corruption_percentage()
		update_corruption_display(corruption)
	
	# Update nests display
	if game_manager and game_manager.has_method("get_nest_count"):
		var nest_count = game_manager.get_nest_count()
		update_nests_display(nest_count)

func update_resource_display(resources: GameResources):
	if not resources:
		return
	
	biomass_label.text = "Biomass: " + str(resources.biomass) + "/" + str(resources.BIOMASS_LIMIT)
	minerals_label.text = "Minerals: " + str(resources.minerals) + "/" + str(resources.MINERALS_LIMIT)
	
	# Color coding for low resources
	if resources.biomass < 5:
		biomass_label.modulate = Color(1, 0.5, 0.5)  # Red tint for low biomass
	else:
		biomass_label.modulate = Color(1, 1, 1)  # Normal white
	
	if resources.minerals < 2:
		minerals_label.modulate = Color(1, 0.5, 0.5)  # Red tint for low minerals
	else:
		minerals_label.modulate = Color(1, 1, 1)  # Normal white

func update_unit_count(count: int):
	var max_units = 20
	unit_count_label.text = "Units: " + str(count) + "/" + str(max_units)
	
	# Color coding for near capacity
	if count >= max_units * 0.8:
		unit_count_label.modulate = Color(1, 0.5, 0.5)  # Red tint for near capacity
	elif count >= max_units * 0.6:
		unit_count_label.modulate = Color(1, 1, 0.5)  # Yellow tint for moderate
	else:
		unit_count_label.modulate = Color(1, 1, 1)  # Normal white

func update_corruption_display(percentage: int):
	corruption_label.text = "Corruption: " + str(percentage) + "%"
	
	# Color coding for corruption level
	if percentage >= 75:
		corruption_label.modulate = Color(0.8, 0.2, 0.8)  # Purple for high corruption
	elif percentage >= 50:
		corruption_label.modulate = Color(0.6, 0.4, 0.8)  # Blue-purple for medium
	else:
		corruption_label.modulate = Color(1, 1, 1)  # Normal white

func update_nests_display(count: int):
	var max_nests = 5
	nests_label.text = "Nests: " + str(count) + "/" + str(max_nests)
	
	# Color coding for nest capacity
	if count >= max_nests:
		nests_label.modulate = Color(1, 0.5, 0.5)  # Red tint for max nests
	elif count >= max_nests * 0.8:
		nests_label.modulate = Color(1, 1, 0.5)  # Yellow tint for near max
	else:
		nests_label.modulate = Color(1, 1, 1)  # Normal white

func _on_worker_drone_button_pressed():
	if game_manager and game_manager.has_method("get_world_builder"):
		var world_builder = game_manager.get_world_builder()
		if world_builder and world_builder.has_method("start_building_mode"):
			world_builder.start_building_mode("worker_drone")

func _on_nest_button_pressed():
	if game_manager and game_manager.has_method("get_world_builder"):
		var world_builder = game_manager.get_world_builder()
		if world_builder and world_builder.has_method("start_building_mode"):
			world_builder.start_building_mode("nest")

func _on_restart_button_pressed():
	get_tree().reload_current_scene()
