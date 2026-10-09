# SEOUL MATES

A playable Godot 4.7.2 web prototype of a Korean snack restaurant. Walk through the kitchen, prepare tteokbokki or ramyeon, control the stove, stir, plate, and serve three customer orders in a shift. A separate headless Godot process can host a shared local WebSocket room.

## Requirements

- Godot 4.7.2 standard edition (GDScript)
- Godot 4.7.2 export templates for web export
- Python 3 to serve the generated web files locally

The Godot download is at the [official Linux page](https://godotengine.org/download/linux/). Use the Compatibility renderer configured in `project.godot`.

## Play solo

```bash
godot --path .
```

Press Enter to enter the kitchen, then Enter again to open a shift. Use WASD or arrow keys to walk. Select an ingredient with 1–6 and press E at the shelf to carry it. Press E at the stove to open a cooking session and add what you carry. Chop fish cake or scallion at the prep board by dragging across it or pressing E repeatedly. Open the stove panel and drag the heat slider; drag circles inside the pot to stir. Press Escape to leave the panel. Press E three times at the plating counter, then E at the occupied table to serve. F5 saves day, money and inventory. M toggles the pending sound setting; audio is not implemented yet.

## Local co-op

Run the authoritative server in one terminal:

```bash
godot --headless --path . -- --server
```

Open the game in two other processes or browser tabs. Press Enter, then N in each. Both join the current development room `SEOUL` at `ws://127.0.0.1:9090`. The server owns inventory, recipe state, orders, payment, player positions, and the stove control lock. Local clients send actions and receive state snapshots.

The room code and localhost address are development defaults. There is no public lobby, membership security, or hosted server yet. The server persists day, money and inventory in Godot's `user://restaurant_v1.json`; browser local saves are separate.

## Export for a browser

```bash
mkdir -p build/web
godot --headless --path . --export-debug Web build/web/index.html
python3 -m http.server 8765 --directory build/web
```

Open `http://127.0.0.1:8765`. For a hosted HTTPS page, set `window.SEOUL_MATES_SERVER_URL` to a reachable `wss://` endpoint in the export's HTML shell. The HTML is generated, so keep deployment configuration outside source or in a custom shell for a release. The export preset has threading disabled; it does not require cross-origin isolation.

## Tests

```bash
godot --headless --path . --script tests/test_state.gd
godot --headless --path . --quit-after 2
```

`tests/network_client.gd` is the scripted two-process local co-op scenario. Its exact run and limits are in [docs/TEST_REPORT.md](docs/TEST_REPORT.md). Browser smoke helpers use Firefox, geckodriver and a local HTTP server.

Current scope and known limits are in [docs/DEVELOPMENT_STATUS.md](docs/DEVELOPMENT_STATUS.md).
