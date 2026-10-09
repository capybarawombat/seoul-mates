# Deployment and release setup

No public client or backend has been deployed. There is no Git remote. The GitHub CLI is installed but its configured token is invalid, so repository creation and Pages deployment cannot run until authentication is restored.

## Production Web client

Use the checked-in, single-threaded Web export preset and supply a real WSS endpoint:

```bash
SEOUL_GODOT=/path/to/godot python3 tools/export_web.py --wss-url wss://game.example.com/socket
python3 -m http.server 8765 --directory build/web
```

The script runs `--export-release`, checks the generated HTML/JS/WASM/PCK files, verifies that threading is disabled, and writes the chosen WSS URL into the generated HTML. The URL is a configuration value, not a secret. Static HTTPS hosting and the WebSocket backend are separate services.

`.github/workflows/deploy-pages.yml` is a manual Pages workflow. After a private repository exists, enable GitHub Pages with GitHub Actions as its source, set repository variable `SEOUL_MATES_WSS_URL` to the reachable `wss://.../socket` address, run **Build Web and deploy Pages**, and check the reported Pages URL in a browser. The workflow downloads checksum-pinned Godot 4.7.2 editor and Web templates, runs headless checks, exports release files and uploads them to Pages. It has not run on GitHub yet.

## Dedicated backend

`server/Dockerfile` packages the same Godot code as a headless server. The official Godot editor archive is checksum-pinned. `server/compose.yaml` mounts a named volume at `/srv/data` for Godot's `user://` saves. Caddy terminates HTTPS and proxies `wss://<domain>/socket` to port 9090 inside the private Compose network. On a Linux host with Docker Compose installed, domain DNS pointing to the host and ports 80/443 open:

```bash
cp server/.env.example server/.env
# Edit SEOUL_MATES_DOMAIN in server/.env.
docker compose --env-file server/.env -f server/compose.yaml up -d --build
```

The local machine has Docker CLI but no accessible daemon or Compose plugin, so this image and proxy have **not** been built or tested here. A host, domain and working Docker installation are required to validate them.

The room code is fixed as `SEOUL`, and neither room membership nor saved restaurant ownership is authenticated. TLS protects transport, but this backend must remain restricted to trusted testers until room authorization, persistent identity, input rate limits and backup procedures are complete. Do not treat the Caddy configuration as application authorization.

## GitHub publication blocker

The local Git tree is clean and has no remote. `gh auth status` reports that the active GitHub token is invalid. After logging in with `gh auth login -h github.com`, the requested publication steps are: create `seoul-mates` as a **private** repository, attach it as `origin`, push the existing history, confirm Actions completes, and only then run the Pages workflow. No source has been pushed and no URL has been verified.
