# MeshSOS — Step 1 (minimal skeleton)

## What this is

Just enough to run the app and see a blank screen with "MeshSOS - setup
working" — proves the project, Riverpod, and theme are wired correctly
before any real feature code is written.

## Setup

1. `flutter create meshsos` (if you haven't already)
2. Replace the generated `lib/` folder's contents with these 3 files,
   keeping the same paths:
   - `lib/main.dart`
   - `lib/app.dart`
   - `lib/core/theme/app_theme.dart`
3. Open `pubspec.yaml`, add ONLY this under `dependencies:`
   (nothing else yet — no hive, no nearby_connections, no uuid):
   ```yaml
   flutter_riverpod: ^2.5.1
   ```
4. `flutter pub get`
5. `flutter run`

## What you should see

A single screen with the text "MeshSOS - setup working" in the center.
That's it. If this runs without errors, the foundation is correct and
you're ready for the next step: `core/models/message_envelope.dart`,
which is the first file the mesh_chat feature actually needs.

## Do NOT add yet

- Navigation/routing (only one screen exists)
- Any feature folder (`features/mesh_chat/`, etc.)
- Any dependency beyond `flutter_riverpod`

Adding these now would be building ahead of what the code actually
needs — the next real step is the `MessageEnvelope` model, nothing else.

---

## Step 2: `core/models/mesh_message.dart` + `core/utils/id_generator.dart`

This is the shared data shape every future feature (mesh_chat, sos,
cloud_sync) will build on top of. Renamed from `MessageEnvelope` to
`MeshMessage` for clarity - same concept, friendlier name.

### Add to `pubspec.yaml`

```yaml
dependencies:
  flutter_riverpod: ^2.5.1
  uuid: ^4.4.0

dev_dependencies:
  flutter_test:
    sdk: flutter
```

Note the `name:` field at the top of `pubspec.yaml` must be `meshsos`
for the test's import (`package:meshsos/core/models/mesh_message.dart`)
to resolve - `flutter create meshsos` sets this automatically.

### Verify it works BEFORE writing any more code

```
flutter pub get
flutter test
```

Both tests in `test/core/models/mesh_message_test.dart` should pass.
This is the "can I test this alone?" checkpoint from the dependency-order
framework — `MeshMessage` needed zero Bluetooth, zero UI, zero Riverpod
to verify. If these tests pass, the model is solid and everything built
on top of it (routing, mesh service) has a safe foundation.

### What's next

`features/mesh_chat/data/routing_service.dart` — the TTL + duplicate-detection
algorithm, which is the first thing that actually USES `MeshMessage`.