# ERPNext 16 — Lightweight (SQLite) Docker Setup

A minimal, resource-friendly **ERPNext v16** you can run locally for learning, practice, and
development — backed by **SQLite (no MariaDB)** plus one tiny `redis:alpine` sidecar, all wrapped
in Docker Compose and capped at **1 CPU / 1500 MB RAM** so it never overwhelms your machine.

> SQLite support requires **Frappe/ERPNext v16** — it is not available on v15.

---

## What this is

- **One container** running ERPNext (`frappe/bench:latest`), command `sleep infinity`, with the
  web UI on port **8000**.
- **SQLite** as the database — a plain file inside the site, so there is **no separate database
  server** to install, tune, or babysit.
- **One small Redis** sidecar (`redis:7-alpine`) for Frappe's cache / queue / socketio. Redis is
  **mandatory** even with SQLite — ERPNext won't install or run without it.
- **Hard resource limits** in [docker-compose.yml](docker-compose.yml) so the stack stays light.
- **Persistent data**: your bench, site, and database live in the named volume `erpnext-data` and
  survive container restarts.

## Why this setup (benefits)

- 🪶 **Tiny footprint** — SQLite means no MariaDB/Postgres server process to run alongside.
- 🛡️ **Won't hog your host** — hard CPU/RAM caps keep Docker in check.
- ⚡ **Fast to spin up** — a couple of commands (or one script) and you're running.
- 💾 **Data persists** — everything is kept in the `erpnext-data` volume across stop/start.
- 🏢 **Multi-site capable** — one bench can host many sites (code shared, data isolated per site).
- 🖱️ **One-click scripts** — start / restart / stop helpers for Windows and macOS/Linux.
- ♻️ **Reproducible** — the whole environment is described in `docker-compose.yml`.

> ⚠️ **SQLite is for local dev only.** For multi-client / production use, switch to
> **MariaDB or Postgres**. See [CHEATSHEET.md](CHEATSHEET.md) for the reasoning.

---

## Prerequisites

- **Docker Desktop** installed and **running**.
- Run `docker` commands from the folder containing [docker-compose.yml](docker-compose.yml)
  (the helper scripts handle this for you).

## Get started — one command

```bash
docker compose up -d
```

That's it. The container's entrypoint ([`scripts/entrypoint.sh`](scripts/entrypoint.sh))
self-detects state:

- **First run** (empty volume): runs `bench init`, pulls ERPNext, points it at the redis sidecar,
  creates the `test.localhost` site on SQLite, installs ERPNext, then starts all services.
  Takes ~5–15 minutes; watch progress with `docker compose logs -f erpnext-dev`.
- **Subsequent runs**: skips install, just runs `bench start` (web + socketio + worker +
  scheduler + asset watcher).

Open **http://test.localhost:8000** → log in as `Administrator` / `erpadmindb`.

To restart after a config change: `docker compose restart`. To stop: `docker compose stop`.
To wipe and start over: `docker compose down -v` (⚠️ deletes your data volume).

> Override the site name, admin password, or branches with env vars or a `.env` next to
> `docker-compose.yml`: `SITE_NAME`, `ADMIN_PASSWORD`, `FRAPPE_BRANCH`, `ERPNEXT_BRANCH`.

---

## Helper scripts (optional convenience)

Thin wrappers around `docker compose up -d` / `restart` / `stop` for users who prefer a
double-clickable file. **Not required** — `docker compose up -d` does the same thing.

| OS / Shell | Scripts | Notes |
|---|---|---|
| **Windows — PowerShell** | `scripts/windows/{start,restart,stop}.ps1` | May need an execution-policy change (see below) |
| **Windows — CMD / double-click** | `scripts/windows/{start,restart,stop}.bat` | ✅ No setup — `.bat` files are **not** affected by execution policy |
| **macOS / Linux — bash** | `scripts/mac/{start,restart,stop}.sh` | Run `chmod +x` once |

```powershell
# Windows (PowerShell), from scripts\windows:
.\start.ps1      # start container + web server
.\restart.ps1    # restart container + web server
.\stop.ps1       # stop everything (data kept)
```

```bat
:: Windows (CMD), from scripts\windows — or just double-click the file:
start.bat        :: start container + web server
restart.bat      :: restart container + web server
stop.bat         :: stop everything (data kept)
```

```bash
# macOS / Linux, from scripts/mac (chmod +x once):
./start.sh       # start container + web server
./restart.sh     # restart container + web server
./stop.sh        # stop everything (data kept)
```

After **start** / **restart**, open **http://test.localhost:8000** →
log in as `Administrator` / `erpadmindb`.

See [scripts/README.md](scripts/README.md) for more detail on the scripts.

---

## Fixing: *"running scripts is disabled on this system"*

By default Windows blocks all PowerShell `.ps1` scripts. This is a one-time machine setting, not a
bug in the scripts. Pick one:

1. **Run it once without changing anything** (safest for occasional use):
   ```powershell
   powershell -ExecutionPolicy Bypass -File .\start.ps1
   ```
2. **Allow scripts for your user account** (recommended for regular use — run once, no admin
   rights needed):
   ```powershell
   Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned
   ```
3. **Allow scripts for the current terminal only** (resets when you close the window):
   ```powershell
   Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
   ```

> 💡 **Or skip all of that** and use the `.bat` files in `scripts/windows/` — they run in CMD and
> are unaffected by PowerShell's execution policy. Just double-click them.

---

## Documentation

- **[CHEATSHEET.md](CHEATSHEET.md)** — full first-time install, daily commands, and gotchas.
- **[scripts/README.md](scripts/README.md)** — details on the helper scripts.

---

## Credits

Thanks to **[Softlancer Solutions](https://softlancersolutions.com)**.

## Support / Donate

If this saved you some time, you can support the work:

[![Buy Me a Coffee](https://img.shields.io/badge/Buy%20Me%20a%20Coffee-support-yellow?logo=buymeacoffee&logoColor=black)](https://www.buymeacoffee.com/abdeali.c)

☕ **https://www.buymeacoffee.com/abdeali.c**
