# Master Dashboard Structure

The master dashboard is split by feature using an MVC-friendly layout.

## Layout

- `core/`: API clients, shared parsing and formatting utilities.
- `shared/`: reusable widgets that are not owned by one feature.
- `features/auth/`: login, signup, verification, and password reset views.
- `features/dashboard_home/`: main owner dashboard home.
- `features/operations/`: operations center, live activity, tracking, map widgets, and operations models.
- `features/orders/`: orders pages, order statuses, scheduled orders, pickup orders, printing/invoices, order chats, and shared order widgets.
- `features/delivery_logistics/`: delivery and logistics dashboard pages, controllers, models, and widgets.

## Current Bridge

These files currently use Dart `part` files under `master_auth_app.dart` so the existing private helpers and private widget names keep working without a risky rewrite. New work should still be added inside the relevant feature folder, and future cleanup can gradually replace private cross-feature dependencies with public controllers, models, and shared widgets.
