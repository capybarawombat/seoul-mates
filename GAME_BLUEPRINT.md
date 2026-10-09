# 🍜 SEOUL MATES

Game Design Blueprint v0.1 · Cozy 2D Pixel Art · iOS Co-op

[My Big Sister: Remastered / eShop Download / Nintendo eShop](https://images.openai.com/static-rsc-4/TUrFOtfc0fQLOMcSf6VDcDJ0XH6NNQPCeIPUSVXiTQJVQLRDTJ_GUUFZSjtvTN6A83-RMRmzAomkjVzBK965QbEuL-lgmlbmIUDlyXvswNasDHU0qqwJg8fxpkw_iAsB1HCRtpYzFnFEUIA2WiZgIWPpGslc_Gu4-qv8JFyignU?purpose=inline)

[Midnight Ramen Shop on Steam](https://images.openai.com/static-rsc-4/1KtUwSlxzX6qtpqoy6O-Ff6W_IaNjJULfF4BhwlYfrk6a66uDAfYvSvW1sNslWQQXKRBOg1ae8Qz7YEyWThJbJQDhD2XT1CYGmhjCZImj02utlGdDRC41VVUG7vQkbEEm0aQnZxGE0nsdOEgGfeaYfz8LIHfmh0eWtKa95C-SAI?purpose=inline)

[Gunja Tteokbokki | Steambase](https://images.openai.com/static-rsc-4/zwiRJzYPEo4-QUuS88P1yKj7sJ3T2j345Ug-2xv6SIWY7TKdM6zNngTV57M9Mni6hVoWIcj7W8Tq0h59vBfdhWCerg1bbZH67zlLDtcP4pYILMwDVIVuDqpEsV-DMwSIZ6JzCyUS4RCNgUh__yzhGOvjMCeDShe2qpLg00kJ-nI?purpose=inline)

10

We're building a cooperative Korean restaurant simulator where cooking is the main attraction, decorating is the long-term reward, and playing together is the fun part.

I'd approach this as a real indie game project, not a collection of unrelated cooking minigames.

Genre

Cozy co-op restaurant sim

Platform

iOS first

Multiplayer

2–4 players online

Art direction

Top-down 2D pixel art

Core experience

Cook, build, serve, socialize

Engine recommendation

Godot 4 + GDScript

## 1. Game world and player experience

I propose a small but alive restaurant that players can freely walk around in, viewed from a slightly elevated top-down perspective.

The game has three natural modes, all within the same world.

[Midnight Ramen Shop Demo on Steam](https://images.openai.com/static-rsc-4/1KtUwSlxzX6qtpqoy6O-Ff6W_IaNjJULfF4BhwlYfrk6a66uDAfYvSvW1sNslWQQXKRBOg1ae8Qz7YEyWThJbJQDhD2XT1CYGmhjCZImj02utlGdDRC41VVUG7vQkbEEm0aQnZxGE0nsdOEgGfeaYfz8LIHfmh0eWtKa95C-SAI?purpose=inline)

Cooking mode

Interact with kitchen appliances, pick up ingredients, chop, stir, boil, fry and plate dishes using touch-based actions.

[Korea restaurant | Sims house design, Pixel art games, Pixel art background](https://images.openai.com/static-rsc-4/DxX6LRP5xyhC38D3kVSSHLuzqxNjisN0MI80mA1KpKuyTg6SD9E77hl3vdcpF7ZmBcAC2dz2Njms_G4zydKrplledMXuXRUAdyX2b4ZhhHjQgKc_VzKBVVXSyUBE0lUYYZd2rCEgWhdeT2tHnT3ZbBIVsXZn0kHuCwraesdyTWU?purpose=inline)

Restaurant mode

Seat customers, take orders, carry dishes, clean tables, purchase ingredients and organize the kitchen.

[The Sims meets Unpacking in this cozy Steam Next Fest demo that could easily have eaten up hours of my free time | GamesRadar+](https://images.openai.com/static-rsc-4/AlRq6e3YeG1aTIG_0TAho9uzK_3ZA1KaTiz4SreAYEVp-hoH2fGZG7Rebs8G68cBp29KWKD_7jncm4-FZNyMhF0DZpVRkRlM9TT6UyhoGKge7s1vSnYzST26IkWgleLNGuHWBvAIg7MPCgzWdhhrAhsc0nFefVYUM86lpLET-Vc?purpose=inline)

Build mode

Place equipment, rearrange the kitchen, change wallpaper and flooring, decorate tables and customize the restaurant's identity.

### An in-game day

1. Preparation: Players buy ingredients, organize stations, prepare sauces and choose a daily menu.
2. Restaurant opens: NPC customers arrive, sit down, and place orders.
3. Cooking and service: Friends cooperate on recipes while managing customer patience and kitchen capacity.
4. Closing: Everyone gets an earnings report showing profits, dish ratings and customer satisfaction.
5. Free time: Decorate, unlock recipes, experiment with food, and plan the next session.

One operating day should initially take around 8–12 minutes, with an option for a no-pressure sandbox mode.

## 2. Cooking architecture — the heart of the game

Instead of making completely separate systems for every Korean dish, I recommend a modular cooking engine.

That means we implement reusable interactions such as chopping, stirring, heating, boiling, rolling and plating. Different recipes combine these interactions in different ways.

Recipe engine

Recipe data

Ingredients · Steps · Tolerances · Quality rules

Chop

Boil

Stir

Fry

Roll

Plate

Dish evaluator

Doneness · Flavor balance · Presentation

Finished dish → Customer → Reward

### Five cooking mechanics worth building

| Mechanic     | Touch gesture               | Simulated result           |
| ------------ | --------------------------- | -------------------------- |
| Chopping     | Swipe across cutting guide  | Cut size and consistency   |
| Stirring     | Circular dragging           | Mixing and burn prevention |
| Heat control | Slider or stove dial        | Doneness and sauce texture |
| Rolling      | Swipe and hold              | Roll tightness and shape   |
| Plating      | Drag ingredients onto plate | Presentation quality       |

### Interactive design: cooking a pot of tteokbokki

The goal is to make cooking satisfying without requiring perfect reactions.

🍲 Tteokbokki station

Mini interaction concept

Cooking

Stove heat

55%

Low

Ideal \~65%

High

Ingredients

Rice cakeFish cakeGochujangCheese

Stirring

0 completed motions

&#x20;Stir

Reset

Plate & serve&#x20;

This is a simplified cooking interaction concept. In the actual game, temperature changes gradually and sauce thickness evolves over time. Stirring prevents burning, but excessive stirring is not automatically better.

### Hybrid cooking rules

My proposed system:

- No instant failure when a player makes a small mistake.
- An ideal cooking window rather than one perfect instant.
- Recipes may be prepared collaboratively.
- Players can recover slightly overcooked food using certain actions.
- Optional assisted cooking for casual players, with modest quality trade-offs.

That creates skill expression without turning a cozy game into a stressful dexterity contest.

## 3. Restaurant building and management

The restaurant should be fully editable on a tile-based grid.

Players purchase furniture and position it in the world. Kitchen layouts must affect gameplay, not just appearance.

Prototype floor planner

Tap a tile to place the selected object

CounterStoveTableChairErase

8×6 planning mockup. Real gameplay will add object collision, price checks, valid placement and walkable-path validation.

The key management systems would be inventory, pricing, customer satisfaction, staff progression and kitchen capacity. I would avoid complicated accounting in the first release.

## 4. Multiplayer system architecture

For a cooperative game, the biggest technical challenge isn't just getting two characters on the same screen. It's ensuring that every player sees the same restaurant, food preparation state, customers and inventory.

I recommend designing multiplayer from the beginning, even if the first prototype is single-player.

### Network architecture

Room service / lobby API

Create room · Join by code · Player identity

Authoritative game server

Validates actions · Simulates orders · Controls shared restaurant state

Player 1

iOS client

Player 2

iOS client

Player 3

iOS client

Persistent storage: layout, money, recipes, upgrades

The diagram represents our intended production architecture, not services that are already running.

### Who controls what?

| System                    | Authority                         | Synchronization                    |
| ------------------------- | --------------------------------- | ---------------------------------- |
| Player movement           | Server validates; client predicts | Frequent position updates          |
| Cooking interaction       | Server                            | Action events + progress snapshots |
| Ingredient inventory      | Server                            | On changes                         |
| Customer AI               | Server                            | State and movement updates         |
| Furniture placement       | Server                            | Placement events                   |
| Shared money              | Server                            | Transactions                       |
| Visual effects, particles | Local client                      | Usually not needed                 |

For Godot, `MultiplayerSpawner` and `MultiplayerSynchronizer` provide useful scene spawning and property replication primitives, while our own game logic handles recipe validation, ownership and persistence.&#x20;

[image](https://www.google.com/s2/favicons?domain=https://docs.godotengine.org\&sz=32)

Godot Engine (stable) documentation in English

+1



### A crucial design choice: cooking should not constantly send touch movements

For example, when stirring tteokbokki:

1. The player opens the pan and acquires a cooking-station interaction lock.
2. Their phone renders the liquid and finger interactions locally.
3. The client periodically sends a compact stirring-intensity value to the server.
4. The server advances mixing, temperature and doneness.
5. Other players see updated pan animation and progress.
6. The server confirms the final dish quality.

That is much more efficient than synchronizing every finger coordinate or every rendered particle.

Two players could contribute to the same recipe, but a single appliance should have clear rules about simultaneous use. A useful initial rule is one primary cook per station, with secondary players adding ingredients or helping with preparation.

### Hosting strategy

Prototype: Local host or dedicated server on your laptop. Test with multiple desktop clients before iOS.

Closed beta: Small cloud-hosted dedicated Godot server and room-code API, avoiding mobile NAT issues.

Release: Persistent restaurant storage, versioned saves, reconnect handling, backups and server monitoring.

A dedicated server is a better production default than making a friend's iPhone host, especially when the host locks the screen or loses signal.

## 5. Game code structure

I would use Godot 4.x stable with typed GDScript, component-like scenes, Resources for recipes and furniture definitions, and a clean separation between simulation and presentation.

Suggested project structure

seoul-mates/ ├── project.godot ├── assets/ │   ├── sprites/ │   ├── tilesets/ │   ├── animations/ │   ├── audio/ │   └── fonts/ ├── scenes/ │   ├── world/ │   ├── characters/ │   ├── kitchen/ │   ├── customers/ │   ├── furniture/ │   └── ui/ ├── scripts/ │   ├── core/ │   ├── cooking/ │   ├── restaurant/ │   ├── economy/ │   ├── building/ │   ├── multiplayer/ │   └── persistence/ ├── data/ │   ├── recipes/ │   ├── ingredients/ │   ├── appliances/ │   └── furniture/ └── tests/

The important domain objects:

| Object             | Responsibility                             |
| ------------------ | ------------------------------------------ |
| `RecipeDefinition` | Ingredient requirements, steps, thresholds |
| `CookingSession`   | Current cooking process and quality        |
| `CookingStation`   | Stove, chopping board, fryer, etc.         |
| `RestaurantState`  | Money, day, inventory, current orders      |
| `CustomerAgent`    | Seat, order, patience, eating, payment     |
| `BuildManager`     | Validate and apply tile/object placement   |
| `NetworkManager`   | Connections, commands, state replication   |
| `SaveManager`      | Versioned restaurant persistence           |

### A data-driven recipe example

The first tteokbokki recipe could be represented like this:

```

{
  "id": "tteokbokki_classic",
  "display_name": "Classic Tteokbokki",
  "station": "stove",
  "ingredients": [
    {"id": "rice_cake", "quantity": 1},
    {"id": "fish_cake", "quantity": 1},
    {"id": "gochujang_sauce", "quantity": 1}
  ],
  "steps": [
    {"action": "add_ingredients"},
    {"action": "heat", "ideal_range": [0.55, 0.75]},
    {"action": "stir", "target_mixing": 0.8},
    {"action": "plate"}
  ],
  "quality_metrics": [
    "doneness",
    "sauce_consistency",
    "ingredient_accuracy",
    "presentation"
  ]
}

```

This is a proposed configuration format, not a final Godot resource or scientifically calibrated cooking model.

The main benefit: adding a new recipe doesn't require rewriting the whole cooking engine.

## 6. Visual system and mobile interaction design

[Sunkissed City - Screenshots zum Quasi-Nachfolger von Stardew Valley](https://images.openai.com/static-rsc-4/W1s6uZ6FEc-mL-OsvU5BWO7SNv-nxGWEaauTTpfMM2MQSfxobNDR85RY69ijsF7kDjhAcdGos3X3GWu_1jq9z8GMtBy1Mi_wtNYEQrKwFq9Sa1qAJ0z2mZDlrqHHU78Ub2BVX0gAHrvfyZG4PdFx4YLZfGkqT3VckPKTq2EKyLM?purpose=inline)

[Redesigning Yatai Master’s aesthetic and quality system news - ModDB](https://images.openai.com/static-rsc-4/q7py6MwQAPaynIZchSgHdFoa0HeQ7LNaRNnpEbBBEJTuwg3aVHrFYHy6zvacd0F5K7YUG-8yNbACjJbGfN56dPp2DSRWEX574oUjqYlazzHGz_-sTrOFVqat0K8QhylRukAmSkAiPtOAdGwrEtcB56HYl-BWR6mM3fLm94dx0U8?purpose=inline)

[Cute Pixel Art Kitchen and Dining Room](https://images.openai.com/static-rsc-4/ekfRtTaZDEfRK1XK2LXOI9QwZJ04VIfu8kOCBcxaj_s-oGXBiY9ral8Fp30MrA3RJrFc0QtvA_2yR0wJneh_4MQglDY9zPpB-57m0O0VOVchjS62T-uwFB_PclGBx8wsD-cmceARACRjfK1c4orkM4slW3Dzn0OF4LEdL3W6DYw?purpose=inline)

14

### Art specification

| Attribute   | Proposed standard                                  |
| ----------- | -------------------------------------------------- |
| Camera      | Top-down, slightly elevated                        |
| World tiles | 16×16 or 32×32 pixels                              |
| Characters  | Roughly 24×32 to 32×48 px                          |
| Animations  | 4-direction walking, idle, carrying, cooking       |
| Palette     | Warm cream, peach, mint, pastel pink               |
| Rendering   | Pixel-perfect textures, nearest-neighbor filtering |
| Performance | Target 60 FPS; scalable for older phones           |

I'd choose 32×32 tiles because they give us enough visual detail for kitchen objects while keeping production manageable.

### iPhone controls

Landscape gameplay layout

Control placement wireframe, not a final pixel-art screenshot.

A virtual joystick controls movement. The right-side action button changes contextually between picking up an item, using a station, interacting with a customer, or placing furniture.

When entering a detailed cooking activity, the interface can enlarge that station to fill most of the screen. The player retains an exit button, order information, and a visual indication of what their character is doing in the restaurant.

Important: Cooking gestures should not conflict with movement gestures. Entering a cooking station changes the input context, so a chopping swipe doesn't accidentally move the character.

Godot supports touch events and drag input, making this interaction model practical.&#x20;

[image](https://www.google.com/s2/favicons?domain=https://docs.godotengine.org\&sz=32)

Godot Engine (stable) documentation in English



## 7. Development roadmap

Here's the order I would actually build it in. The time estimates assume one developer learning some game-development systems along the way, with occasional help from coding tools. They're planning estimates, not fixed deadlines.

Phase 1

Weeks 1–2

Movement and restaurant world

Godot project, pixel-art renderer, character animations, collisions, interactable objects, basic floor layout.

Walk around a restaurant and interact with a stove.

Phase 2

Weeks 3–5

Cooking vertical slice

Tteokbokki recipe engine, ingredient handling, heat simulation, stirring gestures, quality scoring, visual/audio feedback.

A complete, satisfying cooking experience.

Phase 3

Weeks 6–8

Restaurant operations

Customer orders, queueing, serving, payments, basic inventory, workday cycle, NPC navigation.

A playable single-player restaurant shift.

Phase 4

Weeks 9–12

Online co-op

Authoritative server, shared player/world state, cooking-station locking, synchronized orders, reconnects.

Two players complete one restaurant shift online.

Phase 5

Weeks 13–16

Building, saving and content

Furniture placement, persistent layout, restaurant upgrades, ramyeon recipe, progression.

A restaurant that friends can develop together.

Phase 6

Weeks 17–20+

iOS testing and polish

iOS export, device testing, touch UX, frame-time profiling, reconnect/recovery tests, bug fixes.

Private iPhone playtest build.

A credible first closed alpha is approximately 4–6 months of part-time work, potentially longer if you're creating all art, networking and backend infrastructure independently.

### Three development gates

Before expanding the project, I'd establish three objective milestones.

Cooking gate: A tester can prepare one dish without instructions and wants to repeat it. If not, refine cooking instead of adding recipes.

Co-op gate: Two players can jointly complete 10 consecutive orders without duplicated ingredients, desynchronized food or lost transactions.

Mobile gate: Cooking gestures remain reliable on a physical iPhone and gameplay is stable over an extended session, including interrupted connectivity.

## 8. Data persistence and online reliability

These features aren't visually exciting, but they are essential if friends are building a restaurant together over multiple days.

The save system should store restaurant ID and membership, furniture positions, recipes unlocked, shared currency, purchased appliances, ingredients and upgrades.

I would intentionally separate two categories of data:

- Persistent state: restaurant layout, unlocks, funds, upgrades and ownership.
- Temporary state: current cooking progress, player positions, customer animations, active kitchen effects.

The server periodically saves persistent state and records significant transactions immediately or in a recoverable log. Every purchase or furniture placement must be validated to prevent duplicate purchases and negative inventory.

If a player disconnects during cooking, the server should retain the station state briefly and let another player take over. If the whole server fails, the restaurant should reopen from its last consistent save rather than corrupting the restaurant.

For private rooms, we can initially avoid public text chat and use emotes, ping markers and preset messages. That reduces moderation scope and keeps the experience focused on playing together.

## 9. iOS deployment and your development machine

Your Arch Linux laptop is sufficient for building the Godot game, designing art, testing multiplayer locally and running a development server.

However, Godot's official iOS export workflow requires macOS with Xcode.&#x20;

[image](https://www.google.com/s2/favicons?domain=https://docs.godotengine.org\&sz=32)

Godot Engine (4.7) documentation in English



I would therefore organize development as follows:

| Environment        | Work                                             |
| ------------------ | ------------------------------------------------ |
| Arch Linux         | Main Godot development, art, testing             |
| Desktop builds     | Rapid local iteration and co-op debugging        |
| Linux cloud server | Online multiplayer backend                       |
| Mac + Xcode        | iOS exports, signing and device testing          |
| iPhone             | Touch interaction, performance and UX validation |

Use GDScript rather than C# for this project. Godot's iOS C# support is documented as experimental, and there's no compelling reason for us to introduce that additional constraint.&#x20;

[image](https://www.google.com/s2/favicons?domain=https://docs.godotengine.org\&sz=32)

Godot Engine (4.7) documentation in English



We should arrange access to a Mac early, preferably before the cooking system becomes large, rather than discovering touch or export problems at the end.

## 10. What I would deliberately exclude from version 0.1

To prevent feature creep, I would not implement open-world Seoul exploration, dozens of recipes, online matchmaking with strangers, voice chat, complex NPC hiring, pets, farming, food-delivery mechanics or procedural cities yet.

They can all fit a later version, but the first success is much narrower:

Two friends enter a cute Korean snack restaurant, cook tteokbokki together, serve customers, earn money, rearrange their kitchen and return the next day to find their restaurant saved.

That is already a complete gameplay experience.

## 11. The first thing we should build

[Gunja Tteokbokki | Steambase](https://images.openai.com/static-rsc-4/zwiRJzYPEo4-QUuS88P1yKj7sJ3T2j345Ug-2xv6SIWY7TKdM6zNngTV57M9Mni6hVoWIcj7W8Tq0h59vBfdhWCerg1bbZH67zlLDtcP4pYILMwDVIVuDqpEsV-DMwSIZ6JzCyUS4RCNgUh__yzhGOvjMCeDShe2qpLg00kJ-nI?purpose=inline)

## Prototype 001: Tteokbokki Kitchen

Godot · GDScript · Desktop-first with touch-compatible controls

Build one little kitchen with a movable character, ingredient shelf, stove, cooking interface and plating counter.

First implementation sequence

1. Create the Godot project and pixel-art settings.
2. Build the tiled kitchen and player controller.
3. Add interactive ingredient and cooking stations.
4. Implement the tteokbokki cooking state machine.
5. Add temperature, mixing, doneness and feedback.
6. Connect the completed dish to a customer order.

Start building Prototype 001&#x20;

One more design principle I'd keep throughout the project: the restaurant is shared, but each player should feel personally involved. Every dish should be something they made, not just a timer they started.

That is what can make SEOUL MATES feel different from traditional mobile restaurant-management games.