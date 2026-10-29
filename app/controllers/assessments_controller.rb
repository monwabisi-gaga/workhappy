class AssessmentsController < ApplicationController
  include CompanyScoped

  def index
    @assessments = filtered_assessments.limit(100)
    @statuses = Assessment::STATUSES
  end

  def export
    response.content_type = "text/csv"
    response.headers["Content-Disposition"] = 'attachment; filename="assessments.csv"'
    response.headers["Cache-Control"] = "no-store"
    self.response_body = AssessmentExport.new(filtered_assessments).each_row
  end

  private

  def filtered_assessments
    current_company.assessments
      .with_status(valid_status)
      .created_on_or_after(parse_date(:from))
      .created_on_or_before(parse_date(:to))
      .order(created_at: :desc)
  end

  def valid_status
    status = params[:status].to_s
    status if Assessment::STATUSES.include?(status)
  end

  def parse_date(key)
    Date.iso8601(params[key].to_s) if params[key].present?
  rescue Date::Error
    nil
  end
end
