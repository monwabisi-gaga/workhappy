class DemoSessionsController < ApplicationController
  def create
    company = Company.order(:id).first
    return redirect_to root_path, alert: "Run the seed task first." unless company

    reset_session
    session[:company_id] = company.id
    redirect_to assessments_path, notice: "Signed in as #{company.name}."
  end
end
