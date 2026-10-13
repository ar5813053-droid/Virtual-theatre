# Virtual Cinema 3D (Virtual-theatre)

Playable 3D cinema simulator — **Godot 4.3**, Compatibility renderer, Windows + Android.

## Features

- 3D theater, 30 seats, sit/stand, pause, light dimming
- Desktop: WASD, mouse look, E interact, Esc pause, L lights, **V** video URL, **T** tablet
- Android: virtual joystick (correct axes), touch look (works while seated), on-screen buttons
- **URL video playback** on the real 3D cinema screen (direct `.ogv` / Ogg Theora files)
- **3D tablet** + touch-friendly control panel (play/pause, volume, seek, ±10s, mute, URL entry)

## Controls

| Action | Desktop | Android |
|--------|---------|---------|
| Move | WASD | Left joystick |
| Look | Mouse | Drag right half of screen (works while seated) |
| Sit / Stand | E or Space | Sit/Stand button |
| Pause | Esc | Pause button |
| Lights | L | Lights button |
| Video URL panel | V | Video button |
| Tablet | T | Tablet button |

## Video URL support (honest limits)

**Supported**

- Direct HTTP(S) links to **Ogg Theora** files (`.ogv`)
- Local `res://` / `user://` `.ogv` paths

**Not supported**

- YouTube / Instagram / Facebook / TikTok / Vimeo watch pages
- Ordinary HTML webpages
- DRM streams
- Stock Godot **does not** decode MP4/H.264 or WebM without extra modules

The UI will show a clear error instead of a fake player when the URL is a webpage or an unsupported format.

Example public test pattern (if reachable): any hosted `.ogv` direct link.

## Project layout

```
scripts/
  player/PlayerController.gd
  ui/MobileControls.gd, HUD.gd, PauseMenu.gd, URLEntryPanel.gd
  video/VideoManager.gd, VideoScreen.gd
  tablet/TabletController.gd, TabletUI.gd
  theater/, managers/
scenes/ … matching structure
```

## Run

1. Open folder in **Godot 4.3**
2. Play `scenes/Main.tscn` (F5)

## Export

See `docs/ANDROID_SETUP.md` and `export_presets.cfg`. CI: `.github/workflows/build.yml`.

## License

See LICENSE.
