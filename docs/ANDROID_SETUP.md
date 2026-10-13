# Android export setup (Virtual Cinema 3D)

Phase 1 ships with an **Android** export preset (`export_presets.cfg`) targeting **arm64-v8a**, package `com.virtualcinema.vc3d`.

CI attempts a **debug** APK export. Artifacts are uploaded **only** when the APK file is produced. Failures are logged and do not invent a successful build.

---

## Required on a developer machine

1. **Godot 4.3** with **Android export templates** installed  
   - Editor → Editor Settings → Export → Android  
   - Or download templates matching your exact Godot version from [Godot releases](https://github.com/godotengine/godot/releases).

2. **Android SDK** (command-line tools or Android Studio)  
   - Platform API level recommended: **34** (or current stable).  
   - Build-tools (e.g. 34.0.0).  
   - Set path in Godot: **Editor Settings → Export → Android → Android SDK Path**.

3. **JDK 17** (Temurin / OpenJDK).

4. **Debug keystore** (optional for first debug builds)  
   Godot can generate one, or use the Android default:
   ```bash
   keytool -genkey -v -keystore debug.keystore -storepass android \
     -alias androiddebugkey -keypass android -keyalg RSA -keysize 2048 \
     -validity 10000 -dname "CN=Android Debug,O=Android,C=US"
   ```
   Point Godot’s debug keystore fields at this file. **Never commit** the keystore or passwords.

5. Export:
   - Project → Export → **Android** → Export Project  
   - Output: `build/android/VirtualCinema3D.apk`

---

## CI notes

The workflow (`.github/workflows/build.yml`):

- Installs JDK 17 and Android SDK via `android-actions/setup-android`.
- Downloads Godot 4.3-stable + export templates.
- Writes a minimal `editor_settings-4.3.tres` with an SDK path hint.
- Runs `--export-debug "Android"`.
- If the APK is missing, it emits a warning, uploads the export log, and **does not** publish a fake artifact.

Common failure causes:

| Cause | Fix |
|-------|-----|
| Missing export templates | Install templates for the same Godot version used in CI |
| SDK path not found | Ensure `ANDROID_HOME` / setup-android path matches editor settings |
| Build-tools / platform missing | Install via `sdkmanager "platforms;android-34" "build-tools;34.0.0"` |
| Signing | Use debug keystore for CI; store release secrets in GitHub Secrets only |

---

## Release signing (not configured in Phase 1)

Do **not** put release keystore paths or passwords in `export_presets.cfg` in the repo.  
For production:

1. Store keystore as a GitHub Secret (base64) or use a secure file action.  
2. Pass `keystore/release`, `keystore/release_user`, `keystore/release_password` via environment or a generated preset at build time.  
3. Prefer `--export-release` only after secrets are injected.

---

## Compatibility renderer

`project.godot` sets:

```
renderer/rendering_method="gl_compatibility"
renderer/rendering_method.mobile="gl_compatibility"
```

This is intentional for mid-range and lower-end Android devices. Switch to Forward+ later only if you accept narrower GPU support.
