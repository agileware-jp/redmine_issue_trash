# frozen_string_literal: true

module RedmineIssueTrash
  module ProjectPatch
    module Include
      extend ActiveSupport::Concern

      included do
        has_many :trashed_issues, dependent: :destroy
      end
    end
  end
end
