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
var game_manager: GameManager

func _ready():
	# Find game manager
	game_manager = get_node("/root/Main/GameManager")
	
	# Setup UI
	setup_ui()
	
	# Connect building button signals
	connect_building_buttons()

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

func update_resource_display(resources: GameResources):
	if not resources:
		return
	
	biomass_label.text = "Biomass: " + str(resources.biomass)
	minerals_label.text = "Minerals: " + str(resources.minerals)
	genetic_material_label.text = "Genetic: " + str(resources.genetic_material)
	secretions_label.text = "Secretions: " + str(resources.secretions)
	eggs_label.text = "Eggs: " + str(resources.eggs)

func update_game_time(seconds: float):
	var minutes = int(seconds) / 60
	var remaining_seconds = int(seconds) % 60
	time_label.text = "Time: " + str(minutes) + ":" + str(remaining_seconds).pad_zeros(2)

func update_unit_count(count: int):
	units_label.text = "Units: " + str(count)

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
	title_label.text = "VICTORY!" if is_victory else "DEFEAT!"
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
	restart_button.add_theme_font_size_override("font_size", 20)
	restart_button.pressed.connect(_on_restart_pressed)
	message_container.add_child(restart_button)
	
	# Create quit button
	var quit_button = Button.new()
	quit_button.text = "Quit to Menu"
	quit_button.add_theme_font_size_override("font_size", 20)
	quit_button.pressed.connect(_on_quit_pressed)
	message_container.add_child(quit_button)

func _on_restart_pressed():
	if game_manager:
		game_manager.restart_game()

func _on_quit_pressed():
	# Return to main menu or quit game
	get_tree().quit()

func update_ui():
	if game_manager:
		# Update resource display
		update_resource_display(game_manager.get_current_resources())
		
		# Update game time
		update_game_time(game_manager.get_game_time())
		
		# Update unit count
		if game_manager.hive_core:
			update_unit_count(game_manager.hive_core.get_current_units_count())

func _process(delta):
	# Update UI every frame
	update_ui()

# Building button signal handlers
func _on_worker_drone_button_pressed():
	print("Worker Drone button pressed")
	# The world builder will handle the actual building logic

func _on_harvester_button_pressed():
	print("Harvester button pressed")

func _on_queen_button_pressed():
	print("Queen button pressed")

func _on_larvae_button_pressed():
	print("Larvae button pressed")

func _on_spire_button_pressed():
	print("Spire button pressed")

func _on_nursery_button_pressed():
	print("Nursery button pressed")

func _on_creep_node_button_pressed():
	print("Creep Node button pressed")
