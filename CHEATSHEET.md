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

1. **The container** = the box. Managed by `docker compose`. It just runs `sleep infinity` and
   does nothing on its own.
2. **The web server** (`bench serve`) = the app running *inside* the box. **It does not start
   automatically with the container** — this is the #1 thing people forget.
3. **Your data** = lives in a Docker **named volume** (`erpnext-data`). It survives restarts and
   even deleting the container. It is destroyed only if you explicitly wipe the volume.

Two more terms you'll see everywhere:

- **Bench** = the install directory (`frappe-bench/`): the code (Frappe, ERPNext, your apps) +
  shared config. One bench can hold **many sites**.
- **Site** = one tenant (`sites/<name>/`): its own database, files, and users. Picked by the
  domain (e.g. `test.localhost`) or `bench --site <name> ...` on the CLI.
- 👉 **Code is shared (bench); data is isolated (site).**

---

## 3. Daily use — just use the scripts 🎯

**You do not need to memorize any Docker commands for everyday start/stop.** Ready-made scripts do
the two steps (start the box **and** the app) for you, so nobody has to remember the commands:

| OS | Command (from the scripts folder, or double-click the file) |
|---|---|
| Windows (CMD) | `start.bat` / `restart.bat` / `stop.bat` |
| Windows (PowerShell) | `.\start.ps1` / `.\restart.ps1` / `.\stop.ps1` |
| macOS / Linux | `./start.sh` / `./restart.sh` / `./stop.sh` |

Then open **http://test.localhost:8000** → log in as `Administrator` / `erpadmindb`.

> 💡 On Windows the `.bat` files need no setup. The `.ps1` files may need a one-time execution
> policy change — see the [README](README.md#fixing-running-scripts-is-disabled-on-this-system)
> and [scripts/README.md](scripts/README.md).

The sections below show the **manual** commands the scripts run — handy for DevOps, debugging, or
just understanding what's happening under the hood.

---

## 4. Docker commands explained (the manual way)

Run all of these from the folder that contains [docker-compose.yml](docker-compose.yml).

### Start
```bash
docker compose start                 # 1) start the box (container)
docker exec -d erpnext_lightweight bash -lc "cd /home/frappe/frappe-bench && exec bench serve --port 8000 >> logs/serve.log 2>&1"
                                     # 2) start the app (web server), detached
```
*Why two commands:* the web server isn't auto-started with the container. `-d` = detached, so it
keeps running after you close the terminal.

### Restart (e.g. after a config change)
```bash
docker compose restart
docker exec -d erpnext_lightweight bash -lc "cd /home/frappe/frappe-bench && exec bench serve --port 8000 >> logs/serve.log 2>&1"
```
*Why line 2 again:* `restart` kills `bench serve` along with the container's processes, so you
relaunch it.

### Stop
```bash
docker compose stop                  # stops the box and everything inside it; data is safe
```

### Watch the server live (foreground) instead of detached
```bash
docker exec -it erpnext_lightweight bash
cd /home/frappe/frappe-bench && bench serve --port 8000      # Ctrl+C to quit
```

### Check it's healthy
```bash
docker compose ps                                            # both erpnext_lightweight + erpnext_redis "Up"?
docker exec erpnext_lightweight tail -n 20 /home/frappe/frappe-bench/logs/serve.log
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

## 5. First-time setup (run once)

You only do this the very first time, or after a full reset.

```bash
# --- On your machine (host) ---
docker compose up -d                          # 1. start the container
docker exec -it erpnext_lightweight bash      # 2. open a shell inside it (you're now "frappe")

# --- Inside the container ---
cd /home/frappe
# 3. create the bench (v16) and pull ERPNext
bench init --skip-redis-config-generation --frappe-branch version-16 frappe-bench
cd frappe-bench
bench get-app --branch version-16 erpnext

# 4. point the bench at the Redis sidecar (hostname is "redis", NOT 127.0.0.1)
bench set-config -g redis_cache    redis://redis:6379/0
bench set-config -g redis_queue    redis://redis:6379/1
bench set-config -g redis_socketio redis://redis:6379/2

# 5. create the site on SQLite and install ERPNext
bench new-site test.localhost --db-type sqlite --admin-password erpadmindb --install-app erpnext

# 6. turn on developer mode and serve
bench --site test.localhost set-config developer_mode 1
bench --site test.localhost clear-cache
bench use test.localhost
bench serve --port 8000
```

Open **http://test.localhost:8000** → log in as `Administrator` / `erpadmindb`.

> ✅ Verify the version right after init:
> `./env/bin/python -c "import frappe; print(frappe.__version__)"` must print `16.x`.
> (SQLite only works on v16.)

After this, switch to the **daily-use scripts** (section 3) — don't repeat these steps.

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
| **Redis `Connection refused` (e.g. `127.0.0.1:11000`)** | The bench isn't pointed at the sidecar. Re-run the three `bench set-config -g redis_*` lines (host is `redis`). Confirm `docker compose ps` shows `erpnext_redis` Up. |
| **OOM while building assets (at 1500 MB)** | Temporarily raise `deploy.resources.limits.memory` in [docker-compose.yml](docker-compose.yml), recreate, build, then lower it back. |
| **`Permission denied` on first `bench init`** | `docker exec -u root erpnext_lightweight chown -R frappe:frappe /home/frappe/frappe-bench` |
| **Web server "not responding" after start** | Remember step 2 — the web server doesn't auto-start. Use a daily script, or run the `docker exec -d ... bench serve` line. |

> The volume name is `<project-folder>_erpnext-data`. Confirm yours with `docker volume ls` before
> running any `volume rm`.

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
