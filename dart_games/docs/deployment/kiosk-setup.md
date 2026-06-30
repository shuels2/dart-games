# Kiosk Setup (Windows Service)

Run the Dart Games backend (which also serves the built Flutter web app) as
an always-on Windows service so the kiosk machine is ready at every boot,
even before anyone logs in.

The server gained a `--web-root` flag for this. When set, it serves
`build/web/` at `/` while keeping `/api/v1/*` for the REST API and
rewriting unknown paths to `index.html` so Flutter's client-side routing
works.

## What gets installed

- A Windows service called **DartGamesServer**, run by [WinSW](https://github.com/winsw/winsw)
- Binds **port 80** (so URLs are just `http://<machine>/`)
- Runs as a **local Windows account you choose at install time** so the
  Python sidecar can find that account's `pip install --user` packages
  (mediapipe for Treasure Divide face landmarks). The installer defaults
  to the currently logged-in user; you can override it at the prompt.
- Auto-starts on boot, restarts on failure, rotates logs at 10 MB

## One-time setup

1. **Install Flutter SDK** (provides `dart` + `flutter` on PATH).
2. **Run `check_python_deps.bat` once** to verify mediapipe etc. are
   installed for the Windows account the service will run as.
3. **Download WinSW**:
   - Get `WinSW-x64.exe` from
     https://github.com/winsw/winsw/releases
   - Rename it to `dart-games-service.exe`
   - Place it in this directory (`dart_games/`)
4. **Run `install_service.bat` as Administrator**
   (right-click → Run as administrator). It will:
   - Compile the server to `server/bin/server.exe`
   - Run `./build.bat build web`
   - Prompt for the **Windows account** to run the service as
     (format: `DOMAIN\USERNAME` — use `.\USERNAME` for a local account
     on this machine, or `AzureAD\USERNAME` / your tenant prefix for a
     Microsoft account). Defaults to `.\<current-user>` — press Enter
     to accept, or type a different account.
   - Prompt for that account's **Windows password** (stored in
     `dart-games-service.xml`, which is ACL-restricted to admins)
   - Install and start the **DartGamesServer** service

When it finishes, browse `http://localhost/` on the kiosk, or
`http://<this-machine-ip>/` from any device on the network.

## Updating after a git pull

Run **`update_service.bat` as Administrator**. It pulls, recompiles
the server, rebuilds the web app, and restarts the service.

## Managing the service

```bat
dart-games-service.exe status
dart-games-service.exe restart
dart-games-service.exe stop
dart-games-service.exe start
```
…or use `services.msc` for the GUI.

## Logs

`logs/service/` — rotated by size (10 MB, 5 files kept).

## Removing the service

Run **`uninstall_service.bat` as Administrator**. The service is removed
and `dart-games-service.xml` (which contains your password) is deleted.
Compiled artefacts (`server/bin/server.exe`, `build/web/`, data, log
files) are left in place — delete them by hand if you want a full reset.

## Security notes

- The WinSW XML stores your Windows password in plaintext. The install
  script ACLs it to Administrators + SYSTEM only. Don't commit it — it's
  in `.gitignore`.
- The WinSW exe itself is also gitignored (it's a downloaded binary, not
  repo state). Each kiosk machine downloads its own copy.
- Service runs on port 80. Make sure no other web server (IIS, Apache,
  etc.) is bound to that port on the same machine.
