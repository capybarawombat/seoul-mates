# SEOUL MATES — Development status

Status: **playable local multiplayer alpha with a verified two-browser cooking cycle**. A production Web export and deployment configuration exist; no public client or backend is live.

## Implemented

- Godot 4.7.2 project with Compatibility renderer and single-threaded Web export.
- Original procedural restaurant art, walkable room, collision, directional walking characters, customer movement, interaction prompts and keyboard/mouse controls. Added plants, stove steam, food details and depth sorting; player colors and facing now replicate consistently.
- Original procedural interaction audio with mute and volume controls.
- Data-driven tteokbokki and ramyeon recipes; shared inventory, ingredient carrying, chopping, heating, circular stirring, plating quality and completed dishes.
- A three-order shift with customer arrival, seating, service, departure, patience, matching dishes, one payment per order, shared money and next-day transition.
- Dedicated Godot WebSocket server on port 9090 with authoritative room state, numbered snapshots, station control lock and local JSON save of day, money and inventory. Rejoining clients synchronize their spawn position to the server.
- Production export script with explicit WSS endpoint, GitHub Pages workflow and separate Docker/Caddy backend configuration.

## Verified locally

- Headless scene startup and state tests, including both recipes, three orders, duplicate serving, save/load and next-day transition.
- Single-threaded Web debug and release exports. The release export loaded in Firefox and did not expose the debug-only state readout.
- Two independent Firefox WebDriver contexts connected to one live local WebSocket server and completed one shared tteokbokki: independent movement, shared ingredient quantities, fish-cake chopping, mouse heating and stirring, plating and service. Both saw money 46, one completed order and the same inventory. Repeated serving did not pay again.
- One browser reload/rejoin restored authoritative state. Both browsers reconnected after a backend restart and saw persisted money and inventory. See [TEST_REPORT.md](TEST_REPORT.md) for the exact assertions and limits.
- Actual browser screenshots of menu, cooking in both clients, service in both clients and release startup were inspected at the tested desktop size.

## Remaining work and blockers

- GitHub CLI authentication is invalid, so the private repository, push and Pages deployment are blocked. There is no public game URL.
- Docker Compose is unavailable and access to the local Docker daemon is denied, so the backend image and Caddy proxy remain untested. There is no live HTTPS/WSS backend or hosting environment.
- Room SEOUL has no authentication or persistent player identity. Rejoin restores shared room state and assigns a fresh player session; it is not secure for an open public server.
- Ten consecutive browser cooperative orders, small-screen layout, touch input, iPhone testing, external-network WSS, accessibility and performance profiling remain unverified.
- Dynamic rooms/join codes, full world progression persistence, customer seat choice/path recovery, build mode and final sprite art remain future work.
