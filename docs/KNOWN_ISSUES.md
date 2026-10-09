# Known issues

- The room is fixed as `SEOUL`. There is no create/join code UI, ready state or membership authorization.
- Saves include day, money and inventory, but not furniture, unlocks, active orders or full recovery state. The server uses a single local JSON file.
- Customers follow one fixed entry/exit path to one table. They do not choose seats, avoid changed furniture or recover from a blocked path.
- No build mode, furniture placement or path validation exists yet.
- Stove control has a single owner. Other players can add ingredients, but cannot take over the heat after an abrupt disconnect until the peer leave event releases the lock.
- No audio, touch joystick, settings menu, reconnect identity or mobile device test yet.
- Visuals are original procedural prototype art, not final sprite sheets or animation sets.
- Browser multiplayer needs a reachable WSS backend when the page is served over HTTPS.
