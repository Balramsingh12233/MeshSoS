# MeshSOS

**An offline-first, mesh-networked emergency chat app built in Flutter.**

MeshSOS lets nearby devices exchange messages over Bluetooth/WiFi Direct
with zero internet or cellular dependency, using a multi-hop
controlled-flooding routing algorithm. This repository is being built
incrementally and documented step by step, so each stage is a working,
verifiable checkpoint rather than a single large drop of code.

---

## Table of Contents

- [Project Status](#project-status)
- [Prerequisites](#prerequisites)
- [Getting Started](#getting-started)
- [Build Log](#build-log)
   - [Step 1 — Minimal Skeleton](#step-1--minimal-skeleton)
   - [Step 2 — Core Message Model](#step-2--core-message-model)
- [Verifying Your Setup](#verifying-your-setup)
- [Project Conventions](#project-conventions)
- [What's Next](#whats-next)

---

## Project Status

| Step | Deliverable | Status |
|---|---|---|
| 1 | App skeleton — Riverpod, theme, minimal shell | ✅ Complete |
| 2 | `MeshMessage` model + ID generator, unit-tested | ✅ Complete |
| 3 | Routing engine (TTL + duplicate detection) | ⏳ Not started |
| 4 | Mesh device discovery (`nearby_connections`) | ⏳ Not started |
| 5 | Local persistence (Hive) | ⏳ Not started |

Each step is designed to be independently runnable and testable before
the next one begins — no step depends on code that hasn't been verified yet.

---

## Prerequisites

- Flutter SDK (stable channel)
- A physical Android device for later mesh-networking steps (Bluetooth/WiFi
  Direct is not supported on emulators — not required yet at this stage)

---

## Getting Started

```bash
flutter create meshsos
cd meshsos
```

> The `name:` field in `pubspec.yaml` must remain `meshsos` — later steps
> import from `package:meshsos/...`, and renaming the project will break
> those imports.

Follow the [Build Log](#build-log) below in order. Each step lists the
exact files to add, the dependencies to declare, and how to confirm the
step works before moving to the next one.

---

## Build Log

### Step 1 — Minimal Skeleton

**Goal:** confirm the project, Riverpod, and theming are wired correctly
before any feature code exists.

**Files added:**
```
lib/main.dart
lib/app.dart
lib/core/theme/app_theme.dart
```

**Dependencies** (`pubspec.yaml`):
```yaml
dependencies:
  flutter_riverpod: ^2.5.1
```

**Run:**
```bash
flutter pub get
flutter run
```

**Expected result:** a single screen displaying `MeshSOS - setup working`.
Nothing else — no navigation, no feature folders, no additional
dependencies. Anything more at this stage would be building ahead of
what the code actually needs.

---

### Step 2 — Core Message Model

**Goal:** establish `MeshMessage`, the shared data structure every future
feature (mesh chat, SOS broadcast, cloud sync) will be built on top of.

> Renamed from an earlier internal working name `MessageEnvelope` to
> `MeshMessage` — same concept, clearer name.

**Files added:**
```
lib/core/models/mesh_message.dart
lib/core/utils/id_generator.dart
test/core/models/mesh_message_test.dart
```

**Dependencies** (`pubspec.yaml`):
```yaml
dependencies:
  flutter_riverpod: ^2.5.1
  uuid: ^4.4.0

dev_dependencies:
  flutter_test:
    sdk: flutter
```

**Run:**
```bash
flutter pub get
flutter test
```

**Expected result:** both tests in `mesh_message_test.dart` pass.

`MeshMessage` requires zero Bluetooth, zero UI, and zero Riverpod to
verify — it's pure data-layer logic, tested in isolation before anything
is built on top of it. This is a deliberate checkpoint: if this model is
solid, the routing and transport layers built on it in later steps have
a safe foundation.

---

## Verifying Your Setup

At any point, confirm the current step works before continuing:

```bash
flutter pub get     # dependencies resolve cleanly
flutter analyze      # no static analysis errors
flutter test          # all unit tests pass
flutter run            # app launches without runtime errors
```

If any of these fail, resolve it before adding the next step's files —
each step in this log assumes the previous one is fully working.

---

## Project Conventions

- **Incremental builds.** Each step adds the minimum code needed to
  reach a verifiable checkpoint — no speculative scaffolding for
  features that haven't started yet.
- **Test before you build on it.** Any pure-logic file (models,
  algorithms) gets a unit test before anything else depends on it.
- **Dependencies are added just-in-time.** A package is only declared in
  `pubspec.yaml` in the step that first uses it.

---

## What's Next

**Step 3 — Routing Engine.** `features/mesh_chat/data/routing_service.dart`
will implement the TTL and duplicate-detection logic — the first
component that actually consumes `MeshMessage`, and the algorithmic
core of the mesh network.