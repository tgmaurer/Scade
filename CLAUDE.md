# Scade

SwiftUI grade tracker for macOS/iOS. Full spec: docs/SPEC.md — read it before
starting any feature work.

## Non-negotiables
- No ORM change-tracking. GRDB only, explicit queries, no ambient state.
- Business logic (averages, validation) lives in Sources/Logic/, is unit
  tested, and is never duplicated across call sites.
- If GradeMaster (old MAUI app) is in context: reference for business logic
  and data shape ONLY. Do not follow its project structure, UI patterns, or
  architecture — that's what this rewrite exists to leave behind.

## Conventions
- [testing requirements, formatting, whatever you land on]
