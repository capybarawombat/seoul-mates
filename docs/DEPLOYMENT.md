# Deployment status and local setup

No public client or backend has been deployed. There is no Git remote.

Export the Godot Web preset to `build/web/index.html` and serve the directory with an HTTP server. Run the dedicated Godot server separately with `godot --headless --path . -- --server`. The server listens on port 9090 without TLS. For HTTPS hosting, terminate TLS at a reverse proxy and pass WebSocket traffic to the server. Configure the generated page's `window.SEOUL_MATES_SERVER_URL` to the public WSS URL before release.

The current room code is fixed and is not an access credential. The save has no account ownership. Do not expose this server as a production public service until room authorization, persistent room identity and input rate limits are complete.
