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
        before_destroy -> { trash! }, prepend: true
        attr_writer :trashed

        def trash!
          init_journal(User.current, 'チケットを削除しました') # TODO
          save!
          TrashedIssue.copy_from!(self)
        end

        def trashed?
          @trashed.present?
        end
      end
    end
  end
end
