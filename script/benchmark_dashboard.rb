#!/usr/bin/env ruby

require "pg"
require "fileutils"
require "time"

database_url = ENV.fetch("BENCHMARK_DATABASE_URL") do
  abort "BENCHMARK_DATABASE_URL is required (use a dedicated PostgreSQL benchmark database)"
end
rows = Integer(ENV.fetch("BENCHMARK_ROWS", "250000"), 10)
company_count = Integer(ENV.fetch("BENCHMARK_COMPANIES", "25"), 10)
report_path = ENV.fetch("BENCHMARK_REPORT", "tmp/benchmark_dashboard.txt")

connection = PG.connect(database_url)
connection.transaction do |db|
  db.exec("DROP TABLE IF EXISTS assessments")
  db.exec(<<~SQL)
    CREATE TABLE assessments (
      id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
      company_id integer NOT NULL,
      status varchar NOT NULL,
      created_at timestamp NOT NULL,
      responses_json jsonb NOT NULL DEFAULT '{}'::jsonb
    )
  SQL
  db.exec_params(<<~SQL, [rows, company_count])
    INSERT INTO assessments (company_id, status, created_at, responses_json)
    SELECT
      ((series - 1) % $2) + 1,
      (ARRAY['pending', 'in_progress', 'completed', 'needs_follow_up', 'archived'])[((series - 1) % 5) + 1],
      now() - ((series % 730) * interval '1 day'),
      '{"questions":[{"score":80}]}'::jsonb
    FROM generate_series(1, $1) AS series
  SQL
  db.exec("ANALYZE assessments")
end

query_without_indexes_or_limit = <<~SQL
  EXPLAIN (ANALYZE, BUFFERS, COSTS)
  SELECT id, status, created_at
  FROM assessments
  WHERE company_id = 3
    AND status = 'completed'
    AND created_at >= now() - interval '90 days'
  ORDER BY created_at DESC
SQL

query_with_indexes_and_limit = <<~SQL
  EXPLAIN (ANALYZE, BUFFERS, COSTS)
  SELECT id, status, created_at
  FROM assessments
  WHERE company_id = 3
    AND status = 'completed'
    AND created_at >= now() - interval '90 days'
  ORDER BY created_at DESC
  LIMIT 100
SQL

connection.exec("DROP INDEX IF EXISTS benchmark_assessments_on_company_created_at")
connection.exec("DROP INDEX IF EXISTS benchmark_assessments_on_company_status_created_at")
connection.exec("ANALYZE assessments")
before = connection.exec(query_without_indexes_or_limit).column_values(0).join("\n")

connection.exec("CREATE INDEX benchmark_assessments_on_company_created_at ON assessments (company_id, created_at)")
connection.exec("CREATE INDEX benchmark_assessments_on_company_status_created_at ON assessments (company_id, status, created_at)")
connection.exec("ANALYZE assessments")
after = connection.exec(query_with_indexes_and_limit).column_values(0).join("\n")

FileUtils.mkdir_p(File.dirname(report_path))
File.write(report_path, <<~REPORT)
    # Dashboard benchmark
    # Generated: #{Time.now.utc.iso8601}
    # PostgreSQL: #{connection.exec("SHOW server_version").first["server_version"]}
    # Rows: #{rows}; companies: #{company_count}
    # Dataset is synthetic/anonymized. No application or historical status backfill was run.
    # Before: no dashboard indexes and no LIMIT (baseline work).
    # After: company/status/date indexes and LIMIT 100 (dashboard shape).

    ## BEFORE
    #{before}

    ## AFTER
    #{after}
  REPORT

puts "Wrote #{report_path}"
