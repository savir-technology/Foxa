# Checkout load test

This test targets the real checkout endpoint used by `frontend/savir604`:

`orders/checkout.php`

It sends one checkout per virtual user. The endpoint reads the user's server-side
cart, creates the order, creates its order items/vendor orders, then clears the
cart. Therefore, every test user must have exactly one prepared test cart.

## Safety

Run only against a staging copy of the backend and database. Do not use real
payment credentials, real customer accounts, or production carts. The script
blocks the known production hostname unless `ALLOW_PRODUCTION=YES` is supplied.

## Install k6

Install k6 from the official package for the machine running the test, then
verify it with:

```powershell
k6 version
```

## Run a 100-user baseline

`USER_START_ID` is the first ID in a contiguous block of seeded test users.
For 100 users, seed IDs `50001` through `50100`, each with one cart item.

On the staging database, the disposable users and carts can be prepared with
`loadtest/prepare_staging.sql`. Change `@seed_user_count` before running it for
larger bursts. The script is explicitly staging-only.

```powershell
k6 run `
  -e BASE_URL=https://staging.example.com/roaqv2 `
  -e USER_START_ID=50001 `
  -e VUS=100 `
  .\loadtest\checkout.js
```

## Run the 1,000-order burst

Use a fresh block of users/carts because checkout deletes each cart after a
successful order:

```powershell
k6 run `
  -e BASE_URL=https://staging.example.com/roaqv2 `
  -e USER_START_ID=51001 `
  -e VUS=1000 `
  -e MAX_DURATION=10m `
  .\loadtest\checkout.js
```

The 1000 virtual users issue one request each. They start as close together as
the load-generator and network allow; this is a burst test, not a claim that
all packets arrive in the exact same CPU tick.

For repeatable staging runs, use the guarded PowerShell wrapper:

```powershell
.\loadtest\run-staging-burst.ps1 `
  -BaseUrl https://staging.example.com/roaqv2 `
  -UserStartId 51001 `
  -Vus 1000 `
  -MaxDuration 10m
```

## What to verify after each run

- The expected number of new orders exists in the test database.
- Every successful response has a unique `order_id`.
- No user's cart was converted twice.
- `orders`, `order_items`, and `vendor_orders` counts agree.
- The API error rate and p95/p99 latency meet the thresholds in the script.
- PHP-FPM/Apache workers, MySQL connections, CPU, RAM, and disk are not
  exhausted.
- Run `loadtest/verify_checkout.sql` on staging and confirm that only
  `orders_created` is non-zero and has the expected count.

Do not judge the result from HTTP status alone: verify the database and the
business invariants after the run.

## Optional notification outbox

After applying `backend/roaq/migrations/20261020_notification_outbox.sql` on
staging, set `ROAQ_NOTIFICATION_OUTBOX=1` and run
`backend/roaq/notifications/outbox_worker.php` from a supervised scheduler.
Verify that pending events are drained and that `failed` remains zero before
using the setting in production.
Use `loadtest/verify_outbox.sql` as the post-run check.
