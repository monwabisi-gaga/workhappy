module CompanyScoped
  extend ActiveSupport::Concern

  included do
    before_action :require_company
    helper_method :current_company
  end

  private

  def current_company
    @current_company ||= Company.find_by(id: session[:company_id])
  end

  def require_company
    return if current_company

    redirect_to root_path, alert: "Please sign in as a company administrator."
  end
end
