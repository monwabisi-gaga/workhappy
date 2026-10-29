# Workhappy assessment

A small Rails implementation of a company-scoped assessment dashboard and safe CSV export.

## Run locally

Requirements: Ruby matching `.ruby-version`, PostgreSQL 16+, and Node.js 22+ for E2E tests. PostgreSQL is used for both development and test; SQLite is not supported by the application configuration.

Create a local PostgreSQL role/database, or start the equivalent Docker service:

```bash
docker run --name workhappy-postgres \
  -e POSTGRES_USER=postgres -e POSTGRES_PASSWORD=postgres \
  -p 5432:5432 -d postgres:16
export PGUSER=postgres PGPASSWORD=postgres
```

```bash
bundle install
npm install
npm run build
bin/rails db:prepare
bin/rails db:seed
bin/rails server
```

Open <http://localhost:3000>, then choose **Open demo dashboard**. The demo session is deliberately not production authentication; a real application must derive the company from an authenticated admin membership.

Run the checks with `bin/rails test`. `bin/dev` and `bin/setup` build the TypeScript asset automatically; run `npm run build` directly after changing `app/javascript/export.ts`. `app/assets/javascripts/export.js` is generated output—edit the TypeScript source, not the compiled asset.

## PostgreSQL benchmark

The benchmark uses a separate database and synthetic, anonymized rows. It compares the dashboard query without its indexes and `LIMIT 100` against the dashboard query with both indexes and the 100-record limit. It does not run the historical status backfill.

```bash
createdb workhappy_benchmark
BENCHMARK_DATABASE_URL=postgres://postgres:postgres@127.0.0.1:5432/workhappy_benchmark \
  bundle exec ruby script/benchmark_dashboard.rb
```

The generated report is written to `tmp/benchmark_dashboard.txt` (ignored locally). The measured run committed with this project is reproduced in `SOLUTION.md`.

Recorded PostgreSQL 16.15 run (250,000 rows, 25 companies):

| Shape | Plan | Rows | Execution time | Buffers |
| --- | --- | ---: | ---: | --- |
| No indexes, no limit | Parallel sequential scan + sort | 1,234 | 8.570 ms | 3,919 shared hits |
| Both indexes, `LIMIT 100` | Backward composite index scan | 100 | 0.144 ms | 100 shared hits, 3 reads |

These are measurements from the committed synthetic benchmark report, not production promises. The benchmark intentionally changes both the indexes and the dashboard's 100-row limit, so it isolates the combined improvement rather than claiming either change alone caused the full difference.

## End-to-end tests

Install the JavaScript test dependency and browser once:

```bash
npm install
npx playwright install chromium
```

Run the Playwright suite with `npm run test:e2e`. It starts Rails automatically, seeds the local database, and covers dashboard access, future-date limits, status filtering, and redacted CSV downloads.

## Submission notes

Design decisions, assumptions, measurement instructions, status mapping, and release/rollback planning are documented in `SOLUTION.md`. The TypeScript source for the small export interaction is in `app/javascript/export.ts`; the equivalent browser asset is checked in for this minimal no-build setup.
