# Alien Colony Game - Technical Specification

## Core Requirements
2D top-down alien colony simulation. Player controls autonomous units through indirect commands. Grid-based movement on 16x16 tilemap.

## Asset Specifications

### Sprite Dimensions
- Ground units: 16x16 pixels
- Large units: 32x32 pixels
- Tall structures: 16x32 pixels
- Wide structures: 32x16 pixels
- Small units: 16x16 pixels (can be smaller within canvas)

### Required Animations Per Unit
- Idle: 2-4 frames, 0.5 second loop
- Movement: 4-6 frames, 0.3 second loop
- Action: 3-5 frames, 0.4 second duration
- Death: 4-6 frames, 0.6 second duration, no loop

## Unit Specifications

### Worker Drone
- **Size**: 16x16 pixels
- **Function**: Resource collection, construction
- **Speed**: 32 pixels/second
- **Carry capacity**: 1 resource unit
- **AI behavior**: Pathfind to nearest resource node, return to hive core
- **Animations**: Idle, movement, gathering, carrying

### Harvester
- **Size**: 16x32 pixels
- **Function**: Hunt live prey, convert to biomass
- **Speed**: 48 pixels/second
- **Carry capacity**: 1 prey unit
- **AI behavior**: Patrol assigned radius, attack non-hive entities
- **Animations**: Idle, movement, attack, dragging

### Queen
- **Size**: 32x32 pixels
- **Function**: Produce eggs, provide area buffs
- **Speed**: 0 (stationary)
- **Production rate**: 1 egg per 10 seconds when resources available
- **Buff radius**: 128 pixels
- **Animations**: Idle, egg laying, buff activation

### Larvae
- **Size**: 16x16 pixels
- **Function**: Develop into other units
- **Speed**: 8 pixels/second
- **Growth time**: 15 seconds per stage, 3 stages total
- **AI behavior**: Move toward nursery structures
- **Animations**: Stage 1, stage 2, stage 3, pupation

## Resource System

### Resource Types
1. **Biomass**
   - Base value: 1 unit
   - Sources: Dead organisms, organic debris
   - Collection time: 2 seconds
   - Storage limit: 100 units per hive core

2. **Live Prey**
   - Base value: 3 biomass when converted
   - Sources: Non-hive living entities
   - Capture time: 3 seconds combat
   - Conversion time: 5 seconds at hive core

3. **Genetic Material**
   - Base value: 1 unit
   - Sources: Consumed prey (20% chance drop)
   - Required for: Evolution upgrades, advanced units
   - Storage limit: 50 units per hive core

4. **Minerals**
   - Base value: 1 unit
   - Sources: Rock nodes, metal deposits
   - Collection time: 3 seconds
   - Required for: Structure construction
   - Storage limit: 75 units per hive core

5. **Secretions**
   - Generation rate: 1 unit per 30 seconds per unit
   - Sources: All living units produce automatically
   - Required for: Creep expansion
   - Storage limit: 200 units per hive core

6. **Eggs**
   - Production cost: 2 biomass + 1 genetic material
   - Development time: 45 seconds to larvae
   - Storage: Nursery structures or hive core
   - Maximum storage: 10 per structure

## Structure Specifications

### Hive Core
- **Size**: 32x32 pixels
- **Cost**: Starting structure
- **Function**: Resource storage, unit spawning point
- **Storage capacity**: All resource types at listed limits
- **Required for**: Game victory condition

### Spire
- **Size**: 16x32 pixels
- **Cost**: 10 minerals + 5 biomass
- **Function**: Vision extension, area coordination, defense
- **Vision radius**: 256 pixels
- **Coordination buff**: +25% speed to units in 128 pixel radius
- **Attack damage**: 2 damage per second to enemies in range
- **Attack range**: 96 pixels

### Nursery
- **Size**: 32x16 pixels
- **Cost**: 8 biomass + 3 genetic material
- **Function**: Accelerated larvae development, egg storage
- **Development speed**: 50% faster larvae growth
- **Storage capacity**: 20 eggs maximum
- **Auto-production**: 1 larvae per 20 seconds when resources available

### Creep Node
- **Size**: 16x16 pixels
- **Cost**: 3 secretions + 2 biomass
- **Function**: Territory expansion, movement bonus
- **Creep spread rate**: 1 tile per 2 seconds in cardinal directions
- **Movement bonus**: +50% speed for hive units
- **Enemy movement penalty**: -50% speed for non-hive units

### Evolution Chamber
- **Size**: 24x24 pixels (non-standard, centered on grid)
- **Cost**: 15 genetic material + 10 minerals
- **Function**: Unlock unit upgrades and new unit types
- **Research time**: 60 seconds per upgrade
- **Capacity**: Process 1 research at a time

## Game Mechanics

### Control System
- **Pheromone Trails**: Click-drag creates waypoint paths, units follow nearest trail
- **Priority Zones**: Right-click areas to assign gathering/patrolling behavior
- **Structure Placement**: Buildings auto-assign nearby units to relevant tasks
- **Evolution Queue**: Select upgrades from tech tree interface

### Pathfinding Requirements
- A* algorithm implementation
- 16x16 grid-based movement
- Obstacle avoidance for environmental hazards
- Dynamic path recalculation when blocked
- Unit collision avoidance (units can occupy same tile but path around each other)

### Victory Conditions
- **Territory Control**: Creep covers 75% of playable area
- **Population Goal**: Maintain 50+ active units simultaneously
- **Survival**: Survive 300 seconds of continuous gameplay

### Defeat Conditions
- **Hive Core Destruction**: Core reaches 0 health
- **Population Collapse**: Less than 3 total units for 30 seconds
- **Resource Depletion**: All resource nodes exhausted with insufficient stockpile

## Technical Implementation

### Engine: Godot 4.x
Required systems:
1. **TileMap**: 16x16 grid with collision layers
2. **AnimatedSprite2D**: Frame-based unit animations
3. **NavigationServer2D**: Pathfinding implementation
4. **Resource**: Custom resource types for game economy
5. **StateMachine**: Unit AI behavior states
6. **UI**: Resource counters, building buttons, upgrade interface

### Scene Structure
```
Main
├── TileMap (terrain layer)
├── TileMap (creep layer)  
├── Units (Node2D container)
├── Structures (Node2D container)
├── Resources (Node2D container)
├── UI (CanvasLayer)
└── GameManager (Node)
```

### Core Scripts Required
- `GameManager.gd`: Resource tracking, victory conditions, unit spawning
- `Unit.gd`: Base unit class with AI state machine
- `Structure.gd`: Base building class with production logic
- `ResourceNode.gd`: Harvestable resource points
- `Pathfinding.gd`: Navigation and movement logic
- `UI.gd`: Interface updates and player input handling

### Asset Integration
- Import provided 16x16 tileset for terrain
- Import provided audio files for ambient sound
- Create unit sprites matching 16x16 specifications
- Create structure sprites at specified dimensions
- Implement provided hazard objects (rotation platforms, wall spikes)

## Development Phases

### Phase 1 (Core Loop)
- Implement basic tilemap rendering
- Create worker drone with gathering behavior
- Add hive core with resource storage
- Basic UI showing resource counts

### Phase 2 (Unit Expansion)
- Add harvester units with combat
- Implement queen with egg production
- Add larvae development system
- Create nursery structures

### Phase 3 (Territory System)
- Implement creep spreading mechanics
- Add spire construction and buffs
- Create pheromone trail system
- Add victory/defeat condition checking

### Phase 4 (Polish)
- Integrate provided audio assets
- Add environmental hazard interaction
- Implement evolution chamber upgrades
- Balance resource economy and timing