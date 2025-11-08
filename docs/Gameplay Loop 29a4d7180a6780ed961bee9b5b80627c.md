# Gameplay Loop

# Game Overview

**Core Premise:** Player is an undercover bartender investigating a murder on an airship over 50 days. Must interrogate passengers through interactive dialogue to uncover secrets before suspects leave the airship.

**Win Condition:** Gather all key information from all suspects by Day 50 to understand the full context of the murder.

## Core Gameplay Loop

### HIGH-LEVEL FLOW

```
1. Day Start (Evening)
2. Character Selection
3. Pre-Interrogation
4. Cocktail Mixing
5. Interrogation
6. Success/Failure
7. Day End
Repeat
```

---

### DETAILED BREAKDOWN

### 1. DAY START

UI Elements:

<aside>

- Current day counter

2 choices:

1. Include the day of the week. Makes it for the player to remember the suspects' available days (ex: Morrigan available on Tue/Fri/Sun).
2. No day of the week. The suspects' availability is more nebulous (every 3 days, 1-3-1-3 cycle of absent days, ...)
</aside>

<aside>

- Character Availability

Several choices here:

1. Simple 2D grid showing which suspects are present today. This does not allow for suspects talking between themselves.
2. 2D background of the bar, with the available suspects sitting somewhere. Some suspects sometime sit together and can be seen exchanging words.
3. 2.5D isometric view of the bar itself; the player can move around and choose which character to talk to. Similarly, suspects can be sitting together sometimes.
</aside>

At this stage, the Player is expected to interact with the available characters (they all have a few lines of dialogue), and choose with one they would like to interrogate further today.

### 2. CHARACTER SELECTION

When selecting a character, the UI shows:

- Character name and portrait
- Chapter list
- Chapter status for each (Complete, Incomplete, Locked, NEW)

The Player can then choose which chapter to engage with.

- The Player can choose to replay a past chapter to find more secrets.
- The Player can start the newest chapter if they completed the previous one.

### 3. PRE-INTERROGATION SEGMENT

The dialogue starts.

**Purpose**: Non-interactive prologue that sets up the interrogation topic and hints at optimal cocktail choice.

- Casual Conversation occurs between bartender and suspect.
- Dialogue naturally leads to the chapter's main topic.
- Contains subtle hints about:
    - Whether the character will lie frequently (→ Truth Serum)
    - Whether the conversation will involve memories/past (→ Nostalgia Blend)
    - etc...

At the end of this section of the dialogue, the bartender will proceed and make a cocktail, before entering the Interrogation section.

### 4. COCKTAIL MIXING

TODO

### 5. INTERROGATION SEGMENT - FIRST READ

**Format**: Non-interactive presentation of the suspect's testimony.

**Flow**:

1. Suspect tells their story (5-15 statements)
2. Statements appear one at a time.
3. Player reads but cannot interact yet.
4. After final statement, the Bartender's internal thoughts appear. They typically hint at suspicious words/topics.
5. Transition to Interactive Phase

### 6. INTERROGATION SEGMENT - INTERACTIVE PHASE

**Core Mechanic**: Player clicks on words in the dialogue to investigate secrets.

SUSPICION METER (Investigation Points)

- Represents how much the bartender can probe before the suspect becomes suspicious of the bartender's motives, and interrupts the conversation.
- Starts empty. Every time the player investigates a word, the meter increases by 1 (whether or not it's a secret)
- Base: 5 empty slots (+1 if cocktail matches taste preference)

SECRETS

Each segment contains the following:

- **2 ~ 5 Key Secrets**: Required to complete the chapter.
- **Side Secrets**: Optional lore (not required for completion)

WORD CLICKING MECHANIC

When Player clicks on a word:

- Word Contains a Secret
    - *Suspicion raises by 1*
    - New dialogue branch opens
    - Additional statements may be added to the character's story
    - Secret logged in player notebook
    - Word becomes marked
- Word Contains nothing:
    - Suspicion raises 1
    - Generic response
    - No new information gained

### 7. INTERROGATION END CONDITIONS

SUCCESS

Triggers when all key secrets are found.

- Protagonist automatically interrupts the Interrogation sequence.
- Protagonist and character exchanges a few more words before the chapter ends.
- Summary of the interrogation: Display the list of secrets (found & unfound, the latter ones being greyed out)
- Chapter marked as Complete.

FAILURE

Triggers when suspicion meter is full.

- Suspect becomes uncomfortable and interrupts the conversation ("*I should get going... Maybe we can talk another time.*")
- Conversation ends naturally.
- Summary of the interrogation: Display the list of secrets (found & unfound, the latter ones being greyed out)
- Chapter remains Incomplete.
- Player must retry this chapter on a future before they can unlock the next one. They will be able to choose another cocktail. Secrets they've already discovered will be marked automatically.

### 8. DAY END & PROGRESSION

After Interrogation (Success or Failure)

- Depending on the day, there could be a story event (ex: section involving Vesper, the Captain, or Elysia)
- Protagonist goes to bed
- Day counter advances by 1
- Game auto-saves
- If a passenger is leaving the ship without having all his chapters completed, the game will offer the possibility to rewind time (more info below)

---

### TIME MANAGEMENT SYSTEM

### 50-DAY STRUCTURE

The player has a limited number of days to unlock every chapter of every character.

Story events are conditioned by having cleared some characters' chapters, so it's impossible to make the main story progress without completing chapters.

The goal is to complete all chapters in the allocated number of days and reach the true end.

A normal playthrough will allow for 4~5 failures.

### CHARACTER AVAILABILITY

Each character has:

- A schedule: which days they appear in the bar.
- An Arrival date: Day from which they become available.
- A Departure date: Day when they leave the airship permanently.

### WARNINGS & NOTIFICATIONS

**Departure Warning:**

- Appears when character leaves is ≤5 days
- UI: ⚠️ icon on character portrait
- Notification: *"Reiko leaves the ship in 3 days!"*

**Insufficient Time Warning:**

- Appears when mathematically, it is impossible to complete a chracter's story.
- Exemple: 2 days left, 3 incomplete chapters, character only available 1 more day.
- UI: Red ⚠️ icon
- It's there to incite the player to rewind time now rather than when the character actually leaves.

---

### REWIND SYSTEM

### TRIGGER CONDITION

When a Character departs with Incomplete Chapters.

Notification window appears:

```
╔══════════════════════════════════════╗
║  Reiko is departing!                 ║
║                                      ║
║  Chapters completed: 3/5             ║
║  Key secrets found: 12/20            ║
║                                      ║
║  You have not learned their full     ║
║  story. Without this information,    ║
║  you cannot understand what truly    ║
║  happened.                           ║
║                                      ║
║  ┌────────────────────────────────┐  ║
║  │  [REWIND TIME]                 │  ║
║  │  Return to an earlier day and  │  ║
║  │  try again.                    │  ║
║  └────────────────────────────────┘  ║
╚══════════════════════════════════════╝
```

### REWIND UI

Day Selection Slider:

- Display calendar view
- Highlights days when character was available
- Shows minimum rewind days (calculated automatically)
- Player can choose any day from Day 1 to Day X (X being the latest possible day that still allows the player to finish the character's story)

**Information Display:**

- "Rewinding to Day X will give you Y opportunities to speak with this character"
- Shows character's remaining available days

### WHAT IS PRESERVED ON REWIND

Nothing. It's like reloading a save from day X.

We could consider keeping all the discovered secrets and the discovered recipes, so the player does not have to redo content the exact same way... But I am not sure if that makes sense narratively.

### NARRATIVE FRAMING

- The Captain tells the Protagonist that they can use the airship (time capsule) to rewind time, so to speak. Every suspect will have their memories reset to whatever they were a few days prior.
- Obviously, since it's not a real time travel, it only works if you're not a real human. Only on copies of consciousnesses of real people, because it's all data. The Captain, the Protagonist and Lyra will keep their memories. Vesper and Elysia too (because they are not data)
- If the Protagonist meets Vesper or Elysia on Day X + i during a story event, . Because it's not a real time travel.
    
    that story event won't be repeated after rewinding back to Day X
    

---

### NOTEBOOK / INVESTIGATION SYSTEM

### PLAYER NOTEBOOK (UI Element)

Accessible at any time.

Contents:

- Main Page
    - Calendar
    - Overall completion percentage
    - Days remaining
    - Character at risk (leaving soon)
- Characters page
    - Character Profile
    - Characters' chapters, along with the secrets already discovered
- Cocktails page
    - List of unlocked recipes
    - List of available ingredients
- Story Notes (optional)

---

## WIN/LOSE CONDITIONS

### WIN CONDITION

Complete all chapters before the last day (i.e. discover every key secret).

The player will have the opportunity to use the remaining days to unlock more optional secrets, should they choose to do so.

At any moment, they can choose to see the ending (automatically happens on the last day, if all key secrets have been discovered).

### LOSE CONDITION

An incomplete character departs.

Lead to a forced rewind.

---

## Summary of Core Loop

- **Day Start:** Player sees who's available, chooses character and chapter
- **Pre-Interrogation:** Read casual conversation (hints at optimal cocktail)
- **Cocktail Mixing:** Choose cocktail (highlights secret types + taste bonus)
- **First Read:** Watch testimony non-interactively, receive hints
- **Interactive Phase:** Click words (costs Investigation Points), find secrets
- **Success:** Find all key secrets → Chapter complete → Day advances
- **Failure:** Suspicion meter full → Chapter incomplete → Day advances (retry later)
- **Departure:** Character leaves incomplete → Mandatory rewind to earlier day
- **Repeat:** Until all characters complete (5/5 chapters each) by Day 50
- **Endgame:** Full context gathered → Final sequence → True ending

## Gameplay Possibilities

**Interrogation**

- Latent secret: Some secrets in earlier statements could only "activate" after other secrets have been probed. Before that, they are normal words.
    - When that happens, the player should be noticed that words he already investigated are worth checking again.
- Nested secrets: Some secrets can be nested in sentences added to the story *after* discovering another secret. To go even further, a secret could be nested inside 2 others.
- Some "heavy" secrets can dramatically raise the suspicion meter (by more than 1), should the player choose to probe into them.
- In some tense situations, perhaps the suspicion meter can raise by 2 instead of 1 as base value.
- A Character could intentionally lie, in order to drop multiple side secrets and sidetrack the player by making them deplete their investigation points on non-key secrets. Creates strategic depth: "Is this lie important, or a distraction?"
- A Character could intentionally choose to speak a lot and create a lot of statements with no secrets inside.
- Some secrets could only be accessible if the player discovered a specific secret from another character prior (shared experience).
- Special interrogation sequence (a stressful one) where the suspicion meter raises in realtime. The player can investigate any secret, but he still has to find all the key secrets before the time is up. If he clicks on every side secret, the extra dialogue will make them lose precious time.

**Time Management**

- Change the number of allocated days to balance difficulty (hardest difficulty won't allow any chapter to be failed)

## Uncertainties

- The game can feel repetitive after a while, since the player does (roughly) the same thing each day.
    - Story beats can help alleviate that. Story events can happen on fixed days, and also after some milestone have been achieved (ex: X chapters completed).
    - AA alternates between investigation sections and court sections to help with pacing. Our game doesn't have that (since we are trying to keep the scope small), but we can consider introducing other small gameplay mechanics in the mix.
        - Special interrogation section involving 2 characters at the same time.
        - Special interrogation section where the Protagonist confronts the Captain, instead of a suspect. Since there's no drink involved, the secret finding could work slightly differently.