# Cocktail Mixer System

A 2D liquid pouring animation system for Godot 4.5, designed for cocktail mixing mechanics.

## Files

- **liquid_layer.gd** - Data structure representing a single liquid layer (color + amount)
- **liquid_container.gd** - Container class for glasses and bottles that can hold liquid layers
- **cocktail_mixer.gd** - Main controller that manages pouring between containers
- **cocktail_mixer.tscn** - Demo scene with 1 glass and 4 bottles
- **setup_demo.gd** - Editor script to initialize bottles with demo liquids

## How to Use

### Setup Demo Scene

1. Open `cocktail_mixer.tscn` in the Godot editor
2. To add demo liquids to bottles, you have two options:

   **Option A - Use EditorScript:**
   - Open `setup_demo.gd`
   - Go to `Tools > Execute EditorScript`

   **Option B - Manual setup in code:**
   - Select a bottle node in the scene
   - Attach a script or use the ready function to call:
     ```gdscript
     add_liquid_layer(Color.RED, 120.0)  # Add 120px of red liquid
     ```

3. Run the scene (F5 or F6)
4. Click on any bottle to pour its contents into the glass

### How It Works

- **Bottles** contain pre-filled liquid layers
- **Glass** starts empty and receives liquid
- **Clicking a bottle** triggers a pour animation
- Each bottle pours a **fixed amount** (configurable via `pour_amount` export)
- Liquid layers of the same color merge automatically
- Pour animation shows a curved stream of liquid flowing from bottle to glass

### Customization

**On LiquidContainer nodes:**
- `container_width` - Width of the container
- `container_height` - Height of the container
- `max_capacity` - Maximum liquid height
- `pour_amount` - How much to pour per click (bottles only)
- `is_bottle` - true for bottles, false for glass

**Adding liquids programmatically:**
```gdscript
# Get a bottle reference
var bottle = $Bottle1

# Add liquid layers (color, amount in pixels)
bottle.add_liquid_layer(Color(0.8, 0.1, 0.1), 120.0)  # Red layer
bottle.add_liquid_layer(Color(1.0, 0.6, 0.1), 80.0)   # Orange layer
```

## Architecture

1. **LiquidLayer** - Simple data class for a colored liquid segment
2. **LiquidContainer** - Handles liquid storage, rendering, and click detection
3. **CocktailMixer** - Orchestrates pouring between containers with animation
4. **PourStream** - Inner class that renders the animated liquid stream

The system uses signals for communication and Godot's Tween system for smooth animations.
