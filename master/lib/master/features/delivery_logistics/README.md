# Delivery Logistics Feature

This feature follows an MVC-style layout while the wider dashboard is still
being migrated away from the legacy single-file structure.

## Structure

- `models/`
  Data objects parsed from the backend.
- `controllers/`
  State, filters, loading, assignment actions, and API access.
- `views/pages/`
  Route-level Flutter pages.
- `views/workspaces/`
  Page composition/layout widgets.
- `views/widgets/`
  Reusable cards, tables, sidebar, map, and controls.

## Current Integration Note

The files are currently connected with Dart `part` directives because the
legacy dashboard still keeps shared private helpers in `master_auth_app.dart`.
As more dashboard areas are migrated, these parts can be promoted to normal
imports with public shared components.
