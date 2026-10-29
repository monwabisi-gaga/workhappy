alpha = Company.find_or_create_by!(name: "Acme Health")
beta = Company.find_or_create_by!(name: "Other Company")

employee = alpha.employees.find_or_create_by!(email: "private@example.test")
alpha.assessments.find_or_create_by!(employee:, status: "completed") do |assessment|
  assessment.responses_json = { "questions" => [{ "score" => 80 }, { "score" => 90 }] }
end
alpha.assessments.find_or_create_by!(employee:, status: "in_progress") do |assessment|
  assessment.responses_json = { "questions" => [{ "score" => 60 }] }
end

other_employee = beta.employees.find_or_create_by!(email: "other@example.test")
beta.assessments.find_or_create_by!(employee: other_employee, status: "completed") do |assessment|
  assessment.responses_json = { "questions" => [{ "score" => 10 }] }
end
