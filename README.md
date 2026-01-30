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

  * AR session setup
  * World tracking and plane detection
  * Raycasting‑based object placement
  * Scene anchoring and lifecycle management

* **Spatial correctness**

  * World mapping and surface alignment
  * Occlusion‑aware placement paths
  * Lighting estimation for visual consistency

* **Rendering performance**

  * Efficient RealityKit entity management
  * Safe update paths for multiple simultaneous assets
  * Interactive frame rates under dynamic scene updates

* **Extensibility by design**

  * Modular AR view containers
  * Isolated gesture and interaction handling
  * Clear separation between UI, rendering, and data layers

---

## Architecture Overview

Renovix follows a layered architecture intended to scale beyond a prototype:

* **UI Layer**

  * SwiftUI‑driven views
  * Declarative state management
  * UIKit bridges where system frameworks require delegation

* **AR & Rendering Layer**

  * ARKit for spatial tracking and environment understanding
  * RealityKit for high‑level rendering, lighting, and interaction
  * SceneKit compatibility where lower‑level control is beneficial

* **Interaction Layer**

  * Raycasting‑based placement
  * Modular gesture handling
  * Scene‑safe update logic

* **Data & Domain Layer**

  * Repository‑driven access patterns
  * Dependency‑injected components
  * Mock‑friendly data sources for testability

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

* **Language**: Swift
* **UI**: SwiftUI
* **AR & Rendering**: ARKit, RealityKit, SceneKit
* **Animation**: Core Animation
* **Concurrency**: Swift Concurrency (async/await)
* **Architecture**: Repository pattern, dependency injection

---

## Status

Renovix is under active development, with a focus on stability, extensibility, and production‑aligned design decisions.
