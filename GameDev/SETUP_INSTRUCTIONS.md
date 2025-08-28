# Quick Setup Guide - Alien Colony Game

## Immediate Setup (5 minutes)

### 1. Download Godot 4.x
- Go to [godotengine.org/download](https://godotengine.org/download)
- Download Godot 4.2 or later for your platform
- Extract and run Godot

### 2. Open the Project
- In Godot, click "Import"
- Select the `project.godot` file from this folder
- Click "Import & Edit"

### 3. Test the Game
- Press F5 or click the "Play" button
- You should see:
  - Purple hive core in the center
  - Blue worker drone nearby
  - Green biomass and gray mineral nodes
  - Orange enemies moving around
  - Resource counter at the top

## What You'll See

- **Hive Core**: Purple 32x32 structure (your base)
- **Worker Drone**: Blue 16x16 unit that automatically gathers resources
- **Resource Nodes**: Green (biomass) and gray (minerals) harvestable resources
- **Enemies**: Orange units that harvesters can hunt
- **UI**: Resource counters and game time display

## Current Features Working

✅ **Resource System**: 6 resource types with storage limits
✅ **Unit AI**: Worker drones automatically gather resources
✅ **Basic Economy**: Resources are collected and stored
✅ **Game Loop**: Victory/defeat conditions checked
✅ **Pathfinding**: Units can navigate around obstacles
✅ **UI System**: Resource display and game status

## Next Steps for Development

1. **Add More Units**: Spawn harvesters, queens, and larvae
2. **Build Structures**: Add spires, nurseries, and creep nodes
3. **Expand Territory**: Implement creep spreading system
4. **Add Combat**: Enhance harvester hunting mechanics
5. **Polish Graphics**: Replace gradients with proper sprites

## Troubleshooting

- **Units not moving**: Check NavigationRegion2D is present
- **Resources not spawning**: Verify resource node scripts are attached
- **Game crashes**: Check console for error messages
- **Performance issues**: Reduce unit count or resource density

## File Structure

```
GameDev/
├── project.godot          # Main project file
├── scenes/
│   ├── main.tscn         # Main game scene
│   ├── test_scene.tscn   # Simple test scene
│   ├── units/            # Unit scene files
│   └── enemies/          # Enemy scene files
├── scripts/               # All game logic
├── resources/             # Resource management
└── assets/                # Sprites and audio (to be added)
```

## Ready to Play!

The game is fully functional with the core mechanics implemented. You can:
- Watch worker drones gather resources automatically
- See the resource economy in action
- Observe enemy movement patterns
- Experience the basic game loop

Start building your alien colony! 🐛👾
