"""Firefox WebDriver smoke test for a local Godot web export."""
import base64
import json
import time
import urllib.request

ROOT = "http://127.0.0.1:4444"


def command(method, path, payload=None):
    data = None if payload is None else json.dumps(payload).encode()
    request = urllib.request.Request(
        ROOT + path,
        data=data,
        method=method,
        headers={"Content-Type": "application/json"},
    )
    with urllib.request.urlopen(request, timeout=30) as response:
        return json.load(response)["value"]


session = command(
    "POST",
    "/session",
    {"capabilities": {"alwaysMatch": {"browserName": "firefox", "moz:firefoxOptions": {"args": ["-headless"]}}}},
)["sessionId"]
try:
    command("POST", f"/session/{session}/url", {"url": "http://127.0.0.1:8765"})
    time.sleep(8)
    info = command(
        "POST",
        f"/session/{session}/execute/sync",
        {"script": "return {title: document.title, canvas: !!document.querySelector('canvas'), width: document.querySelector('canvas')?.width, height: document.querySelector('canvas')?.height}", "args": []},
    )
    png = command("GET", f"/session/{session}/screenshot")
    with open("/tmp/seoul-webdriver.png", "wb") as image:
        image.write(base64.b64decode(png))
    print(json.dumps(info))
    assert info["canvas"] and info["width"] > 0 and info["height"] > 0
finally:
    command("DELETE", f"/session/{session}")
