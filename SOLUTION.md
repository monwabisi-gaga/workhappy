# Implementation notes

## Assumptions

The supplied brief does not define authentication, a scoring formula, or a response schema. This slice uses a demo session only for local evaluation. Production authentication must set the company from an authenticated membership, never from request parameters. `responses_json.questions[*].score` is treated as a numeric score; the displayed score is the arithmetic mean of finite values rounded to two decimals. Missing or malformed scores produce “Not available” and are not treated as zero.

## Export and tenant safety

The controller always starts with `current_company.assessments`. It accepts only `from`, `to`, and `status`; date filters are inclusive day boundaries and invalid dates are ignored. Invalid statuses do not broaden the query. CSV output contains only assessment ID, canonical status, timestamp, and derived score. It excludes employee identity and raw answers. `find_each` emits rows in batches. Sensitive response parameters are filtered from Rails logs.

## Performance

The dashboard returns at most 100 rows and selects no raw response payload into the view. The migration adds `(company_id, status, created_at)` and `(company_id, created_at)` indexes for the filtered and unfiltered paths.

No production-sized PostgreSQL dataset was available, so no benchmark is fabricated. Before release, run `EXPLAIN (ANALYZE, BUFFERS)` on an anonymised comparable database for the filtered query, and record planning time, execution time, rows removed by filter, and buffer usage before and after the migration.

## Status rollout

New and updated records are restricted by the model validation and database check constraint. For a legacy table, first inventory values. Map `complete`, `comp`, and `done` to `completed`; retain `in_progress`, `needs_follow_up`, and `archived`; map `nil`, empty, and `n/a` to `pending only after business confirmation`. Unknown values must be reviewed and reported, never guessed. Backfill in primary-key batches with short commits and throttling; do not run a full historical backfill here.

## Release and rollback

1. Capture and verify a platform database backup before deployment.
2. Deploy the additive application and indexes; monitor locks, latency, and errors.
3. Run a read-only status inventory and agree unknown-value mappings.
4. In a low-traffic window, run an idempotent, resumable, throttled batch backfill. Record the last ID.
5. Verify counts, scores, tenant isolation, and query plans before enforcing a constraint on an existing large table. Prefer `NOT VALID` then separate validation in PostgreSQL.
6. Roll back to the prior application release if errors occur. Stop and record a backfill in progress. Preserve additive indexes. For incorrect data, restore the backup to a separate database, validate it, then use the platform recovery procedure; never blindly reverse a partial backfill.

## Deliberate non-goals

This does not rewrite authentication, invent a business scoring formula, export raw health data, or execute the historical backfill.
