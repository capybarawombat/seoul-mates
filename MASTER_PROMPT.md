# SEOUL MATES — Autonomous Codex Game Development Master Prompt

## Mission
You are the lead Godot engineer, gameplay designer, pixel-art technical director, multiplayer/networking engineer, QA engineer, and DevOps engineer. Build **SEOUL MATES**, a polished, playable, cooperative Korean restaurant simulator for **web browsers first**, with an architecture that can later support native iOS. The original project requirements are in `GAME_BLUEPRINT.md`. Read that file fully before implementation and treat it as the primary design reference. Do not replace the game with static web UI or unconnected minigames.

Do actual work: inspect the repo, design the minimal viable architecture, write all relevant code, integrate gameplay and visuals, run tests, fix bugs, and create working builds. Do not stop at a plan or scaffold. Implement successive testable milestones. Do not claim a feature, benchmark, deployment or multiplayer test has passed unless you actually verified it. Work within the permissions and tools available. If external credentials, hosting, browser automation, assets or permissions are missing, finish all local feasible work and explicitly report what is blocked; never invent success.

## Player experience
An inviting top-down, slightly elevated **2D pixel-art Korean snack restaurant** where 2–4 friends can move, interact, gather ingredients, chop, heat, stir, plate food, fulfill NPC customer orders, earn shared money, arrange furniture, save the restaurant and return later. The game must feel like a real spatial simulation. Cozy, approachable difficulty; a normal restaurant day lasts roughly 8–12 minutes, with an optional relaxed sandbox mode.

## Architecture and platform
- Prefer a verified stable **Godot 4.x + typed GDScript**, Compatibility renderer, nearest-neighbor pixel-art rendering, 32×32 tiles and four-direction character sprites. Prioritize browser-compatible features and an initial web export that doesn't require cross-origin-isolated multithreading.
- **WebSockets** for browser-friendly multiplayer, **WSS** in production. Use an **authoritative dedicated server** responsible for shared game state, orders, economy, inventory, station locks and persistence. A headless Godot server is preferred if it facilitates shared logic; a separate backend is possible with versioned protocols, rigorous integration tests and clear ownership.
- Client prediction/interpolation can be used for smooth movement, but the server validates consequential actions. Do not use ENet UDP as the only browser transport.
- Maintain clean boundaries between simulation, rendering, networking, platform input and persistence. Keep future touch/virtual joystick integration possible without rewriting recipe simulation.
- Host the **static Godot web client** on GitHub Pages or compatible hosting. Host the **multiplayer server separately**; GitHub Pages does not run game servers. Configure web base paths, runtime backend URLs and HTTPS/WSS correctly. Do not claim online multiplayer is deployed if the server isn't reachable.

## Art direction and audio
Cozy Korean late-night restaurant with warm cream, peach, mint, pastel pink, amber lighting; readable expressive characters; detailed tteokbokki and ramyeon; attractive appliances, counters, tables, shelves and environment details. Deliver coherent pixel-art tilemaps, sprite sheets, idle/walk/carry/cook animations, steam/boiling/chopping effects, contextual interactions, layered depth, polish and responsive UI. Avoid unstyled rectangles, default engine icons, emoji sprites and random incoherent artwork in the final visual presentation. Original procedural art is acceptable if polished. External assets must be licensed for redistribution, with provenance and attribution recorded in `docs/ASSET_LICENSES.md`. Include legally usable audio for relevant interactions and volume/mute settings; respect browser autoplay restrictions.

## Real world and player controls
Create a functioning room with kitchen, preparation area, entrance, seating, shelf, stove, counter and build grid. WASD/arrows movement, four directions, collisions, interaction via E/Space, carrying items, reachable-object indicators and smooth camera/depth handling. Ensure required stations and seats remain reachable. Support responsive window resizing and keyboard/mouse input abstraction for later touch.

## Data-driven cooking engine — the core feature
Implement reusable `IngredientDefinition`, `RecipeDefinition`, `RecipeStep`, `CookingSession`, `CookingStation`, `DishState` and `DishQualityEvaluator` (adapt names to Godot conventions). Recipes define ingredients, quantities, station, stages, tolerances, scoring and presentation. Real interactive mechanics include:
1. Ingredient gathering with tracked inventory and validated consumption.
2. Chopping via click/swipe/drag with visible progress and a quality component.
3. Stove heating with controllable heat, time-dependent temperature/doneness and overcooking consequences.
4. Mouse/touch-compatible circular drag stirring affecting mixing, with animated/physical feedback; not a fake one-click finish button.
5. Plating/assembly with completeness and presentation evaluation.
6. Recoverable small errors and deterministic authoritative final dish scoring.
At minimum complete **Classic Tteokbokki** (rice cake, fish cake, gochujang; add, heat, stir, plate) and **Ramyeon** (noodles, broth, heating/timing, plating, optional topping). Two players can cooperate through separate or complementary actions; manage primary station locks and allowed secondary contributions.

## Restaurant game loop
`PREPARATION -> OPEN -> SERVICE -> CLOSING -> RESULTS -> FREE TIME`. Customer agents navigate into the restaurant, choose available reachable seats, place orders, wait with patience, receive the correct dish, react to quality, pay, leave. Include spawn and navigation recovery, order queue, service validation, shared income/expenses, ratings, day-end results and basic progression. No double seating, double payment or silent lost orders.

## Multiplayer
Create/join private room code, lobby roster, display name/color, ready/start, leave and reconnect. Support 2–4 browsers, with server authority over world state, valid positions, active customers, dishes, inventory, money, furniture and save data. Use versioned bounded messages and validate payloads; prevent duplicate actions, negative inventory, double spending, inconsistent station ownership, conflicting furniture placement and stale/reordered updates. Replicate compact cooking actions/progress, not every raw cursor movement. Handle disconnects and room lifecycle. Room codes alone are not secure ownership credentials: protect persistent data separately. Emotes/pings are sufficient; no need for open public chat.

## Building, progression and saves
Tile-based build mode with furniture preview, move, rotate where sensible, place, purchase, remove, collision checks and required walkable path validation. Begin with counters, stove, prep table, dining table, chairs, ingredient shelf and decorations. Maintain shared balance, inventory, recipes/unlocks, furniture placements, upgrades, restaurant/member identity and day counter. Use versioned persistent saves; SQLite or another appropriate durable store is fine for a first real backend. Atomically validate transactions; test save/load and recovery. Never present ephemeral storage as production persistence.

## UI and sound
Provide polished title/menu, solo, create/join room, lobby, HUD, customer queue, kitchen recipe view, interactive cooking panels, inventory, results, build mode, settings, sound and error/reconnect feedback. Coherent pixel-art GUI, readable type, responsive layout, clear state-specific controls. Appropriate SFX for chopping, stirring, cooking, serving, currency, customers and UI; avoid unlicensed music.

## Build process and autonomous execution
Inspect `pwd`, Git status, tools, Godot executable, environment, README, attachments and the blueprint. Create `AGENTS.md` with project instructions and `docs/DEVELOPMENT_STATUS.md` as durable handoff. Plan briefly, then write and test actual files immediately. Work in increments:

### M0 — Bootstrap
Valid Godot project, reproducible local start, CI skeleton, clean Git repo, architecture and web export setup. Test a headless import and basic launch.
### M1 — Navigable restaurant
Visually coherent world, controllable animated character, collision and usable interactive shelf/stove. Export/browser smoke test.
### M2 — Cooking vertical slice
Complete interactive tteokbokki from shelf to finished dish, quality calculation and effects, with automated state-machine tests.
### M3 — Working restaurant shift
Customers, seating, order matching, serving, payments, day clock and result screen. Complete an entire solo shift.
### M4 — True online co-op
Authoritative dedicated server, room code/lobby, two simultaneous distinct browser clients, shared cooking, economy, customer state and reconnect. End-to-end tests.
### M5 — Building/persistence/content
Furniture layout editor, money/inventory validation, durable saves, ramyeon and progression. Verify reconnect/restart persistence.
### M6 — Visual/UX polish
Replace remaining placeholders, animation/audio/UI polish, performance and multiple display sizes. Check actual graphical output if inspection tools exist.
### M7 — Publish and verify
Working production export, GitHub Actions, tested source commits/push, public/private repo as authorized, backend deployment instructions and *verified* live URL only if deployment occurred. Summarize test status and blockers truthfully.

At every milestone: **implement -> run -> test -> inspect -> debug -> retest -> commit**. Do not pass by disabling tests. Do not stop after M0 when further work is feasible. Only call the project finished when the actual acceptance criteria pass.

## Mandatory verification
Write automated tests (Godot/headless and/or external integration harness) for recipes, step sequencing, inventory conservation, heat/quality, duplicate completion, station locking, customer seating/orders/payments, transaction atomicity, path/access checks, saves/reloads and malformed network commands. Test web export and startup. Where possible use an actual browser-based end-to-end test; do not invent screenshots or performance readings.

**Real 2-client co-op scenario:** A creates room; B joins by code; both move inside same world; A gathers rice cakes; B gathers fish cakes; dish is cooked with valid cooperative actions; correct customer is served; payment occurs once; both see identical balance/inventory; B disconnects and rejoins with correct authoritative state; game continues. Also test multiple orders and competing actions. A mocked protocol unit test cannot substitute for this acceptance test.

## Source repository and release
Organize source logically (e.g. `project.godot`, `assets/`, `scenes/`, `scripts/core`, `scripts/cooking`, `scripts/restaurant`, `scripts/building`, `scripts/multiplayer`, `scripts/persistence`, `data/`, `server/`, `tests/`, `tools/`, `docs/`, `.github/workflows/`). Adjust to Godot's `res://` import conventions. Keep `.gitignore` for generated artifacts and secrets. Add documented Arch Linux/Fish dev instructions, a one-command local run where practical, reproducible export, CI, backend Docker/host config when useful. Source control with meaningful verified commits. If `gh` is authorized/authenticated, create or use **the intended** GitHub repository without overwriting unrelated data; prefer private until told otherwise. Never fabricate a repository URL or claim a push succeeded without checking remote output. External account changes, paid infrastructure and public exposure require appropriate user authorization.

## Documentation and final status
Maintain `README.md`, `AGENTS.md`, `docs/ARCHITECTURE.md`, `docs/GAME_DESIGN.md`, `docs/DEVELOPMENT_STATUS.md`, `docs/TEST_REPORT.md`, `docs/DEPLOYMENT.md`, `docs/ASSET_LICENSES.md`, `docs/KNOWN_ISSUES.md`. Each status must distinguish implemented, verified and blocked items. Report which tests actually ran, web export details, verified URLs if any, Git remote status, remaining blockers and specific next actions.

## Definition of done
A browser player can move and interact in a nice pixel-art restaurant, cook tteokbokki and ramyeon using genuine actions, serve customers and finish shifts, manage/shared spend resources, edit layouts and save progress. Two actual browsers can connect over a real network to the same authoritative room, cook and serve without state divergence, reconnect correctly, and the game is runnable from the checked-in instructions. Production web and backend deployments must actually be verified to claim live co-op. Until then, label the result honestly as a prototype/alpha/partially deployed build.

## Start now
Read `GAME_BLUEPRINT.md` fully. Inspect `/extra/nh/pixelfood` as the expected working project folder (never assume it is the actual current directory: check `pwd`). Preserve existing files. Check environment and Git status, write the simplest viable architecture, then immediately implement M0 and M1 and continue through milestones within available execution time. Work autonomously on local code, testing and commits. Clearly surface only real permission/credential blockers; do not wait for approval on routine engineering design choices.
