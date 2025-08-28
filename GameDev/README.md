# Alien Colony Game

A 2D top-down alien colony simulation game built with Godot 4.x where you control autonomous units through indirect commands in a grid-based world.

## Game Overview

In Alien Colony, you manage an alien hive through strategic building placement and unit management. Your units operate autonomously, gathering resources, expanding territory, and evolving to create a thriving colony.

### Core Features

- **Autonomous Units**: Worker drones, harvesters, queens, and larvae that operate independently
- **Resource Management**: 6 different resource types with complex economy
- **Territory Control**: Expand your influence through creep spread and structure placement
- **Evolution System**: Research upgrades and unlock new unit types
- **Strategic Gameplay**: Indirect control through pheromone trails and priority zones

## Gameplay Mechanics

### Unit Types

- **Worker Drone** (16x16): Resource collection and construction
- **Harvester** (16x32): Hunting live prey and converting to biomass
- **Queen** (32x32): Egg production and area buffs
- **Larvae** (16x16): Development stages leading to new units

### Resource System

1. **Biomass**: Base resource from organic matter
2. **Live Prey**: Converted to biomass at hive core
3. **Genetic Material**: Required for evolution and advanced units
4. **Minerals**: Used for structure construction
5. **Secretions**: Automatically generated, used for creep expansion
6. **Eggs**: Produced by queen, develop into larvae

### Victory Conditions

- **Territory Control**: Creep covers 75% of playable area
- **Population Goal**: Maintain 50+ active units simultaneously
- **Survival**: Survive 300 seconds of continuous gameplay

### Defeat Conditions

- **Hive Core Destruction**: Core reaches 0 health
- **Population Collapse**: Less than 3 total units for 30 seconds
- **Resource Depletion**: All resources exhausted with insufficient stockpile

## Installation & Setup

### Prerequisites

- **Godot 4.x** (4.2 or later recommended)
- Windows, macOS, or Linux

### Setup Instructions

1. **Download Godot 4.x**
   - Visit [godotengine.org](https://godotengine.org/download)
   - Download the latest 4.x version for your platform

2. **Open the Project**
   - Launch Godot
   - Click "Import" and select the `project.godot` file
   - Click "Import & Edit"

3. **Run the Game**
   - Press F5 or click the "Play" button
   - The game will start with a basic hive core and resource nodes

### Project Structure

```
GameDev/
├── project.godot          # Godot project configuration
├── scenes/
│   └── main.tscn         # Main game scene
├── scripts/
│   ├── game_manager.gd   # Main game logic
│   ├── unit.gd           # Base unit class
│   ├── worker_drone.gd   # Worker drone implementation
│   ├── harvester.gd      # Harvester implementation
│   ├── queen.gd          # Queen implementation
│   ├── larvae.gd         # Larvae implementation
│   ├── structure.gd      # Base structure class
│   ├── hive_core.gd      # Hive core implementation
│   ├── resource_node.gd  # Resource system
│   └── ui.gd             # User interface
├── resources/
│   └── game_resources.gd # Resource management system
└── assets/
	├── sprites/          # Game sprites and textures
	└── audio/            # Sound effects and music
```

## Development

### Current Implementation Status

**Phase 1 (Core Loop) - COMPLETE ✅**
- Basic tilemap rendering
- Worker drone with gathering behavior
- Hive core with resource storage
- Basic UI showing resource counts
- Resource node system
- Game manager with victory/defeat conditions

**Phase 2 (Unit Expansion) - IN PROGRESS 🔄**
- Harvester units with combat mechanics
- Queen with egg production
- Larvae development system
- Basic AI state machines

**Phase 3 (Territory System) - PLANNED 📋**
- Creep spreading mechanics
- Spire construction and buffs
- Pheromone trail system
- Advanced pathfinding

**Phase 4 (Polish) - PLANNED 📋**
- Audio integration
- Environmental hazards
- Evolution chamber upgrades
- Economy balancing

### Adding New Features

#### Creating New Units

1. Create a new script extending the `Unit` class
2. Implement unit-specific behavior in `check_for_tasks()`
3. Add the unit to the hive core's spawn system
4. Create corresponding scene file

#### Adding New Structures

1. Create a new script extending the `Structure` class
2. Set construction costs and functionality
3. Implement `on_construction_complete()` method
4. Add to building UI system

#### Resource Types

1. Add new resource to `GameResources` class
2. Update storage limits and methods
3. Modify UI display
4. Add to resource node system

### Code Style Guidelines

- Use descriptive variable and function names
- Follow GDScript naming conventions
- Add comments for complex logic
- Use proper error handling
- Implement proper resource management

## Controls

- **Left Click**: Select units and create pheromone trails
- **Right Click**: Set priority zones and assign behaviors
- **Mouse Drag**: Create waypoint paths for units
- **ESC**: Pause game

## Performance Considerations

- Units use efficient pathfinding with NavigationAgent2D
- Resource collection uses timers to avoid constant updates
- UI updates are optimized to run only when necessary
- Scene instancing is managed through object pooling

## Troubleshooting

### Common Issues

1. **Units not moving**: Check if NavigationServer2D is properly set up
2. **Resources not spawning**: Verify resource node scripts are attached
3. **UI not updating**: Ensure GameManager is properly referenced
4. **Performance issues**: Check unit count and resource node density

### Debug Mode

Enable debug output by setting `debug_mode = true` in the GameManager script.

## Contributing

This is a personal development project, but suggestions and improvements are welcome! The code is structured to be easily extensible for new features.

## License

This project is created for educational and personal use. Feel free to use the code as a reference for your own projects.

## Future Enhancements

- **Multiplayer Support**: Cooperative colony management
- **Mod Support**: Custom unit and structure types
- **Campaign Mode**: Story-driven progression
- **Advanced AI**: More sophisticated enemy behaviors
- **Visual Effects**: Particle systems and animations
- **Sound Design**: Ambient audio and unit sounds

---

**Happy Colony Building! 🐛👾**
