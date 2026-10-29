alpha = Company.find_or_create_by!(name: "Acme Health")
beta = Company.find_or_create_by!(name: "Other Company")

employee = alpha.employees.find_or_create_by!(email: "private@example.test")

assessment_payloads = {
  "pending" => { "questions" => [{ "score" => 75 }] },
  "in_progress" => { "questions" => [{ "score" => 60 }] },
  "completed" => { "questions" => [{ "score" => 80 }, { "score" => 90 }] },
  "needs_follow_up" => { "questions" => [{ "score" => 45 }] },
  # Deliberately malformed: the score service ignores these values safely.
  "archived" => {
    "questions" => [{ "score" => "not-a-number", "answer" => "sensitive free text" }, { "score" => nil }],
    "free_text" => "sensitive free text"
  }
}

assessment_payloads.each do |status, responses_json|
  assessment = alpha.assessments.find_or_initialize_by(employee:, status:)
  assessment.responses_json = responses_json
  assessment.save!
end

other_employee = beta.employees.find_or_create_by!(email: "other@example.test")
beta.assessments.find_or_create_by!(employee: other_employee, status: "completed") do |assessment|
  assessment.responses_json = { "questions" => [{ "score" => 10 }] }
end
