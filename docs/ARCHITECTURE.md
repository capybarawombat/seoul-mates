# Architecture

`scripts/restaurant_state.gd` is a deterministic, UI-independent restaurant simulation. It loads recipe definitions from `data/recipes.json`, tracks ingredient inventory, per-player carried items, one active cooking session, dish quality, orders, money and day state. Its snapshot format is versioned for network replication. A separate versioned save stores day, money and inventory.

`scripts/main.gd` renders the restaurant with Godot draw commands, handles keyboard and mouse input, validates local geometry, and manages the multiplayer peer. In solo play it runs the simulation locally. With `-- --server`, the same Godot scene becomes a dedicated WebSocket authority on port 9090. Browser and desktop clients send station actions and position updates. The server validates proximity, movement, inventory and the stove control owner before changing shared state, then sends snapshots.

The first room is fixed as `SEOUL`. The protocol uses Godot high-level multiplayer RPCs over WebSocket and requires matching exported client/server builds. It is an alpha protocol, not a stable or secure public-room service. `ws://` works on local HTTP; HTTPS hosting needs a WSS reverse proxy.

The current world uses procedural draw commands instead of texture assets. This keeps the prototype editable and lightweight, but needs sprite sheets, sound, responsive touch controls and visual polishing before release.
