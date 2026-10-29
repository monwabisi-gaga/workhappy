# Workhappy assessment

A small Rails implementation of a company-scoped assessment dashboard and safe CSV export.

## Run locally

Requirements: Ruby matching `.ruby-version` and SQLite for local development.

```bash
bundle install
bin/rails db:prepare
bin/rails db:seed
bin/rails server
```

Open <http://localhost:3000>, then choose **Open demo dashboard**. The demo session is deliberately not production authentication; a real application must derive the company from an authenticated admin membership.

Run the checks with `bin/rails test`. PostgreSQL is the intended production database; SQLite is used only to keep this assessment runnable without external services.

## End-to-end tests

Install the JavaScript test dependency and browser once:

```bash
npm install
npx playwright install chromium
```

Run the Playwright suite with `npm run test:e2e`. It starts Rails automatically, seeds the local database, and covers dashboard access, future-date limits, status filtering, and redacted CSV downloads.

## Submission notes

Design decisions, assumptions, measurement instructions, status mapping, and release/rollback planning are documented in `SOLUTION.md`. The TypeScript source for the small export interaction is in `app/javascript/export.ts`; the equivalent browser asset is checked in for this minimal no-build setup.
