# Virtual Cinema 3D — Phase 1

A playable, cross-platform 3D cinema simulator built with **Godot 4.3** (Compatibility / GL renderer).

**Targets:** Windows desktop · Android APK  
**Language:** GDScript  
**Renderer:** `gl_compatibility` for broad mid-range and lower-end device support.

---

## Features (Phase 1)

| Feature | Status |
|--------|--------|
| 3D theater (floor, ceiling, walls, screen, aisles) | Done |
| 30 interactive seats | Done |
| First-person controller + collision + gravity | Done |
| Desktop: WASD, mouse look, Esc pause, E/Space interact | Done |
| Android: virtual joystick, touch look, on-screen buttons | Done |
| Sit / stand (raycast + proximity highlight) | Done |
| Screen placeholder material (test pattern style) | Done |
| Pause / resume + mouse capture | Done |
| Light dimming (L key / mobile button) | Done |
| Low-cost lighting, simple colliders, shared materials | Done |
| GitHub Actions: validate + Windows + Android export | Done |

**Not in Phase 1:** remote video playback, multiplayer, streaming UI.

---

## Quick start (local)

1. Install [Godot 4.3](https://godotengine.org/download) (standard build is fine; Compatibility renderer is selected in project settings).
2. Clone / open this folder as a project in the Godot editor.
3. Press **F5** (or Play). Main scene: `scenes/Main.tscn`.

### Controls

**Desktop**

- **WASD** / arrow keys — move  
- **Mouse** — look (captured on start)  
- **E** or **Space** — interact (sit when looking at a seat; stand when seated)  
- **Esc** — pause / resume  
- **L** — dim / restore cinema lights  

**Android**

- **Left joystick** — move (kept away from edges)  
- **Drag on right half of screen** — look  
- **Sit / Stand** button — interact  
- **Pause** / **Lights** buttons — top-right  

---

## Project layout

```
VirtualCinema3D/
├── project.godot
├── icon.svg
├── export_presets.cfg
├── .github/workflows/build.yml
├── docs/
│   └── ANDROID_SETUP.md
├── scenes/
│   ├── Main.tscn
│   ├── player/Player.tscn
│   ├── theater/Theater.tscn
│   ├── theater/Seat.tscn
│   └── ui/{HUD,MobileControls,PauseMenu}.tscn
├── scripts/
│   ├── Main.gd
│   ├── player/PlayerController.gd
│   ├── theater/{Theater,Seat}.gd
│   ├── managers/CinemaManager.gd
│   └── ui/{HUD,MobileControls,PauseMenu}.gd
└── assets/   (textures / audio placeholders for later phases)
```

Scripts are split by responsibility. Signals connect player ↔ manager ↔ theater ↔ UI. Interaction is null-safe and does not trap the player.

---

## Export (local)

### Windows

1. Editor → **Project → Export…**  
2. Select preset **Windows Desktop**.  
3. Export to e.g. `build/windows/VirtualCinema3D.exe`.

### Android

See **[docs/ANDROID_SETUP.md](docs/ANDROID_SETUP.md)** for SDK, templates, and debug keystore.  
Without a configured Android SDK and export templates, APK export will fail; the CI workflow documents this and only uploads artifacts on success.

---

## CI (GitHub Actions)

Workflow: `.github/workflows/build.yml`

- Pins **Godot 4.3-stable**.  
- **validate** job: download engine + templates, headless import, basic project checks.  
- **export-windows**: release export → artifact `VirtualCinema3D-Windows` on success only.  
- **export-android**: sets up JDK 17 + Android SDK, attempts debug APK export.  
  - On success → artifact `VirtualCinema3D-Android`.  
  - On failure → warning + upload of export log; no fake APK.  

Never commit keystores, passwords, or signing secrets. Use GitHub Secrets for release signing if you add it later.

---

## Design notes (performance)

- Compatibility renderer (OpenGL ES-friendly).  
- Omni/spot lights with **shadows disabled**.  
- Simple `BoxShape3D` / capsule colliders.  
- Shared dark / carpet materials; screen uses unshaded + emission.  
- No SSAO, glow, or heavy post-processing.  
- ~30 seat instances of one packed scene.

---

## Phase 2 ideas (out of scope)

- Video stream / local file playback on the screen mesh.  
- Seat reservation / simple multiplayer.  
- Richer audio ambience and door transitions.

---

## License

Project scaffolding provided for development. Add your preferred license before public release.
