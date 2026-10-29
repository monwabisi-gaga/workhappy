require "test_helper"

class AssessmentTest < ActiveSupport::TestCase
  setup do
    @company = Company.create!(name: "Test company")
    @employee = @company.employees.create!(email: "employee@example.test")
  end

  test "allows only canonical statuses" do
    assessment = @company.assessments.new(employee: @employee, status: "complete")
    assert_not assessment.valid?
    assert_includes assessment.errors[:status], "is not included in the list"
  end

  test "prevents an employee from another company" do
    other_company = Company.create!(name: "Other company")
    other_employee = other_company.employees.create!(email: "other@example.test")
    assessment = @company.assessments.new(employee: other_employee, status: "pending")
    assert_not assessment.valid?
    assert_includes assessment.errors[:employee], "must belong to the assessment company"
  end

  test "averages finite numeric scores and ignores malformed values" do
    assessment = @company.assessments.create!(employee: @employee, responses_json: { "questions" => [{ "score" => 80 }, { "score" => "90" }, { "score" => "bad" }] })
    assert_equal 85.0, AssessmentScore.call(assessment)
  end

  test "returns nil when no usable scores exist" do
    assessment = @company.assessments.create!(employee: @employee, responses_json: { "questions" => [{ "score" => "bad" }] })
    assert_nil AssessmentScore.call(assessment)
  end
end
