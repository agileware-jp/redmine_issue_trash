# frozen_string_literal: true

class CreateTrashedCustomValues < ActiveRecord::Migration[5.2]
  def change
    create_table :trashed_custom_values do |t|
      t.references :trashed_issue
      t.integer :source_attachment_id

      t.timestamps
    end
  end
end
