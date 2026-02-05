# Signature & Condition System Documentation

## Overview

The signature system allows you to define complex cocktail patterns that unlock special effects. Signatures are defined as resources (`Signature.tres` files) containing an array of reusable `CocktailCondition` sub-resources.

## Architecture

### Core Components

1. **Signature** (`scripts/resources/signature.gd`) - Resource combining conditions and effects
2. **CocktailCondition** (`scripts/cocktail_system/conditions/`) - Polymorphic condition resources
3. **ColorUtils** (`scripts/utils/color_utils.gd`) - Color matching and pattern detection

### Condition Types

| Class | Fields | What it checks |
|-------|--------|---------------|
| `CapacityCondition` | `min_capacity`, `max_capacity` | Number of liquors poured |
| `LayerCondition` | `min_layers`, `max_layers` | Number of layers |
| `FlavorCondition` | `min_flavors`, `max_flavors` | Total cocktail flavor stats |
| `FlavorProgressionCondition` | `flavor`, `progression`, `constant_tolerance` | Flavor pattern across layers |
| `ColorCondition` | `requirement`, `required_color_names` | Color pattern across layers |

Each condition implements `is_met(cocktail: Cocktail) -> bool`.

### How It Works

```gdscript
# After each cocktail change (pour, mix, add ingredient):
cocktail.detect_signatures()

# Check what's unlocked:
for sig in cocktail.signatures:
    print("Unlocked: ", sig.name)

# Signatures automatically affect reveal rates:
var lie_reveal_rate = cocktail.get_reveal_rate(LIE_SECRET_TYPE)
```

## Signature Resource Fields

### Basic Info
- `name: String` - Display name
- `icon: Texture2D` - Visual icon
- `condition_description: String` - Human-readable conditions
- `effect_description: String` - Human-readable effects

### Conditions
- `conditions: Array[CocktailCondition]` - All conditions must be met for the signature to unlock

Glow color is inferred from the condition types present. A signature with all three types (color, progression, and flavors) is considered **rare** and gets a special glow.

### Effects
- `boosted_secret_types: Array[SecretType]` - Which secrets get revealed more
- `suspicion_modifier: int` - Suspicion level change
- `reveal_bonus_percent: int` - Percentage boost to reveal rate

## Condition Details

### CapacityCondition
- `min_capacity: int` (default: 0) - Minimum liquors poured
- `max_capacity: int` (default: 999) - Maximum liquors allowed
- **Note**: Counts total pours. Mixing doesn't change this count.

### LayerCondition
- `min_layers: int` (default: 0) - Minimum layers required
- `max_layers: int` (default: 999) - Maximum layers allowed
- **Note**: Layer count changes when you mix. Pour 3 liquors = 3 layers, then mix = 1 layer.

### FlavorCondition
- `min_flavors: Dictionary[Flavor, int]` - Flavor minimums (e.g., {Caustic: 5, Volatile: 3})
- `max_flavors: Dictionary[Flavor, int]` - Flavor maximums (optional upper bounds)

### FlavorProgressionCondition
- `flavor: Flavor` - Which flavor to track across layers
- `progression: Progression` - Pattern type:
  - `SAME_DOMINANT` - Same flavor dominant in all layers
  - `CRESCENDO` - Flavor increases bottom→top
  - `DECRESCENDO` - Flavor decreases bottom→top
  - `CONSTANT` - Flavor stays roughly same (within `constant_tolerance`)
- `constant_tolerance: int` (default: 1) - Allowed deviation for CONSTANT

### ColorCondition
- `requirement: Requirement` - Pattern type:
  - `GRADIENT` - Smooth transition toward target (requires 1 color)
  - `ALTERNATING` - Layers alternate between colors (requires 2 colors)
  - `MONOCHROME` - All layers same color (requires 1 color)
  - `SPECIFIC_SEQUENCE` - Exact color order (requires N colors matching layer count)
- `required_color_names: Array[ColorUtils.ColorName]` - Color(s) to match

## Example Signatures

### Simple Flavor Signature
```
Name: "Nebula"
Conditions:
  - CapacityCondition(min_capacity=2)
  - FlavorCondition(min_flavors={Resonant: 4, Abyss: 4})
```

### Crescendo Pattern
```
Name: "Rising Heat"
Conditions:
  - LayerCondition(min_layers=3)
  - FlavorProgressionCondition(flavor=Caustic, progression=CRESCENDO)
```

### Color Monochrome
```
Name: "Blue Purity"
Conditions:
  - CapacityCondition(min_capacity=1)
  - LayerCondition(min_layers=1, max_layers=1)
  - ColorCondition(requirement=MONOCHROME, colors=[BLUE])
```

### Complex Multi-Condition (Rare)
```
Name: "Paradox"
Conditions:
  - LayerCondition(min_layers=3)
  - FlavorCondition(min_flavors={Temporal: 5, Void: 5})
  - FlavorProgressionCondition(flavor=Temporal, progression=SAME_DOMINANT)
  - ColorCondition(requirement=MONOCHROME, colors=[PURPLE])
```
*Glow: **Rare** (has color + progression + flavor conditions)*

## ColorUtils.ColorName Enum

Available color names for matching:
- `RED` - Hue ~0°
- `ORANGE` - Hue ~30°
- `YELLOW` - Hue ~60°
- `GREEN` - Hue ~120°
- `CYAN` - Hue ~180°
- `BLUE` - Hue ~240°
- `PURPLE` - Hue ~280°
- `PINK` - Hue ~330°
- `WHITE` - Low saturation, high value
- `BLACK` - Low value

Color matching uses HSV with 30° hue tolerance by default.

## Extending the System

To add a new condition type:
1. Create a new class extending `CocktailCondition` in `scripts/cocktail_system/conditions/`
2. Implement `is_met(cocktail: Cocktail) -> bool`
3. The new type automatically appears in the Godot inspector dropdown when adding conditions to a Signature

CocktailConditions are reusable beyond signatures — any system that needs to check cocktail state (story gates, tutorials, achievements) can use them directly.
