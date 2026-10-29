class Company < ApplicationRecord
  has_many :employees, dependent: :destroy
  has_many :assessments, dependent: :destroy
end
