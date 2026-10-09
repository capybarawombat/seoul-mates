# Test report

Date: 2026-10-10. Godot 4.7.2 stable, Firefox 157.0.1, geckodriver 0.37.0 on Linux.

## Passed

- `godot --headless --path . --editor --quit`: project imported and scripts parsed. The workspace sandbox blocked Godot's editor listener socket and printed unrelated `ERR_CANT_CREATE` messages; process exited 0 and gameplay scripts parsed.
- `godot --headless --path . --quit-after 2`: scene launched with exit 0.
- `godot --headless --path . --script tests/test_state.gd`: `STATE TESTS PASSED`, including both recipes, three orders, customer entry/seating/departure stages, duplicate serving prevention, inventory conservation, save/load and day transition.
- `godot --headless --path . --export-debug Web build/web/index.html`: exit 0, generated HTML/JS/WASM/PCK files; HTML reports `GODOT_THREADS_ENABLED = false`.
- `python3 tools/browser_smoke.py` through Firefox WebDriver: page title and live canvas returned; screenshot `/tmp/seoul-webdriver.png` was inspected and showed the game menu and restaurant.
- `python3 tools/browser_coop_smoke.py` through two Firefox/WebDriver processes: both exported browser clients connected to the local Godot server; screenshots `/tmp/seoul-browser-client-1.png` and `-2.png` showed the same balance/order/inventory and both player avatars. Server logged two joins and two leaves.
- `tests/network_client.gd` in two separate Godot processes against a live local dedicated server: A added rice cakes and sauce, B chopped and added fish cake, both saw service and balance 46. A tried serving again; balance and served count remained unchanged. A third client joined after both cooks exited and saw served count 1 and balance 46. The server restarted with the same isolated save; a fourth client saw balance 46 and rice cake inventory 2. One earlier run exposed a server-only cooking-panel draw error, which was fixed and rerun successfully.
- The two-client recipe scenario was rerun after adding the moving customer. Both clients again saw one payment of 46; the server reported no script errors.

## In progress or not verified

- Full cooking actions inside two browser windows were not automated. The actual co-op recipe was verified with two headless Godot clients; browser clients were verified for connection, replication and rendering.
- No tests ran on a phone, deployed host, HTTPS/WSS environment or external network.

## Browser and test limitations

Firefox CLI screenshots captured only Godot's loading splash because they returned before WASM initialization. WebDriver waited for the canvas and produced inspectable game screenshots. Browser layout at the tested 1366×682 canvas is usable; smaller screens and touch input remain unverified.
