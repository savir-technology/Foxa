# Jeeb Master deployment checklist

## Quick packaging

From the repository root, run `./prepare_master_deployment.ps1`. It creates a
timestamped `deploy/jeeb-master-*` bundle containing the compiled web files,
the required backend files, and the migration without any credentials.

## 1. Upload the backend changes

Upload the complete `backend-roaq/dash/master/` directory from the generated
bundle to the same `roaqv2` backend used by the dashboard. The bundle also
contains the shared files that were hardened for master access:

- `backend/roaq/functions.php`
- `backend/roaq/connect.php`
- `backend/roaq/payments/init_payment.php` and `backend/roaq/payments/.htaccess`
- `backend/roaq/dash/master_auth/verify_signup_code.php`
- `backend/roaq/dash/master_auth/seed_portal_accounts.php`
- `backend/roaq/dash/master_auth/verify_portal_accounts.php`
- `backend/roaq/dash/master_auth/login.php`
- `backend/roaq/dash/master_auth/` (all authentication/session endpoints)
- `backend/roaq/dash/notifications/save_web_push_token.php`
- `backend/roaq/dash/order/assign/assign_driver.php`
- `backend/roaq/dash/master/finance/action.php`
- `backend/roaq/dash/users/get/get_users.php` (shared legacy endpoint; password fields removed)
- `backend/roaq/dash/items/get/get_item_edit_data.php`
- `backend/roaq/dash/items/attributes/save.php`
- `backend/roaq/dash/sections/get/get_categories.php`
- `backend/roaq/dash/items/get/get_items.php`

The bundle also includes `backend/roaq/config/database.php`. The PHP API
expects `ROAQ_DB_HOST`, `ROAQ_DB_PORT`, `ROAQ_DB_NAME`, `ROAQ_DB_USER`, and
`ROAQ_DB_PASSWORD`. If the hosting panel does not expose environment
variables to PHP-FPM, copy `backend/roaq/config/database.local.php.example`
to `config/database.local.php` on the server and replace the placeholders
with the real hosting database credentials. Keep that local file out of
version control.

Do not omit any other file under `dash/master`; the bundle contains 47
production endpoints plus the shared administration helper, all of which are
part of the unified master API surface. `fix_permissions.php` is intentionally
not bundled because it is an internal repair script and is not a web endpoint.

Do not expose `seed_portal_accounts.php` through a web route; it is CLI-only.

## 2. Apply the database migration

Run both migrations once from the backend project directory (in this order):

```bash
mysql -u DATABASE_USER -p DATABASE_NAME < migrations/20260909_master_auth_accounts.sql
mysql -u DATABASE_USER -p DATABASE_NAME < migrations/20261104_master_governance_permissions.sql
```

The second migration registers the supplier-return permissions used by the
governance actions. It is idempotent and safe to rerun.

## 3. Use the existing master account or provision optional defaults

If the database already contains the primary `admin` account with
`admin_role_id = 1`, do **not** run the seed command just to create the six
department accounts. After the migration, that existing account is promoted
to `super_admin` and can create, approve, suspend, and manage employee
accounts from the Master Administration screen.

In that setup, run only the migration and then use the existing master
credentials to sign in. The first master login safely initializes the role and
permission catalogs if they are missing.

The seed command below is optional. Use it only on a clean database or when
the company explicitly wants the six predefined department accounts:

Run on the server, not from a browser:

```bash
export JEEB_MASTER_BOOTSTRAP_PASSWORD='set-this-only-in-your-shell'
php dash/master_auth/seed_portal_accounts.php
php dash/master_auth/verify_portal_accounts.php
```

Use the password agreed by the company in the environment variable; it is not
stored in the PHP file or deployment bundle.

The verifier must print `OK` for all seven accounts and finish with:

```text
All Jeeb Master portal accounts are ready.
```

## 4. Smoke-test the production API

After uploading, run `./verify_master_production.ps1`. To include an
authenticated smoke test, set `JEEB_MASTER_SMOKE_EMAIL` and
`JEEB_MASTER_SMOKE_PASSWORD` only in the local shell first; the script never
prints them.

Without an `Authorization` header, these endpoints must return HTTP `401`:

- `dash/master/home.php`
- `dash/master/orders/list.php`
- `dash/master/finance/overview.php`
- `dash/master/vendors/get_vendors.php`
- `dash/master/users/overview.php`

The legacy shared `dash/users/get/get_users.php` endpoint is expected to keep
its existing vendor-dashboard behavior and return HTTP `200`. Verify that its
JSON does not contain `users_password` or verification codes. Master customer
access is tested through the protected endpoint listed above.

Then log in with a provisioned account and verify that:

- every account opens the shared master home;
- the sidebar is filtered by the account permissions;
- finance can manage financial actions and reports;
- operations can edit delivery zones and fees;
- analytics can read reports but cannot mutate wallets, coupons, or expenses.

The authenticated smoke test also calls `dash/master/deployment_health.php` and
fails if the database is unavailable or any required Master table is missing.

Never paste the production passwords into logs or commit them to the repository.

The API CORS policy is intentionally limited to the production dashboard
origins and localhost development origins. Do not reintroduce wildcard `*`
origins when adding a new endpoint; call `masterSetCorsHeaders()` instead.

## 5. Configure payment secrets outside the repository

The payment initializer reads the Paymob key only from the server environment.
Before enabling card payments, configure `PAYMOB_API_KEY` in the PHP-FPM/Apache
environment and verify that the value is not present in the deployed source.
Debug payment logging is disabled by default; do not enable `PAYMOB_DEBUG_LOG`
in production. Payment log files are denied by the bundled `.htaccess` rule and
must never be publicly downloadable.
