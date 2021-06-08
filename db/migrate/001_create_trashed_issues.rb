# frozen_string_literal: true

class CreateTrashedIssues < ActiveRecord::Migration[5.2]
  def change
    create_table :trashed_issues do |t|
      t.references :project
      t.json :attributes_json
      t.references :deleted_by, type: :integer, foreign_key: { to_table: :users }

      t.timestamps
    end
  end
end
