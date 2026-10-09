# Test report

Date: 2026-10-10. Godot 4.7.2 stable, Firefox 157.0.1, geckodriver 0.37.0 on Linux.

## Passed

- Headless Godot scene startup exited 0; `tests/test_state.gd` reported `STATE TESTS PASSED`. It covers both recipes, a three-order shift, customer entry/seating/departure, inventory consumption, duplicate-payment prevention, save/load and next-day transition.
- A Godot Web debug export completed with `GODOT_THREADS_ENABLED = false`.
- `python3 tools/browser_full_coop.py` drove two separate Firefox/WebDriver processes against one live Godot server. Both loaded the canvas, joined the same room and moved independently. A consumed one shared rice cake; B chopped and contributed fish cake. A added sauce, set heat and stirred by mouse. The clients received matching cooking and inventory state, and A plated and served the dish.
- In that two-browser run, both clients saw exactly one payment (money 46), one completed order and matching inventory (`rice_cake: 2`, `fish_cake: 2`, `gochujang: 2`, other initial items: 3). Repeated service left money and served count unchanged. B reloaded and rejoined; the backend restarted; both browsers saw the saved money and inventory afterward.
- A production `--export-release Web` using `tools/export_web.py --wss-url wss://game.example.invalid/socket` generated nonempty HTML, JavaScript, WASM and PCK files, retained single-threaded mode and injected the WSS URL. `python3 tools/release_smoke.py` loaded the release in Firefox, found the live canvas and title, and confirmed the debug state readout was absent. The placeholder WSS host is deliberately not live.
- Browser screenshots under ignored `build/verification/` were inspected. They show coherent pixel scaling, player colors/facing, customer, food and cooking panel without the previous overlapping pot text. The tested desktop canvas is 1366×682.
- `server/compose.yaml` parsed with `yq`. The configured Caddy route terminates TLS and proxies WebSocket traffic to the game server, but this route was not executed.

## Not verified / blocked

- No deployed browser client, public HTTPS/WSS session, phone or external-network test. GitHub CLI reports an invalid token, so the Pages workflow and repository publication were not run.
- Docker Compose plugin is missing and Docker daemon access is denied. The Docker image, persisted container volume, Caddy certificate issuance and production WSS connection have not been tested.
- Browser automation covers one collaborative tteokbokki order, not ten consecutive orders or the ramyeon recipe in two browsers. The latter is covered by headless state tests.
- Sound generation is exercised by browser input without script errors; audible output and touch controls were not perceptually verified.

## Test method and limits

The browser harness uses keyboard and pointer WebDriver actions for gameplay and a read-only debug export state readout for assertions. The release export does not include that readout. Position and continuous cooking values can differ briefly between snapshot frames; the test compares exact discrete state and allows a small timing tolerance for continuous values. Local test saves and screenshots are under ignored paths. Godot's editor listener reports `ERR_CANT_CREATE` inside the restricted sandbox during export, but export exits 0 and Firefox loads the resulting game.
