# SEOUL MATES — Codex starter

This archive is designed to **extract directly into** `/extra/nh/pixelfood/`.

Included:
- `GAME_BLUEPRINT.md` — your original SEOUL MATES concept, preserved from the provided text.
- `MASTER_PROMPT.md` — detailed implementation assignment for Codex.
- `AGENTS.md` — persistent agent instructions.
- `docs/DEVELOPMENT_STATUS.md` — honest initial status and checkpoint tracking.
- `START_HERE.md` — this guide.

## Fish shell quick start

```fish
cd /extra/nh/pixelfood
# Unzip the package into this directory, preserving its paths.
# If Git isn't initialized already, run `git init` once.
if not test -d .git
    git init
end
codex
```

Paste this into Codex:

> Read `GAME_BLUEPRINT.md`, `MASTER_PROMPT.md`, `AGENTS.md` and `docs/DEVELOPMENT_STATUS.md`. Follow them as the project specification. Check existing files and Git state, then start implementing real, testable Godot gameplay immediately. Continue autonomously across milestones, updating development status and running tests. Don't stop at planning. Build the web game first; treat iOS as a later stage. Never claim unverified deployment or co-op success.

**Note:** The archive contains instructions/design documents, **not** a pre-built playable game. Codex must generate, test and integrate the game source itself.
