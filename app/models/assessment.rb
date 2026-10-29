class Assessment < ApplicationRecord
  STATUSES = %w[pending in_progress completed needs_follow_up archived].freeze

  belongs_to :company
  belongs_to :employee

  validates :status, inclusion: { in: STATUSES }
  validate :employee_must_belong_to_company

  scope :with_status, ->(status) { where(status:) if STATUSES.include?(status) }
  scope :created_on_or_after, ->(date) { where(created_at: date.beginning_of_day..) if date }
  scope :created_on_or_before, ->(date) { where(created_at: ..date.end_of_day) if date }

  private

  def employee_must_belong_to_company
    return if employee.blank? || company.blank? || employee.company_id == company_id

    errors.add(:employee, "must belong to the assessment company")
  end
end
