This Godot Project is a smaller part of a bigger game.

I am implementing a "cocktail mixing" minigame.

## Gameplay Overview

### Basic Mixing Flow

1. **Receive Order** - Customer may request specific conditions (optional, currently randomized for testing)
2. **Select Glass** - Each has different capacity (3-6 slots) and special properties
3. **Add Liquors** - Each liquor has flavor stats and a color
4. **Mix or Layer** - Choose to combine liquors or keep them separate
5. **Add Special Ingredient** - Optional, one per drink
6. **Serve** - Must meet customer conditions (if any). Final drink determines which secrets are highlighted during interrogation

### Flavor Stats System

There are six flavors:

- Volatile
- Caustic
- Resonant
- Drift
- Temporal
- Void

Each liquor has statistics for some of these flavors.
Typically, a liquor will have 1 main flavor, 1 secondary flavor, and 1 negative flavor.
The flavors are defined as resources inside `./resources/flavors`.

### Special Ingredients

Can add ONE special ingredient per drink (doesn't use glass capacity).
This is a temporary list of example purposes.

- **Stardust Bitters**: Caustic +3, all others -1
- **Entropy Syrup**: Multiple stats +2, all others -2
- **Quantum Foam**: Random +4 to one stat (changes each time)

The special ingredients are defined as resources inside `./resources/special_ingredients`.

### Glasses

Each glass a certain capacity (which is the amount of times you can pour a liquid inside).
They can also have predetermined special effects.

The glasses are defined as resources inside `./resources/glasses`.

### Layer System

**Creating Layers:**

- Each time you press MIX, all unmixed liquors in the glass combine into one layer
- Liquors added after mixing create a new layer on top
- Each layer has its own color and combined flavor stats

### Cocktail Conditions

Conditions are checks that evaluate whether a cocktail meets certain requirements. Defined in `./resources/conditions/`.

**Condition Types:**
- **FlavorCondition**: Checks if cocktail has minimum flavor values (e.g., Caustic ≥ 5)
- **LayerCondition**: Checks layer count requirements
- **ColorCondition**: Checks cocktail color properties

Conditions are used by both signatures (bonus effects) and customer orders (requirements to serve).

### Signatures

Signatures are special combinations that unlock bonus effects when their conditions are met. Each signature contains a list of cocktail conditions.

**Examples:**
- 2 layers + Caustic 5+ and Volatile 5+ (flavor + layer conditions)
- At least 3 layers with decrescendo Caustic values (layer + flavor pattern)

Signatures are defined as resources inside `./resources/signatures`.

### Recipes

Recipes are ordered lists of steps to create specific cocktails. Each step can specify actions like "add liquor X", "mix layers", "add special ingredient Y". Recipes help players recreate successful combinations.

## Connection to the bigger game

The bigger game is an interactive Visual Novel where the player can click on words inside the dialog box itself in order to reveal potential "secrets" behind them.

There are several types of secrets (`./resources/secret_types`), such as "lie" and "omission".

When going through a dialogue (an "interrogation" phase), the player has to guess what words have secrets behind them.
In order to help the player, prior to talking to the characters, they can serve them drinks with a certain flavor profile.
This flavor profile will determine the pre-reveal percentage for certain types of "secrets".
A pre-revealed secret will have its associated word animated in a way that makes it easy for the player to know it hides a secret.

If the cocktail served has a 90% pre-reveal percentage for "lie" secrets, each "lie" present in the dialogue will have a 90% chance of being pre-revealed.

## Glass Scene & Liquid Rendering

The cocktail visuals are rendered using a custom shader (`resources/shaders/fake_liquid.gdshader`) managed by `scripts/scenes/glass_scene.gd`.

**Shader Features:**
- Ellipse top surface + expanding cone body (glass perspective)
- Depth, surface, and side darkening for visual depth
- Wobble and splash animations on pour
- Wave glow to brighten ripple effects
- Rim highlighting for glass appearance

**Glass Scene Features:**
- Manages liquid color display (reads from liquor resources)
- Supports layered drinks (stacked liquors show visually separated)
- Animates pouring (position, scale, color transitions)
- Blends colors when mixing layers

Liquor colors are defined in `resources/liquors/` with vibrant, semi-transparent colors (alpha 0.78-0.88).

## Development Status

It's still very early in the development of the cocktail mixing mechanic, or the bigger game itself.

# Development Environment

- Godot 4.6
- VS Code Editor
