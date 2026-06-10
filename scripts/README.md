# Helper scripts

One-click start / restart / stop for the local ERPNext stack. Each script finds
`docker-compose.yml` **relative to its own location** (`../../docker-compose.yml`), so you can run
it from anywhere. Every "start"/"restart" script also launches the web server (`bench serve`),
which does **not** auto-start with the container.

| OS | Folder | Files |
|----|--------|-------|
| Windows (PowerShell) | [`windows/`](windows/) | `start.ps1`, `restart.ps1`, `stop.ps1` |
| Windows (CMD / double-click) | [`windows/`](windows/) | `start.bat`, `restart.bat`, `stop.bat` |
| macOS / Linux | [`mac/`](mac/) | `start.sh`, `restart.sh`, `stop.sh` |

## Windows (PowerShell)
```powershell
# from the scripts\windows folder:
./start.ps1      # start container + web server
./restart.ps1    # restart container + web server
./stop.ps1       # stop everything (data kept)
```
If you get *"running scripts is disabled on this system"*, allow local scripts for your user once:
```powershell
Set-ExecutionPolicy -Scope CurrentUser RemoteSigned
```

## Windows (CMD / double-click)
Prefer not to touch execution policy? Use the `.bat` files instead — they run in CMD and are
**not** affected by PowerShell's execution policy, so you can simply double-click them.
```bat
:: from the scripts\windows folder (or just double-click the file):
start.bat        :: start container + web server
restart.bat      :: restart container + web server
stop.bat         :: stop everything (data kept)
```

## macOS / Linux (bash)
```bash
# from the scripts/mac folder, make them executable once:
chmod +x start.sh restart.sh stop.sh
./start.sh       # start container + web server
./restart.sh     # restart container + web server
./stop.sh        # stop everything (data kept)
```

After **start**/**restart**: open <http://test.localhost:8000> → `Administrator` / `erpadmindb`.

> These manage an **already-set-up** stack. For the first-time install, follow `../CHEATSHEET.md`.
> Never run `docker compose down -v` — it deletes the data volume (whole bench/site/app).
