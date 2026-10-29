require "csv"

class AssessmentExport
  HEADERS = %w[assessment_id status created_at score].freeze

  def initialize(relation)
    @relation = relation
  end

  def each_row
    return enum_for(__method__) unless block_given?

    yield CSV.generate_line(HEADERS)
    @relation.find_each(batch_size: 1_000) do |assessment|
      yield CSV.generate_line([
        assessment.id,
        assessment.status,
        assessment.created_at.iso8601,
        AssessmentScore.call(assessment)
      ])
    end
  end
end
