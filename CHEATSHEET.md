# ERPNext 16 Lightweight — Cheat Sheet

A simple, no-jargon guide to running this lightweight **ERPNext v16** (SQLite, no MariaDB) in
Docker. Written for both DevOps and developers — if you can copy-paste, you can run this.

> New here? Read the [README.md](README.md) first for the big picture. This file is the hands-on
> command reference.

---

## 1. What you need (system requirements)

| Thing | Requirement |
|---|---|
| **Docker Desktop** | Installed and **running** (the only thing you must install) |
| **RAM** | ~2 GB free is plenty — the stack is capped at 1500 MB |
| **CPU** | 1 core is enough (the container is capped at 1.0 CPU) |
| **Disk** | ~3–4 GB for the image + bench + site |
| **OS** | Windows, macOS, or Linux (anywhere Docker runs) |
| **Internet** | Needed for first-time setup (downloads Frappe + ERPNext) |

You do **not** need Python, Node, MariaDB, or Redis installed on your machine — everything runs
**inside** the container.

---

## 2. The mental model (read this once)

Three layers, from outside in:

1. **The container** = the box. Managed by `docker compose`. Its entrypoint
   ([`scripts/entrypoint.sh`](scripts/entrypoint.sh)) self-detects whether the volume is empty
   (first install) or already set up (just restart), then runs `bench start` to keep all services
   alive.
2. **The bench services** (web on 8000, socketio on 9000, worker, scheduler, asset watcher) =
   the app running *inside* the box. Started automatically by the entrypoint — you do **not**
   need a second command.
3. **Your data** = lives in a Docker **named volume** (`erpnext-data`). It survives restarts and
   even deleting the container. It is destroyed only if you explicitly wipe the volume.

Two more terms you'll see everywhere:

- **Bench** = the install directory (`frappe-bench/`): the code (Frappe, ERPNext, your apps) +
  shared config. One bench can hold **many sites**.
- **Site** = one tenant (`sites/<name>/`): its own database, files, and users. Picked by the
  domain (e.g. `test.localhost`) or `bench --site <name> ...` on the CLI.
- 👉 **Code is shared (bench); data is isolated (site).**

---

## 3. Daily use — one command 🎯

From the folder containing [docker-compose.yml](docker-compose.yml):

```bash
docker compose up -d              # first install OR restart — same command
docker compose restart            # restart after a config change
docker compose stop               # stop everything (data kept)
docker compose logs -f erpnext-dev   # follow first-install progress or runtime logs
```

Then open **http://test.localhost:8000** → log in as `Administrator` / `erpadmindb`.

There are also optional double-clickable wrappers in `scripts/{windows,mac}/` that just call
`docker compose` under the hood — use whichever you prefer.

---

## 4. Watch the server live (foreground)
```bash
docker compose up                 # same as `up -d` but stays attached, Ctrl+C to stop
```

### Check it's healthy
```bash
docker compose ps                                            # both erpnext_lightweight + erpnext_redis "Up"?
docker compose logs -f erpnext-dev                           # follow the entrypoint + bench start output
docker exec erpnext_lightweight tail -n 20 /home/frappe/frappe-bench/logs/web.log
```

### Other useful container commands

| Action | Command | What it does |
|---|---|---|
| Pause | `docker pause erpnext_lightweight` | Freeze (RAM kept, 0 CPU). Resume with `unpause`. |
| Resume | `docker unpause erpnext_lightweight` | Continue after a pause |
| Status | `docker compose ps` | See what's running |
| Container logs | `docker compose logs -f` | Follow Docker-level output |
| Open a shell | `docker exec -it erpnext_lightweight bash` | Get inside the container as `frappe` |
| Delete (keep data) | `docker compose down` | Remove containers, **keep** the data volume |
| Delete (wipe ALL) | `docker compose down -v` | ⚠️ Remove containers **and** the data volume |

> ⚠️ `docker compose down -v` **permanently destroys** your bench, site, and database. Only use it
> for a clean reset.

---

## 5. First-time setup — automatic

You don't run any of this by hand anymore. `docker compose up -d` triggers the entrypoint
([`scripts/entrypoint.sh`](scripts/entrypoint.sh)), which on an empty volume runs the full
install: `bench init` → `bench get-app erpnext` → redis config → `bench new-site` (SQLite) →
`install-app erpnext` → `developer_mode 1` → `bench start`.

Watch progress with `docker compose logs -f erpnext-dev` (takes 5–15 minutes on the first run).
When it prints the "Bench ready" line, open **http://test.localhost:8000** and log in as
`Administrator` / `erpadmindb`.

> ✅ Verify the version after install:
> `docker exec erpnext_lightweight /home/frappe/frappe-bench/env/bin/python -c "import frappe; print(frappe.__version__)"`
> must print `16.x`. (SQLite only works on v16.)

### Overriding defaults

Set these env vars (in your shell, or a `.env` next to `docker-compose.yml`) **before** the first
`up`:

| Variable | Default | Notes |
|---|---|---|
| `SITE_NAME` | `test.localhost` | Browser URL becomes `http://<SITE_NAME>:8000` |
| `ADMIN_PASSWORD` | `erpadmindb` | Administrator password for the site |
| `FRAPPE_BRANCH` | `version-16` | Don't change unless you know SQLite needs v16 |
| `ERPNEXT_BRANCH` | `version-16` | Match Frappe branch |

### If install fails partway

The entrypoint is idempotent. Fix the cause, then `docker compose up -d` again — it picks up where
it stopped. Common cause: OOM. Bump `deploy.resources.limits.memory` in `docker-compose.yml` and
retry. If the install got far enough to create a broken bench dir, wipe and retry:
`docker compose down -v && docker compose up -d` (deletes the data volume).

---

## 6. Baby steps: create a NEW bench (for learning / experiments / app dev)

Want a clean, separate playground — to practise, try a risky change, or build a custom app —
**without touching your main bench/site**? Create another bench inside the same container. Benches
are just folders under `/home/frappe`, so they sit happily side by side.

```bash
# Get inside the container
docker exec -it erpnext_lightweight bash
cd /home/frappe

# 1. Create a new bench (give it any name, e.g. "lab-bench")
bench init --skip-redis-config-generation --frappe-branch version-16 lab-bench
cd lab-bench

# 2. Point THIS bench at the same Redis sidecar (every bench needs this)
bench set-config -g redis_cache    redis://redis:6379/0
bench set-config -g redis_queue    redis://redis:6379/1
bench set-config -g redis_socketio redis://redis:6379/2

# 3. (Optional) pull ERPNext into this bench too
bench get-app --branch version-16 erpnext

# 4. Create a practice site (use a DIFFERENT name than your main one)
bench new-site lab.localhost --db-type sqlite --admin-password erpadmindb --install-app erpnext

# 5. Turn on developer mode (important for app development) and serve
bench --site lab.localhost set-config developer_mode 1
bench use lab.localhost
bench serve --port 8001          # different port so it won't clash with the main bench
```

Open **http://lab.localhost:8001** → `Administrator` / `erpadmindb`.

> ⚠️ **One `bench serve` per port.** If your main bench already serves on 8000, give the new one
> 8001 (or stop the main one first). The container only forwards port 8000 by default — to reach
> 8001 from your browser, add `- "8001:8001"` under `ports:` in
> [docker-compose.yml](docker-compose.yml) and recreate the container (`docker compose up -d`).

### Build your own app in the new bench

```bash
cd /home/frappe/lab-bench
bench new-app my_custom_app                       # scaffolds apps/my_custom_app
bench --site lab.localhost install-app my_custom_app
# ...edit code under apps/my_custom_app...
bench --site lab.localhost migrate                # apply schema changes after editing doctypes
bench --site lab.localhost clear-cache
bench build --app my_custom_app                   # rebuild JS/CSS assets when needed
```

### Install an EXISTING app from your machine into a bench

```bash
# On your machine: copy the app's repo folder into the bench
docker cp "C:\path\to\your_app" erpnext_lightweight:/home/frappe/lab-bench/apps/your_app
docker exec -u root erpnext_lightweight chown -R frappe:frappe /home/frappe/lab-bench/apps/your_app

# Inside the container
cd /home/frappe/lab-bench
./env/bin/pip install -e apps/your_app
grep -qx your_app sites/apps.txt || echo your_app >> sites/apps.txt
bench --site lab.localhost install-app your_app
bench build --app your_app
bench --site lab.localhost migrate && bench --site lab.localhost clear-cache
```

> 🧪 **Golden rule for experiments:** practise/test on a throwaway bench or site — never on a live
> one. A site is self-contained, so you can always move it with `bench backup` → `bench restore`.

---

## 7. Troubleshooting (common gotchas)

| Symptom | Fix |
|---|---|
| **v15 + SQLite fails** | SQLite is v16-only. Always use `--frappe-branch version-16`. |
| **`Bench instance already exists` / wrong version** | The volume holds a stale bench. Reset: `docker compose down`, `docker volume rm erpnext16_lightweight_erpnext-data`, `docker compose up -d`, then re-init. |
| **Scripts say "container is not running" / data looks empty after renaming the folder** | Compose keys resources to the project name (the folder name). This project pins it via [`.env`](.env) (`COMPOSE_PROJECT_NAME=erpnext16_lightweight`) so renaming/moving the folder still finds the existing containers and the `erpnext16_lightweight_erpnext-data` volume. Don't delete `.env`. |
| **Redis `Connection refused` (e.g. `127.0.0.1:11000`)** | The bench isn't pointed at the sidecar. Re-run the three `bench set-config -g redis_*` lines (host is `redis`). Confirm `docker compose ps` shows `erpnext_redis` Up. |
| **OOM while building assets (at 1500 MB)** | Temporarily raise `deploy.resources.limits.memory` in [docker-compose.yml](docker-compose.yml), recreate, build, then lower it back. |
| **`Permission denied` on first `bench init`** | `docker exec -u root erpnext_lightweight chown -R frappe:frappe /home/frappe/frappe-bench` |
| **Web server "not responding" after start** | Remember step 2 — the web server doesn't auto-start. Use a daily script, or run the `docker exec -d ... bench serve` line. |

> The volume name is `<project-name>_erpnext-data`. The project name is pinned to
> `erpnext16_lightweight` in [`.env`](.env), so the data volume is
> `erpnext16_lightweight_erpnext-data`. Confirm with `docker volume ls` before any `volume rm`.

---

## Notes

- Frappe **v16 needs Python 3.14**, which `frappe/bench:latest` already provides — don't pin an
  older Python.
- **Redis is mandatory** even on SQLite (cache / queue / socketio). The `redis` service in
  [docker-compose.yml](docker-compose.yml) provides it.
- ⚠️ **SQLite is for local dev/practice only.** For multi-client or production, use **MariaDB or
  Postgres**.

---

Thanks to **[Softlancer Solutions](https://softlancersolutions.com)** ·
☕ [Buy Me a Coffee](https://www.buymeacoffee.com/abdeali.c)
