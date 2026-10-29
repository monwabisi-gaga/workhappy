# Implementation notes

## Assumptions

The supplied brief does not define authentication, a scoring formula, or a response schema. This slice uses a demo session only for local evaluation. Production authentication must set the company from an authenticated membership, never from request parameters. `responses_json.questions[*].score` is treated as a numeric score; the displayed score is the arithmetic mean of finite values rounded to two decimals. Missing or malformed scores produce “Not available” and are not treated as zero.

## Export and tenant safety

The controller always starts with `current_company.assessments`. It accepts only `from`, `to`, and `status`; date filters are inclusive day boundaries and invalid dates are ignored. Invalid statuses do not broaden the query. CSV output contains only assessment ID, canonical status, timestamp, and derived score. It excludes employee identity and raw answers. `find_each` emits rows in batches. Sensitive response parameters are filtered from Rails logs.

## Performance

The dashboard returns at most 100 rows and computes each score once in the controller; the template receives only the derived score, rather than traversing response data itself. The migration adds `(company_id, status, created_at)` and `(company_id, created_at)` indexes for the filtered and unfiltered paths.

The measurable comparison is the dashboard query with and without the 100-row cap and these indexes: run `EXPLAIN (ANALYZE, BUFFERS)` on the filtered query against an anonymised production-sized PostgreSQL copy, recording planning time, execution time, rows removed by filter, and shared buffer hits/reads in both runs. The expected improvement is bounded result work plus indexed tenant/status/date lookup; the release record must contain the actual before/after timings rather than an invented benchmark. The local SQLite dataset is intentionally not used as a production performance claim.

## Status rollout

New and updated records are restricted by the model validation and database check constraint. For a legacy table, first inventory values. Map `complete`, `comp`, and `done` to `completed`; retain `in_progress`, `needs_follow_up`, and `archived`; map `nil`, empty, and `n/a` to `pending only after business confirmation`. Unknown values must be reviewed and reported, never guessed. Backfill in primary-key batches with short commits and throttling; do not run a full historical backfill here.

## Release and rollback

1. **Before deployment:** capture a platform database backup/snapshot, wait for it to complete, and verify its identifier and restore metadata. Confirm the rollback release and recovery owner.
2. **Safe while live:** deploy the additive application validation and logging changes. Monitor error rate, latency, and lock waits.
3. **Safe while live:** run a read-only status inventory and agree unknown-value mappings. Create the two indexes concurrently in PostgreSQL (`disable_ddl_transaction!` plus `algorithm: :concurrently`) so the large table is not stalled; schedule the index work if the platform cannot run concurrent DDL.
4. **Low-traffic window:** pause or coordinate writers if required by the chosen backfill mechanism, then run an idempotent, resumable, throttled primary-key batch backfill. Commit each short batch and record the last ID. Do not execute this historical backfill as part of application boot or migration.
5. **Safe while live after backfill:** verify counts, scores, tenant isolation, and query plans. Add the final status constraint as `NOT VALID`, then validate it separately; use a low-traffic window if validation duration or lock behavior requires it.
6. **Rollback:** if application errors occur, roll back to the prior application release. Stop and record any backfill progress; preserve additive indexes. For incorrect data, restore the backup to a separate database, validate it, then use the platform recovery procedure—never blindly reverse a partial backfill.

## Deliberate non-goals

This does not rewrite authentication, invent a business scoring formula, export raw health data, or execute the historical backfill.
