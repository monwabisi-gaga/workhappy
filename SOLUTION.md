# Implementation notes

## Assumptions

The supplied brief does not define authentication, a scoring formula, or a response schema. This slice uses a demo session only for local evaluation. Production authentication must set the company from an authenticated membership, never from request parameters. `responses_json.questions[*].score` is treated as a numeric score; the displayed score is the arithmetic mean of finite values rounded to two decimals. Missing or malformed scores produce “Not available” and are not treated as zero.

## Export and tenant safety

The controller always starts with `current_company.assessments`. It accepts only `from`, `to`, and `status`; date filters are inclusive day boundaries and invalid dates are ignored. Invalid statuses do not broaden the query. CSV output contains only assessment ID, canonical status, timestamp, and derived score. It excludes employee identity and raw answers. `find_each` emits rows in batches. Sensitive response parameters are filtered from Rails logs.

## PostgreSQL and performance

Development and test use PostgreSQL through the `pg` adapter. Set `PGUSER`, `PGPASSWORD`, `PGHOST`, `PGPORT`, `PGDATABASE`, and `PGTESTDATABASE` when local defaults do not apply. The CI test and E2E jobs run against PostgreSQL services.

The dashboard returns at most 100 rows and computes each score once in the controller; the template receives only the derived score, rather than traversing response data itself. The migration adds `(company_id, status, created_at)` and `(company_id, created_at)` indexes for the filtered and unfiltered paths.

`script/benchmark_dashboard.rb` creates a dedicated benchmark database table with 250,000 synthetic rows across 25 companies, runs `ANALYZE`, captures a baseline without the dashboard indexes or result limit, adds the two indexes, then captures the dashboard-shaped query with `LIMIT 100`. It writes the raw `EXPLAIN (ANALYZE, BUFFERS)` output to a local report. It does not touch the development/test databases and does not execute a historical status backfill.

### Recorded benchmark

Command:

```bash
BENCHMARK_DATABASE_URL=postgres://postgres:postgres@127.0.0.1:5432/workhappy_benchmark \
  BENCHMARK_ROWS=250000 BENCHMARK_COMPANIES=25 \
  bundle exec ruby script/benchmark_dashboard.rb
```

Dataset: 250,000 synthetic rows, 25 companies, five canonical statuses, and timestamps distributed over 730 days. Query target: company 3, completed assessments from the last 90 days.

The complete raw output is retained in `benchmark/dashboard_explain.txt` and was generated locally against PostgreSQL 16. The summary below is copied from that run; timings and buffer counts are not estimates:

<!-- BENCHMARK_RESULTS_START -->
PostgreSQL 16.15, generated 2026-10-29T12:25:23Z:

| Shape | Plan | Actual rows | Planning time | Execution time | Buffers |
| --- | --- | ---: | ---: | ---: | --- |
| No dashboard indexes and no `LIMIT` | Parallel sequential scan + sort | 1,234 | 0.108 ms | 8.570 ms | 3,919 shared hits |
| Composite indexes and `LIMIT 100` | Backward index scan on `benchmark_assessments_on_company_status_created_at` | 100 | 0.135 ms | 0.144 ms | 100 shared hits, 3 reads |

The baseline removed 82,922 rows by filter. The indexed plan stopped after the first 100 ordered matches. The complete plans, including worker counts and sort details, are in `benchmark/dashboard_explain.txt`.
<!-- BENCHMARK_RESULTS_END -->

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
