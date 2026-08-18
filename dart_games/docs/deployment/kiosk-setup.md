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
- Runs as a **local Windows account you choose at install time**. The
  service token is used mainly for filesystem permissions; the Python
  sidecar itself is invoked via an **absolute interpreter path** and
  an explicit **`PYTHONPATH`** pinned into the WinSW XML at install
  time (see below), so it doesn't rely on the service account's
  `%APPDATA%` resolving to any particular location.
- Auto-starts on boot, restarts on failure, rotates logs at 10 MB

## Python sidecar env vars (baked in at install time)

The Treasure Divide face-landmarks feature spawns a Python sidecar to
call MediaPipe. Because Windows services don't load the interactive
user profile by default, neither `py`/`python` on PATH nor
`pip install --user` locations are reliably visible from the service
token. To sidestep that, `install_service.bat` resolves both at
install time and writes them into `dart-games-service.xml` as
`<env>` entries:

- **`DART_GAMES_PYTHON`** — absolute path to the interpreter the
  interactive shell resolved via `py` / `python` / `python3` (Store
  shims are explicitly rejected). The Dart `FaceLandmarksService`
  checks this env var first before probing PATH, so the service uses
  the same interpreter you tested with.
- **`PYTHONPATH`** — the resolved interpreter's user-site-packages
  directory (from `python -c "import site; print(site.getusersitepackages())"`),
  but only pinned if `cv2/` or `mediapipe/` is actually present
  there. Pins the site where `pip install --user` put MediaPipe/cv2
  so the sidecar can import them from a service context.

**Implication:** the shell you run `install_service.bat` from **must
have a working Python + MediaPipe** — that's what gets pinned. If you
later change Python versions or reinstall packages under a different
account, re-run `install_service.bat` so the XML picks up the new
paths.

If the installer can't resolve a real Python (only Store shim, or no
interpreter at all), it prints a warning and skips both env vars.
Everything else still works; Treasure Divide face-landmark features
report `python-not-found` until you install Python 3.9+ and re-run
the installer.

## MediaPipe FaceLandmarker task model

The sidecar prefers the **MediaPipe Tasks FaceLandmarker** path
(468 real landmark points — actual nose tip, mouth corners, jawline,
etc.) and falls back to an OpenCV Haar cascade heuristic only when
its task-model file is missing. The Haar fallback produces heuristic
(hardcoded) nose and mouth positions relative to the face bounding
box — visibly less accurate for character-avatar overlays like the
Treasure Divide pirate hats and glasses.

- **File:** `server/python/face_landmarker.task` (~3.8 MB, Apache 2.0)
- **Provenance:** Google's public MediaPipe models bucket,
  `https://storage.googleapis.com/mediapipe-models/face_landmarker/face_landmarker/float16/1/face_landmarker.task`
- **Committed to the repo** alongside the sidecar so a fresh checkout
  gets it automatically.
- **`check_python_deps.bat` verifies it and re-downloads if missing**
  (shallow clone, LFS misconfig, manual delete). A failed download
  is a WARN, not an ERROR — the app still runs, it just falls back
  to Haar until the file is restored.

## One-time setup

1. **Install Flutter SDK** (provides `dart` + `flutter` on PATH).
2. **Install Python 3.9+ and MediaPipe** for the account you will run
   `install_service.bat` from:
   - Download from https://www.python.org/downloads/ and check
     "Add python.exe to PATH" during install. Disable the Windows
     Store `python`/`python3` execution aliases
     (**Settings → Apps → Advanced app settings → App execution
     aliases**) — Store shims are rejected by the installer.
   - Run **`check_python_deps.bat`** — it locates a real (non-shim)
     Python, runs `pip install --user mediapipe opencv-python pillow
     numpy` if needed, and writes `.python_deps_verified` as a
     sentinel. This is the shell state `install_service.bat` will
     read from in step 4.
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
   - Resolve the current shell's Python + user-site and pin them into
     the WinSW XML as `DART_GAMES_PYTHON` / `PYTHONPATH` `<env>`
     entries (see "Python sidecar env vars" above). If either can't
     be resolved, it prints a warning and continues.
   - Install and start the **DartGamesServer** service

When it finishes, browse `http://localhost/` on the kiosk, or
`http://<this-machine-ip>/` from any device on the network.

## Updating after a git pull

Run **`update_service.bat` as Administrator**. It pulls, recompiles
the server, rebuilds the web app, and restarts the service.

⚠️ **Pull first, then run the updater.** `cmd.exe` re-reads a batch
file from a byte offset as it executes, so if the script's own
`git pull` step updates `update_service.bat` itself, the rest of the
run can jump to garbage. Run `git pull` manually beforehand — the
script's pull then becomes a harmless no-op.

### Confirming the update landed

The console window stays open at the end (see the `:hold` note below)
and prints a summary:

```
   Branch:   master
   Commit:   6a90872
   Build:    825      (was: 791)

  HOW TO CONFIRM THE UPDATE WORKED
   1. Open the app:  http://localhost/
   2. Go to  Options  ->  System Settings
   3. Look at the BOTTOM of the left sidebar
   4. It must read:   Build 825
```

That build number is `git rev-list --count HEAD`, computed the same
way `build.bat` computes it, and baked into the bundle via
`--dart-define=BUILD_NUMBER`. It renders as **"Build N"** at the
bottom of the Options → System Settings sidebar. If the app still
shows the old number, the browser is serving a cached bundle —
hard-refresh with **Ctrl+F5**.

The same summary is written to **`last_update.txt`** in the repo root
(gitignored), so the details survive even if the window is lost. The
previously-deployed number is tracked in `build/web/build_number.txt`,
stamped at the end of each successful run — so the first run after
this feature landed reports `previous: unknown`.

**Why `:hold` instead of `pause`:** `pause` reads stdin, and the child
processes the script runs (`flutter build web`, `dart pub get`) leave
the inherited stdin handle at EOF. `pause` then reads EOF, returns
instantly, and the window closes before the summary can be read. The
`:hold` subroutine uses `pause <CON` to reattach the real console
keyboard so it blocks as intended.

`update_service.bat` **does not touch** the pinned Python `<env>`
vars in the WinSW XML — it reuses whatever `install_service.bat`
last wrote. If you change Python versions or move MediaPipe to a
different site-packages location, re-run **`install_service.bat`**
(not the updater) so the XML picks up the new absolute paths.

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

## Troubleshooting face landmarks

If "Re-detect" fails on the kiosk (or you want to verify the sidecar
before opening a game), use **Options → Admin Options → Diagnose face
landmarks**. It hits `GET /api/v1/players/face-landmarks/diagnostics`
and reports, for the running service:

- Which `pythonCommand` was resolved (or "not found") and whether it
  came from `DART_GAMES_PYTHON` or from the fallback PATH probe.
- `sidecarPath` — the resolved `python/mediapipe_sidecar.py`.
- Whether `import mediapipe` works, and its version.
- The service's `workingDirectory`, `scriptPath`, and `platform`.

Common failure modes and fixes:

| Symptom | Cause | Fix |
| --- | --- | --- |
| ✗ Python interpreter — not found | `DART_GAMES_PYTHON` not pinned AND no `py`/`python` on the service's PATH | Install Python 3.9+ (add to PATH), then re-run `install_service.bat` so the absolute path gets pinned |
| ✓ Python + ✗ mediapipe importable | Interpreter can't find MediaPipe — usually `pip install --user` put it under a different account's `%APPDATA%` | Re-run `check_python_deps.bat` **from the account whose shell you'll use to run install_service.bat**, then re-run `install_service.bat` so `PYTHONPATH` gets pinned |
| ✓ Python + ✓ mediapipe + still fails on Re-detect | Photo has no face MediaPipe can find | Retake with a clearer, front-facing photo |
| Detection succeeds but eyebrows/mustache/beard overlays sit wrong on themed avatars | `server/python/face_landmarker.task` missing — sidecar fell back to Haar, which hardcodes nose and mouth positions | Re-run `check_python_deps.bat` — it verifies the task file exists and re-downloads it from Google's models bucket if not. If the download itself fails, manually save the file from `https://storage.googleapis.com/mediapipe-models/face_landmarker/face_landmarker/float16/1/face_landmarker.task` to `server/python/face_landmarker.task`, then Re-detect each affected player |

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
