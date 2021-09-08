# frozen_string_literal: true

module RedmineIssueTrash
  module IssuePatch
    module Prepend
      def force_updated_on_change
        return if trashed?

        super
      end
    end

    module Include
      extend ActiveSupport::Concern

      included do
        before_destroy -> { TrashedIssue.copy_from(self) }, prepend: true
        attr_writer :trashed

        def trashed?
          @trashed.present?
        end
      end
    end
  end
end
