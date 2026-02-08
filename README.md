# Renovix

Renovix is an **AR-first iOS application** focused on real‑world spatial visualization of furniture and interior elements. The project explores how modern iOS AR stacks can be composed into a **production‑grade interaction pipeline**, balancing real‑time rendering, spatial accuracy, and extensible architecture.

Rather than positioning itself as a polished consumer product, Renovix is intentionally built as a **systems-oriented AR application** — prioritizing correctness, performance, and long‑term scalability over surface‑level features.

---

## What Renovix Is About

Renovix allows users to:

* Browse interior and furniture products through a lightweight SwiftUI interface
* Preview 3D assets using system‑level Quick Look
* Place and inspect objects in real‑world environments using AR
* Evaluate scale, lighting, and spatial fit before decision‑making

The core emphasis is on **how AR systems are structured**, not just how they look.

---

## Technical Focus

Renovix is designed to mirror **real production ARKit workflows**, with attention to the same constraints faced by shipping AR applications:

* **End‑to‑end AR interaction pipeline**

  * AR session setup with coaching overlay
  * Horizontal/vertical plane detection with visualization
  * Raycasting‑based object placement with floor snapping
  * Ghost preview with real-time gesture manipulation

* **Interactive AR Controls**

  * **Tap** to place ghost preview
  * **Pan** to slide object on detected surfaces
  * **Pinch** to scale objects
  * **Rotate** to adjust orientation
  * **Two-finger vertical pan** to adjust height

* **Persistence & Data**

  * CoreData-backed storage for placed items
  * Repository pattern with dependency injection
  * Position, rotation, and scale persistence across sessions

* **Rendering performance**

  * Centralized `ModelLoader` service with caching
  * SceneKit-based AR rendering with ARSCNView
  * Efficient ghost node management during placement

* **Testability**

  * Unit tests for ViewModels (`ARViewModelTests`, `ProductViewModelTests`)
  * Mock repositories for isolated testing
  * Swift Testing framework integration

---

## Architecture Overview

Renovix follows a layered architecture intended to scale beyond a prototype:

* **UI Layer**

  * SwiftUI‑driven views
  * Declarative state management
  * UIKit bridges where system frameworks require delegation

* **AR & Rendering Layer**

  * ARKit for spatial tracking and environment understanding
  * SceneKit (ARSCNView) for 3D rendering and object placement
  * `ModelLoader` service for centralized USDZ asset loading

* **Interaction Layer**

  * Raycasting‑based placement
  * Modular gesture handling
  * Scene‑safe update logic

* **Data & Domain Layer**

  * CoreData for persistence (`PlacedItem`)
  * Repository pattern (`ARItemRepository`, `ProductRepository`)
  * `AppContainer` for dependency injection
  * Mock-friendly data sources for testability

This structure ensures that UI changes, data sources, and AR behavior can evolve independently.

---

## Implementation Progress

Renovix has evolved through **incremental, intentional phases**, each reinforcing architectural stability rather than feature count.

Current development emphasizes:

* Architectural stabilization
* Clean separation of responsibilities
* UI restructuring aligned with AR‑first interaction models
* Robust handling of real‑world AR constraints

The project is actively structured to support:

* Future networking integration
* Persistent scene storage
* Expanded interaction models
* Advanced AR features without rework

---

## Assets & Models

This repository intentionally excludes heavy 3D assets (`.usdz`, `.reality`) due to size and licensing considerations.

The AR pipeline is designed to:

* Load models dynamically
* Fail gracefully when assets are unavailable
* Use placeholder geometry to preserve behavior and demonstrate system flow

This keeps the repository lightweight while preserving architectural integrity.

---

## Why Renovix

Renovix is not a UI experiment or a one‑off demo.

It is a **technical exploration of AR system design on iOS**, demonstrating:

* Practical use of ARKit and RealityKit in non‑trivial flows
* Performance‑aware rendering strategies
* Modular, extensible code organization
* Real‑world engineering tradeoffs faced in production AR apps

The project is intentionally positioned to reflect how AR features are **engineered**, not merely showcased.

---

## Tech Stack

* **Language**: Swift 5.9+
* **UI**: SwiftUI
* **AR & Rendering**: ARKit, SceneKit
* **Persistence**: CoreData
* **Concurrency**: Swift Concurrency (async/await)
* **Testing**: Swift Testing framework
* **Architecture**: MVVM, Repository pattern, Dependency Injection

---

## Status

Renovix is under active development, with a focus on stability, extensibility, and production‑aligned design decisions.
