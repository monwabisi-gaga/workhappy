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

## Submission notes

Design decisions, assumptions, measurement instructions, status mapping, and release/rollback planning are documented in `SOLUTION.md`. The TypeScript source for the small export interaction is in `app/javascript/export.ts`; the equivalent browser asset is checked in for this minimal no-build setup.
