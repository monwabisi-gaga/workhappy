require "test_helper"
require "csv"

class AssessmentsTest < ActionDispatch::IntegrationTest
  setup do
    @company = Company.create!(name: "Allowed")
    @other_company = Company.create!(name: "Not allowed")
    @employee = @company.employees.create!(email: "secret@example.test")
    @other_employee = @other_company.employees.create!(email: "other@example.test")
    @assessment = @company.assessments.create!(employee: @employee, status: "completed", responses_json: { "questions" => [{ "score" => 100 }] })
    @other_assessment = @other_company.assessments.create!(employee: @other_employee, status: "completed", responses_json: { "questions" => [{ "score" => 1 }] })
  end

  test "requires a company session" do
    get assessments_path
    assert_redirected_to root_path
  end

  test "date filters cannot select a future date" do
    post demo_sign_in_path
    get assessments_path
    assert_response :success
    assert_select "input[type=date][name='from'][max='#{Date.current}']", count: 1
    assert_select "input[type=date][name='to'][max='#{Date.current}']", count: 1
  end

  test "export is scoped and redacts identity and raw responses" do
    post demo_sign_in_path
    get export_assessments_path
    assert_response :success
    assert_equal "text/csv", response.media_type
    assert_equal %w[assessment_id status created_at score], CSV.parse(response.body, headers: true).headers
    exported_ids = CSV.parse(response.body, headers: true).map { |row| row["assessment_id"].to_i }
    assert_equal [@assessment.id], exported_ids
    assert_not_includes response.body, "secret@example.test"
    assert_not_includes response.body, "questions"
    assert_equal [@assessment.id], exported_ids
  end

  test "filters export by canonical status and inclusive dates" do
    post demo_sign_in_path
    @company.assessments.create!(employee: @employee, status: "pending", created_at: Time.zone.parse("2026-01-02 12:00"))
    get export_assessments_path, params: { from: "2026-01-02", to: "2026-01-02", status: "pending" }
    rows = CSV.parse(response.body, headers: true)
    assert_equal ["pending"], rows.map { |row| row["status"] }
  end

  test "invalid filters do not broaden tenant query" do
    post demo_sign_in_path
    get export_assessments_path, params: { from: "not-a-date", status: "done" }
    exported_ids = CSV.parse(response.body, headers: true).map { |row| row["assessment_id"].to_i }
    assert_equal [@assessment.id], exported_ids
    assert_not_includes exported_ids, @other_assessment.id
  end

  test "malformed responses do not crash the dashboard or leak into CSV" do
    malformed = @company.assessments.create!(
      employee: @employee,
      status: "archived",
      responses_json: {
        "questions" => [{ "score" => "not-a-number", "answer" => "sensitive free text" }, { "score" => nil }],
        "free_text" => "sensitive free text"
      }
    )
    post demo_sign_in_path

    get assessments_path
    assert_response :success
    assert_includes response.body, "Not available"

    get export_assessments_path
    row = CSV.parse(response.body, headers: true).find { |candidate| candidate["assessment_id"] == malformed.id.to_s }
    assert_not_nil row
    assert_nil row["score"]
    assert_not_includes response.body, "sensitive free text"
    assert_not_includes response.body, "not-a-number"
  end
end
