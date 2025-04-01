# frozen_string_literal: true

module RedmineIssueTrash
  module CustomizablePatch
    module Prepend
      def destroy_custom_value_attachments
        # no-op
      end
    end
  end
end

