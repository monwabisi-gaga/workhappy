class AssessmentScore
  def self.call(assessment)
    scores = Array(assessment.responses_json&.fetch("questions", nil)).filter_map do |question|
      next unless question.is_a?(Hash)

      value = question["score"]
      number = Float(value, exception: false)
      number if number&.finite?
    end

    scores.empty? ? nil : (scores.sum / scores.length).round(2)
  end
end
