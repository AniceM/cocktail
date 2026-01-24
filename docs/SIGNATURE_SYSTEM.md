# Signature System Documentation

## Overview

The signature system allows you to define complex cocktail patterns that unlock special effects. Signatures are defined as resources (`Signature.tres` files) with declarative conditions that are automatically validated.

## Architecture

### Core Components

1. **Signature** (`scripts/resources/signature.gd`) - Resource defining conditions and effects
2. **SignatureValidator** (`scripts/cocktail_system/signature_validator.gd`) - Validates cocktails against signatures
3. **ColorUtils** (`scripts/utils/color_utils.gd`) - Color matching and pattern detection

### How It Works

```gdscript
# In your cocktail mixing logic:
var all_signatures: Array[Signature] = load_all_signatures()
cocktail.detect_signatures(all_signatures)

# Signatures are now stored in cocktail.signatures
# And automatically boost secret reveal rates
```

## Signature Resource Fields

### Basic Info
- `name: String` - Display name
- `icon: Texture2D` - Visual icon
- `signature_type: SignatureType` - Category (SINGLE_FLAVOR, MULTI_FLAVOR, COLOR_BASED, RARE)
- `condition_description: String` - Human-readable conditions
- `effect_description: String` - Human-readable effects

### Capacity Requirements
- `min_capacity: int` - Minimum liquors that must be poured (default: 0)
  - **Note**: This counts total pours, not layers. Mixing doesn't change this count.
  - Example: Pour 5 liquors → mix → still 5 capacity used
- `max_capacity: int` - Maximum liquors allowed (default: 999)

### Layer Requirements
- `min_layers: int` - Minimum layers required (default: 0)
  - **Note**: Layer count changes when you mix. Pour 3 liquors = 3 layers, then mix = 1 layer.
- `max_layers: int` - Maximum layers allowed (default: 999)

### Flavor Requirements
- `required_flavors: Dictionary[Flavor, int]` - Flavor minimums (e.g., {Caustic: 5, Volatile: 3})

### Flavor Progression (across layers)
- `progression_flavor: Flavor` - Which flavor to track
- `flavor_progression: FlavorProgression` - Pattern type:
  - `NONE` - No progression requirement
  - `SAME_DOMINANT` - Same flavor dominant in all layers
  - `CRESCENDO` - Flavor increases bottom→top
  - `DECRESCENDO` - Flavor decreases bottom→top
  - `CONSTANT` - Flavor stays roughly same

### Color Requirements
- `color_requirement: ColorRequirement` - Pattern type:
  - `NONE` - No color requirement
  - `GRADIENT` - Smooth transition toward target
  - `ALTERNATING` - Layers alternate between colors
  - `MONOCHROME` - All layers same color
  - `SPECIFIC_SEQUENCE` - Exact color order
- `required_color_names: Array[ColorUtils.ColorName]` - Color(s) to match
  - `GRADIENT`: Requires 1 color (target)
  - `ALTERNATING`: Requires 2 colors
  - `MONOCHROME`: Requires 1 color
  - `SPECIFIC_SEQUENCE`: Requires N colors (matches layer count)

### Effects
- `boosted_secret_types: Array[SecretType]` - Which secrets get revealed more
- `suspicion_modifier: int` - Suspicion level change
- `reveal_bonus_percent: int` - Percentage boost to reveal rate

## Example Signatures

### Simple Flavor Signature
```
Name: "Nebula"
Type: MULTI_FLAVOR
Required Flavors: {Resonant: 4, Abyss: 4}
Min Capacity: 2
```

### Crescendo Pattern
```
Name: "Rising Heat"
Type: MULTI_FLAVOR
Min Layers: 3
Progression Flavor: Caustic
Flavor Progression: CRESCENDO
Condition: "Caustic increases with each layer"
```

### Color Gradient
```
Name: "Blue Depths"
Type: COLOR_BASED
Min Layers: 2
Color Requirement: GRADIENT
Required Color Names: [BLUE]
Condition: "Layers form blue gradient"
```

### Alternating Colors
```
Name: "Sunset Stripes"
Type: COLOR_BASED
Min Layers: 2
Color Requirement: ALTERNATING
Required Color Names: [RED, ORANGE]
Condition: "Red and orange layers alternate"
```

### Complex Multi-Condition
```
Name: "Paradox"
Type: RARE
Min Layers: 3
Required Flavors: {Temporal: 5, Void: 5}
Progression Flavor: Temporal
Flavor Progression: SAME_DOMINANT
Color Requirement: MONOCHROME
Required Color Names: [PURPLE]
Condition: "3+ purple layers, all Temporal-dominant, 5+ Temporal and Void"
```

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

## Performance Considerations

The validator checks conditions in order of computational cost:
1. Capacity (cheapest - simple counter)
2. Layer count (cheap - array size)
3. Required flavors (medium - dictionary lookups)
4. Flavor progression (expensive - iterates layers)
5. Color requirements (expensive - iterates layers + color math)

Early exits prevent unnecessary computation. With hundreds of signatures, only relevant ones should be in the database to check.

## Usage in Code

```gdscript
# Create a signature database (load from files or directory)
var signature_db: Array[Signature] = []
signature_db.append(preload("res://resources/signatures/nebula.tres"))
# ... add more

# After each cocktail change (pour, mix, add ingredient):
cocktail.detect_signatures(signature_db)

# Check what's unlocked:
for sig in cocktail.signatures:
    print("Unlocked: ", sig.name)

# Signatures automatically affect reveal rates:
var lie_reveal_rate = cocktail.get_reveal_rate(LIE_SECRET_TYPE)
```

## Extending the System

For signatures with unique conditions not covered by the declarative system, you can add new enum values or create custom validator functions in `SignatureValidator`. Keep most signatures declarative for easy iteration.
