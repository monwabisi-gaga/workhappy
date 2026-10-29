class CreateAssessmentTables < ActiveRecord::Migration[8.1]
  def change
    create_table :companies do |t|
      t.string :name, null: false
      t.timestamps
    end

    create_table :employees do |t|
      t.references :company, null: false, foreign_key: true
      t.string :email, null: false
      t.timestamps
    end

    create_table :assessments do |t|
      t.references :company, null: false, foreign_key: true
      t.references :employee, null: false, foreign_key: true
      t.string :status, null: false, default: "pending"
      t.json :responses_json, null: false, default: {}
      t.timestamps
    end

    add_check_constraint :assessments, "status IN ('pending', 'in_progress', 'completed', 'needs_follow_up', 'archived')", name: "assessments_status_canonical"
    add_index :assessments, [:company_id, :created_at], name: "index_assessments_on_company_and_created_at"
    add_index :assessments, [:company_id, :status, :created_at], name: "index_assessments_on_company_status_created_at"
  end
end
