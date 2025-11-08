# Cocktail Mixing - Gameplay Overview

## Core Mechanics

### Basic Mixing Flow

1. **Select Glass** - Each has different capacity (3-6 slots) and special properties
2. **Add Liquors** - Each liquor has flavor stats and a color
3. **Mix or Layer** - Choose to combine liquors or keep them separate
4. **Serve** - The final drink determines which secrets are highlighted during interrogation

### Flavor Stats System

Each liquor has numerical values for 6 flavor profiles:

- **Caustic** (Sharp) → Reveals Lie/Contradiction secrets
- **Volatile** (Spicy) → Reveals Emotion/Anomaly secrets
- etc... (see [Compendium](https://www.notion.so/Cocktail-Mixing-Compendium-29a4d7180a6780999e5dc0643206ef3c?pvs=21))

Stats stack when mixed:

- Same flavors add together (Caustic 3 + Caustic 2 = Caustic 5)
- Negative stats subtract (Resonant 4 + Resonant -2 = Resonant 2)

### Layer System

**Creating Layers:**

- Each time you press MIX, all unmixed liquors in the glass combine into one layer
- Liquors added after mixing create a new layer on top
- Each layer has its own color and combined flavor stats

**Example:**

```sql
Add Blue Gin → Add Red Vodka → MIX → [Purple Layer]
Add Yellow Mead → [Purple Layer + Yellow Layer on top]
```

**Visual Representation:**

```bash
[Glass Preview]
╭─────╮
│Yellow│ ← Layer 2 (unmixed)
├─────┤
│Purple│ ← Layer 1 (mixed)
╰─────╯
```

### The Mixing Glass (Mid-Game Unlock)

**"The Relay"** - A 2-slot side glass that allows you to:

- Pre-mix liquors separately from the main glass
- Pour the result as a complete layer
- Create "impossible" combinations (same color, different stats)

### Signatures (Resonances)

Special combinations that provide bonus effects:

**Flavor-Based Signatures:**

- Achieved by reaching specific flavor thresholds
- Example: "Solar Flare" = Volatile 8+

**Layer-Based Signatures:**

- Depend on color arrangement or layer count
- Example: "Stellar Cascade" = Purple → Blue → Black layers
- Example: "Memory Fade" = Same color getting progressively lighter

**Multi-Layer Signatures:**

- "Quantum Echo" = Resonant 4+ in multiple separate layers
- "Afterimage" = Same color in non-adjacent layers

### Secret Revelation System

During interrogation, your cocktail's dominant flavors determine which secrets are pre-highlighted:

**Reveal Rate = (Flavor Value × 10)%**

- Caustic 6 = 60% chance to highlight each Lie
- Void 8 = 80% chance to highlight each Omission

**Balance Considerations:**

- Single flavor too high (9+) = Character gets suspicious (-1 suspicion meter)
- Perfect balance (all flavors 3-4) = Safe but lower reveal rates
- Signature bonuses can boost specific secret types

### Special Ingredients

Can add ONE special ingredient per drink (doesn't use glass capacity):

- **Stardust Bitters**: Caustic +3, all others -1
- **Entropy Syrup**: Multiple stats +2, all others -2
- **Quantum Foam**: Random +4 to one stat (changes each time)

### Glass Progression

**Early Game:**

- Signal Glass (3 slots) - Forces focused builds
- Echo Flask (4 slots) - Basic mixing room

**Mid Game:**

- Aether Highball (5 slots) - More complexity
- The Relay unlocks - Mixing glass for advanced techniques

**Late Game:**

- Meridian Tumbler (6 slots) - Maximum layers
- Singularity Shot (4 slots, doubles stats) - High risk/reward
- Graviton Snifter (3 slots, negatives→positives) - Transforms bad combinations

### Strategic Tips

1. **Match Character Preferences**: Each suspect prefers certain Signatures
2. **Layer for Tags**: Some Signatures require specific layer arrangements
3. **Use Mixing Glass**: Create complex multi-tag drinks in late game
4. **Balance Risk**: Higher stats = better reveals but risk suspicion
5. **Experiment**: Discovering new recipes provides permanent bonuses

### Recipe Discovery

When you create specific combinations, you unlock named recipes:

- Unlocked recipes are 20% more effective
- First discovery unlocks recipe in the recipe book
- Each character has 1 favorite drink recipe
    - Last Chapter requires the player to mix their favorite drink (?)

### Example Full Process

**Goal:** Reveal Horatio's lies and emotional secrets

1. Select "Echo Flask" (4 slots, amplifies dominant flavor)
2. Add Plasma Vodka (Volatile +5, Caustic +1)
3. Add Stardust Bitters (Caustic +3)
4. MIX → Creates red crystalline layer
5. Stats: Volatile 5, Caustic 4 = "Supernova" Signature
6. During interrogation: 50% of Emotions and 40% of Lies pre-highlighted
7. Horatio appreciates the "Supernova" signature (+1 suspicion meter)