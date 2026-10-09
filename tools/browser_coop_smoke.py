"""Open two Firefox web clients against the local Godot WebSocket server."""
import base64
import json
import time
import urllib.request
import urllib.error

ROOTS = ["http://127.0.0.1:4444", "http://127.0.0.1:4445"]


def command(index, method, path, payload=None):
    request = urllib.request.Request(
        ROOTS[index] + path,
        data=None if payload is None else json.dumps(payload).encode(),
        method=method,
        headers={"Content-Type": "application/json"},
    )
    try:
        with urllib.request.urlopen(request, timeout=40) as response:
            return json.load(response)["value"]
    except urllib.error.HTTPError as error:
        raise RuntimeError(error.read().decode()) from error


sessions = []
try:
    for index in range(2):
        session = command(index, "POST", "/session", {"capabilities": {"alwaysMatch": {"browserName": "firefox", "moz:firefoxOptions": {"args": ["-headless"]}}}})["sessionId"]
        sessions.append(session)
        command(index, "POST", f"/session/{session}/url", {"url": "http://127.0.0.1:8765"})
    time.sleep(10)
    for index, session in enumerate(sessions):
        canvas = command(index, "POST", f"/session/{session}/element", {"using": "css selector", "value": "canvas"})
        element_id = canvas["element-6066-11e4-a52e-4f735466cecf"]
        command(index, "POST", f"/session/{session}/execute/sync", {"script": "document.querySelector('canvas').focus()", "args": []})
        command(index, "POST", f"/session/{session}/element/{element_id}/value", {"text": "\ue007"})
        command(index, "POST", f"/session/{session}/element/{element_id}/value", {"text": "n"})
    time.sleep(4)
    for index, session in enumerate(sessions):
        png = command(index, "GET", f"/session/{session}/screenshot")
        with open(f"/tmp/seoul-browser-client-{index + 1}.png", "wb") as image:
            image.write(base64.b64decode(png))
    print("TWO BROWSER WINDOWS OPENED AND CONNECTION KEYS SENT")
finally:
    for index, session in enumerate(sessions):
        command(index, "DELETE", f"/session/{session}")
