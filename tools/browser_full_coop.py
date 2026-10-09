"""Drive two real Firefox clients through one authoritative restaurant order.

Requires the local Godot binary, Web templates, Firefox, and geckodriver at
the paths used by the development workspace. Browser input uses WebDriver
keyboard/pointer actions; the Godot debug export exposes read-only state.
"""

import base64
import json
import math
import os
from pathlib import Path
import subprocess
import time
import urllib.error
import urllib.request


ROOT = Path(__file__).resolve().parents[1]
GODOT = Path(os.environ.get("SEOUL_GODOT", "/tmp/godot-bin/Godot_v4.7.2-stable_linux.x86_64"))
GECKO = Path(os.environ.get("SEOUL_GECKO", "/tmp/geckodriver"))
ARTIFACTS = ROOT / "build" / "verification"
ARTIFACTS.mkdir(parents=True, exist_ok=True)
SAVE_NAME = f"user://browser_full_{int(time.time())}.json"
PROCESSES = []
LOGS = []


def note(message):
    print(message, flush=True)


def spawn(name, command, env=None):
    log = open(ARTIFACTS / f"{name}.log", "w", encoding="utf-8")
    LOGS.append(log)
    process = subprocess.Popen(command, cwd=ROOT, env=env, stdout=log, stderr=subprocess.STDOUT)
    PROCESSES.append(process)
    return process


def game_env():
    env = os.environ.copy()
    env.update({
        "XDG_DATA_HOME": "/tmp/seoul-godot-data",
        "XDG_CONFIG_HOME": "/tmp/seoul-godot-config",
        "XDG_CACHE_HOME": "/tmp/seoul-godot-cache",
        "SEOUL_MATES_SAVE_PATH": SAVE_NAME,
    })
    return env


def start_server(name):
    server = spawn(name, [str(GODOT), "--headless", "--path", ".", "--", "--server"], game_env())
    time.sleep(1.0)
    if server.poll() is not None:
        raise RuntimeError(f"server exited: {server.returncode}")
    return server


class Browser:
    def __init__(self, port, label):
        self.port = port
        self.label = label
        self.session = None
        self.canvas = None

    def call(self, method, path, payload=None):
        request = urllib.request.Request(
            f"http://127.0.0.1:{self.port}{path}",
            data=None if payload is None else json.dumps(payload).encode(),
            method=method,
            headers={"Content-Type": "application/json"},
        )
        try:
            with urllib.request.urlopen(request, timeout=90) as response:
                return json.load(response)["value"]
        except urllib.error.HTTPError as error:
            raise RuntimeError(f"WebDriver {self.label}: {error.read().decode()}") from error

    def open(self):
        self.session = self.call("POST", "/session", {"capabilities": {"alwaysMatch": {
            "browserName": "firefox", "moz:firefoxOptions": {"args": ["-headless"]}
        }}})["sessionId"]
        self.navigate()

    def navigate(self):
        self.call("POST", f"/session/{self.session}/url", {"url": "http://127.0.0.1:8765"})
        self.canvas = self.call("POST", f"/session/{self.session}/element", {
            "using": "css selector", "value": "canvas"
        })["element-6066-11e4-a52e-4f735466cecf"]
        self.js("document.querySelector('canvas').focus(); return true")
        self.wait(lambda state: state is not None, "game debug state", 30)

    def js(self, script):
        return self.call("POST", f"/session/{self.session}/execute/sync", {"script": script, "args": []})

    def state(self):
        return self.js("return window.__SEOUL_TEST_STATE || null")

    def wait(self, predicate, description, timeout=20):
        end = time.monotonic() + timeout
        last = None
        while time.monotonic() < end:
            last = self.state()
            if predicate(last):
                return last
            time.sleep(0.15)
        raise AssertionError(f"{self.label}: timed out waiting for {description}; last state={last}")

    def press(self, key):
        self.call("POST", f"/session/{self.session}/element/{self.canvas}/value", {"text": key})

    def hold(self, key, seconds):
        self.call("POST", f"/session/{self.session}/actions", {"actions": [{
            "type": "key", "id": "walking", "actions": [
                {"type": "keyDown", "value": key},
                {"type": "pause", "duration": int(seconds * 1000)},
                {"type": "keyUp", "value": key},
            ]
        }]})

    def move_to(self, x, y):
        for axis, target in ((0, x), (1, y)):
            for _ in range(24):
                pos = self.state()["position"]
                error = target - pos[axis]
                if abs(error) <= 9:
                    break
                key = ("d" if error > 0 else "a") if axis == 0 else ("s" if error > 0 else "w")
                self.hold(key, min(0.32, max(0.07, abs(error) / 150.0)))
            else:
                raise AssertionError(f"{self.label} could not reach {(x, y)}; actual={self.state()['position']}")
        self.wait(lambda s: math.dist(s["peers"].get(str(s["peer_id"]), [9999, 9999]), [x, y]) < 30,
                  f"authoritative movement to {(x, y)}", 5)

    def path(self, points):
        for x, y in points:
            self.move_to(x, y)

    def point(self, x, y):
        rect = self.js("const r=document.querySelector('canvas').getBoundingClientRect(); return {x:r.x,y:r.y,w:r.width,h:r.height}")
        scale = min(rect["w"] / 960.0, rect["h"] / 640.0)
        return [round(rect["x"] + (rect["w"] - 960.0 * scale) / 2.0 + x * scale),
                round(rect["y"] + (rect["h"] - 640.0 * scale) / 2.0 + y * scale)]

    def pointer(self, steps):
        actions = []
        for kind, x, y in steps:
            if kind == "move":
                px, py = self.point(x, y)
                actions.append({"type": "pointerMove", "duration": 25, "origin": "viewport", "x": px, "y": py})
            elif kind == "down":
                actions.append({"type": "pointerDown", "button": 0})
            elif kind == "up":
                actions.append({"type": "pointerUp", "button": 0})
        self.call("POST", f"/session/{self.session}/actions", {"actions": [{
            "type": "pointer", "id": "cooking_mouse", "parameters": {"pointerType": "mouse"}, "actions": actions
        }]})

    def click_game(self, x, y):
        self.pointer([("move", x, y), ("down", 0, 0), ("up", 0, 0)])

    def stir_circles(self, circles=8):
        steps = [("move", 550, 333), ("down", 0, 0)]
        for index in range(1, circles * 20 + 1):
            angle = index * math.tau / 20.0
            steps.append(("move", 480 + 70 * math.cos(angle), 333 + 70 * math.sin(angle)))
        steps.append(("up", 0, 0))
        self.pointer(steps)

    def screenshot(self, name):
        png = self.call("GET", f"/session/{self.session}/screenshot")
        (ARTIFACTS / f"{name}.png").write_bytes(base64.b64decode(png))

    def close(self):
        if self.session is not None:
            self.call("DELETE", f"/session/{self.session}")
            self.session = None


def equal_shared(a, b):
    left, right = a.state(), b.state()
    for key in ("money", "inventory", "served", "order", "phase", "dish"):
        assert left[key] == right[key], f"{key} diverged: {left[key]} != {right[key]}"
    cooking_a, cooking_b = left["session"], right["session"]
    for key in ("added", "chopped", "heat", "mixing", "stir_count", "recipe", "plating"):
        assert cooking_a.get(key) == cooking_b.get(key), f"cooking {key} diverged"
    for key in ("temperature", "doneness", "burn"):
        assert abs(cooking_a.get(key, 0) - cooking_b.get(key, 0)) < 0.05, f"cooking {key} lagged too far"
    return left


def run():
    assert GODOT.exists() and GECKO.exists()
    server = start_server("browser_server")
    spawn("web_http", ["python3", "-m", "http.server", "8765", "--bind", "127.0.0.1", "--directory", "build/web"])
    spawn("gecko_4444", [str(GECKO), "--host", "127.0.0.1", "--port", "4444"])
    spawn("gecko_4445", [str(GECKO), "--host", "127.0.0.1", "--port", "4445"])
    time.sleep(1.0)
    a, b = Browser(4444, "A"), Browser(4445, "B")
    try:
        a.open()
        b.open()
        note("Both Firefox contexts loaded the Godot game")
        for browser in (a, b):
            browser.press("\ue007")
            browser.press("n")
            browser.wait(lambda s: s and s["online"], "WebSocket connection", 15)
        a.wait(lambda s: len(s["peers"]) >= 3, "both players visible", 10)
        b.wait(lambda s: len(s["peers"]) >= 3, "both players visible", 10)
        assert a.state()["peer_id"] != b.state()["peer_id"]
        note("Both distinct players joined one authoritative room")
        a.press("\ue007")
        a.wait(lambda s: s["phase"] == "OPEN", "shift open", 10)
        b.wait(lambda s: s["phase"] == "OPEN", "shared shift open", 10)

        a.path([(470, 300), (220, 300), (220, 235)])
        pos_a = a.state()["position"]
        b.path([(470, 300), (220, 300), (220, 235)])
        pos_a_after = a.state()["position"]
        assert math.dist(pos_a, pos_a_after) < 12, f"A moved while B was walking: {pos_a} -> {pos_a_after}"
        assert a.state()["peer_id"] in [int(x) for x in b.state()["peers"]]
        note("Both browser players moved independently to the shelf")
        a.press("1")
        a.press("e")
        a.wait(lambda s: s["carried"] == "rice_cake", "A carrying rice cake")
        b.press("2")
        b.press("e")
        b.wait(lambda s: s["carried"] == "fish_cake", "B carrying fish cake")

        a.path([(220, 300), (580, 300), (580, 235)])
        a.press("e")
        a.wait(lambda s: s["session"].get("added", {}).get("rice_cake") == 1, "rice cake added")
        b.wait(lambda s: s["inventory"]["rice_cake"] == 2, "rice cake inventory synchronized")
        note("A opened the recipe and consumed one shared rice cake")

        b.path([(220, 300), (410, 300), (410, 230)])
        for _ in range(4):
            b.press("e")
            time.sleep(0.2)
        a.wait(lambda s: s["session"].get("chopped") is True, "B's chopping replicated")
        b.path([(410, 300), (580, 300), (580, 235)])
        b.press("e")
        a.wait(lambda s: s["session"].get("added", {}).get("fish_cake") == 1, "B's fish cake added")
        equal_shared(a, b)
        note("B chopped fish cake and added it to A's recipe")

        a.path([(580, 300), (220, 300), (220, 235)])
        a.press("3")
        a.press("e")
        a.wait(lambda s: s["carried"] == "gochujang", "A carrying sauce")
        a.path([(220, 300), (580, 300), (580, 235)])
        a.press("e")
        a.wait(lambda s: s["session"].get("added", {}).get("gochujang") == 1, "sauce added")
        a.wait(lambda s: s["panel_open"], "cooking panel")
        a.click_game(570, 469)
        a.wait(lambda s: s["session"].get("heat", 0) >= 0.68, "heat changed")
        a.stir_circles()
        a.wait(lambda s: s["session"].get("mixing", 0) >= 0.65, "stirring changed mixing", 10)
        a.wait(lambda s: s["session"].get("doneness", 0) >= 0.72, "dish cooked", 35)
        equal_shared(a, b)
        note("Browser mouse heat and circular stirring changed shared cooking state")

        a.screenshot("cooking_a")
        b.screenshot("cooking_b")
        a.press("\ue00c")
        a.path([(580, 300), (755, 300), (755, 235)])
        for _ in range(3):
            a.press("e")
            time.sleep(0.25)
        a.wait(lambda s: s["dish"].get("recipe") == "tteokbokki", "dish plated")
        b.wait(lambda s: s["dish"].get("recipe") == "tteokbokki", "dish replicated")
        note("A plated the shared dish")

        a.path([(755, 300), (785, 300), (785, 440)])
        a.wait(lambda s: s["customer_stage"] == "seated", "customer seated")
        a.press("e")
        a.wait(lambda s: s["served"] == 1 and s["money"] > 30, "single service payment")
        b.wait(lambda s: s["served"] == 1 and s["money"] > 30, "payment replicated")
        paid = equal_shared(a, b)
        a.press("e")
        time.sleep(0.7)
        assert a.state()["money"] == paid["money"] and a.state()["served"] == 1
        note(f"Both browsers saw one payment: money={paid['money']}, inventory={paid['inventory']}")
        a.screenshot("served_a")
        b.screenshot("served_b")

        b.navigate()
        b.press("\ue007")
        b.press("n")
        b.wait(lambda s: s["online"] and s["served"] == 1, "rejoin authoritative state", 15)
        b.wait(lambda s: str(s["peer_id"]) in s["peers"] and math.dist(s["position"], s["peers"][str(s["peer_id"])]) < 3,
               "rejoin spawn position synchronized", 10)
        equal_shared(a, b)
        note("B reloaded and rejoined with authoritative state")

        server.terminate()
        server.wait(timeout=5)
        for browser in (a, b):
            browser.wait(lambda s: not s["online"], "server disconnect", 10)
        server = start_server("browser_server_restarted")
        for browser in (a, b):
            browser.press("n")
            browser.wait(lambda s: s["online"], "server reconnection", 15)
            browser.wait(lambda s: str(s["peer_id"]) in s["peers"] and math.dist(s["position"], s["peers"][str(s["peer_id"])]) < 3,
                         "restarted server spawn position synchronized", 10)
        a.wait(lambda s: s["money"] == paid["money"] and s["inventory"] == paid["inventory"], "saved state restored", 10)
        equal_shared(a, b)
        note("Backend restart restored persistent money and inventory to both browsers")
        note("FULL TWO-BROWSER CO-OP TEST PASSED")
    finally:
        for browser in (a, b):
            try:
                browser.close()
            except Exception as error:
                note(f"Browser cleanup: {error}")


try:
    run()
finally:
    for process in reversed(PROCESSES):
        if process.poll() is None:
            process.terminate()
            try:
                process.wait(timeout=5)
            except subprocess.TimeoutExpired:
                process.kill()
    for log in LOGS:
        log.close()
