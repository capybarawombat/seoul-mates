"""Serve and open the local release export in real headless Firefox."""

import base64
import json
import os
from pathlib import Path
import subprocess
import time
import urllib.request


ROOT = Path(__file__).resolve().parents[1]
GECKO = os.environ.get("SEOUL_GECKO", "/tmp/geckodriver")
PROCESSES = []


def call(method, path, payload=None):
    request = urllib.request.Request(
        "http://127.0.0.1:4444" + path,
        data=None if payload is None else json.dumps(payload).encode(),
        method=method,
        headers={"Content-Type": "application/json"},
    )
    with urllib.request.urlopen(request, timeout=40) as response:
        return json.load(response)["value"]


try:
    PROCESSES.append(subprocess.Popen(["python3", "-m", "http.server", "8765", "--bind", "127.0.0.1", "--directory", "build/web"], cwd=ROOT, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL))
    PROCESSES.append(subprocess.Popen([GECKO, "--host", "127.0.0.1", "--port", "4444"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL))
    time.sleep(1)
    session = call("POST", "/session", {"capabilities": {"alwaysMatch": {"browserName": "firefox", "moz:firefoxOptions": {"args": ["-headless"]}}}})["sessionId"]
    try:
        call("POST", f"/session/{session}/url", {"url": "http://127.0.0.1:8765"})
        time.sleep(10)
        result = call("POST", f"/session/{session}/execute/sync", {"script": "return {title:document.title, canvas:!!document.querySelector('canvas'), wss:window.SEOUL_MATES_SERVER_URL, debug:window.__SEOUL_TEST_STATE !== undefined}", "args": []})
        screenshot = call("GET", f"/session/{session}/screenshot")
        output = ROOT / "build" / "verification" / "release.png"
        output.parent.mkdir(parents=True, exist_ok=True)
        output.write_bytes(base64.b64decode(screenshot))
        print(json.dumps(result), flush=True)
        assert result["canvas"] and result["wss"].startswith("wss://") and not result["debug"]
        print("RELEASE FIREFOX STARTUP PASSED", flush=True)
    finally:
        call("DELETE", f"/session/{session}")
finally:
    for process in reversed(PROCESSES):
        process.terminate()
        process.wait(timeout=5)
