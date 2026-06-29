# Helper scripts

These are **optional** thin wrappers around `docker compose` for users who prefer a
double-clickable file. The container's entrypoint ([`entrypoint.sh`](entrypoint.sh)) handles
first-install detection and starting `bench start`, so plain `docker compose up -d` from the
repo root is equally good.

| OS | Folder | Files |
|----|--------|-------|
| Windows (PowerShell) | [`windows/`](windows/) | `start.ps1`, `restart.ps1`, `stop.ps1` |
| Windows (CMD / double-click) | [`windows/`](windows/) | `start.bat`, `restart.bat`, `stop.bat` |
| macOS / Linux | [`mac/`](mac/) | `start.sh`, `restart.sh`, `stop.sh` |

## What each script does

| Script | Equivalent compose command |
|---|---|
| `start.*`   | `docker compose up -d` — boots the stack; first run installs everything |
| `restart.*` | `docker compose restart` — restarts container; entrypoint re-runs `bench start` |
| `stop.*`    | `docker compose stop` — stops the box; data is kept in the named volume |

After `start`/`restart`: open <http://test.localhost:8000> → `Administrator` / `erpadmindb`.

First-time install takes ~5–15 minutes — watch progress with:
```bash
docker compose logs -f erpnext-dev
```

## Windows execution-policy note

If PowerShell rejects the `.ps1` files with *"running scripts is disabled on this system"*, either
use the `.bat` files (unaffected by execution policy) or allow scripts for your user once:
```powershell
Set-ExecutionPolicy -Scope CurrentUser RemoteSigned
```

## The bootstrap script

[`entrypoint.sh`](entrypoint.sh) runs as PID 1 inside the container. It's mounted read-only from
the host, so editing it on the host and recreating the container picks up the change. It is
idempotent — skip any install step whose output already exists, then `exec bench start`.

Override defaults with env vars (or a `.env` next to `docker-compose.yml`): `SITE_NAME`,
`ADMIN_PASSWORD`, `FRAPPE_BRANCH`, `ERPNEXT_BRANCH`.

> Never run `docker compose down -v` unless you intend to wipe the data volume (bench, site, db).
