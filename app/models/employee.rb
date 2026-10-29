class Employee < ApplicationRecord
  belongs_to :company
  has_many :assessments, dependent: :restrict_with_exception

  validates :email, presence: true
end
