# frozen_string_literal: true

module RedmineIssueTrash
  module UserPatch
    module Include
      extend ActiveSupport::Concern

      included do
        has_many :trashed_issues, foreign_key: :deleted_by_id, dependent: :nullify
      end
    end
  end
end
