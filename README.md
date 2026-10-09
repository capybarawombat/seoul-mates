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

Press Enter to enter the kitchen, then Enter again to open a shift. Use WASD or arrow keys to walk. Select an ingredient with 1–6 and press E at the shelf to carry it. Press E at the stove to open a cooking session and add what you carry. Chop fish cake or scallion at the prep board by dragging across it or pressing E repeatedly. Open the stove panel and drag the heat slider; drag circles inside the pot to stir. Press Escape to leave the panel. Press E three times at the plating counter, then E at the occupied table to serve. F5 saves day, money and inventory.

Short original sound effects play after input. Press M to mute and `[` or `]` to adjust sound volume.

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

Open `http://127.0.0.1:8765`. For a production build, run `python3 tools/export_web.py --wss-url wss://your-domain/socket` with `SEOUL_GODOT` set if needed. The script checks the single-threaded release export and inserts the supplied endpoint into the generated HTML. A public game needs a separately hosted backend; see [deployment steps](docs/DEPLOYMENT.md). The export preset does not require cross-origin isolation.

## Tests

```bash
godot --headless --path . --script tests/test_state.gd
godot --headless --path . --quit-after 2
```

`tests/network_client.gd` is the scripted two-process local co-op scenario. Start a fresh test server with `SEOUL_MATES_SAVE_PATH=user://coop_test.json godot --headless --path . -- --server`, then run `godot --headless --path . --script tests/network_client.gd -- A` and `godot --headless --path . --script tests/network_client.gd -- B` in separate terminals. Run role C after both finish to check a new client joining the room. `SEOUL_MATES_SAVE_PATH` keeps integration test data separate from normal play. Browser smoke helpers use Firefox, geckodriver and a local HTTP server. Test results and limits are in [docs/TEST_REPORT.md](docs/TEST_REPORT.md).

`tools/browser_full_coop.py` starts a fresh local backend and drives two real Firefox contexts through movement, shared ingredient preparation, chopping, mouse heat/stirring, plating, service, duplicate-payment prevention, rejoin and backend restart. It needs Firefox, geckodriver and a Godot executable; set `SEOUL_GODOT` and `SEOUL_GECKO` if they are outside the documented local paths. It uses a debug Web export and writes screenshots and logs under `build/verification/`.

Current scope and known limits are in [docs/DEVELOPMENT_STATUS.md](docs/DEVELOPMENT_STATUS.md).
