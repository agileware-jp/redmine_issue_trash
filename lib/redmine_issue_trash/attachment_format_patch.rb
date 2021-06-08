# frozen_string_literal: true

module RedmineIssueTrash
  module AttachmentFormatPatch
    module Prepend
      def set_custom_field_value_by_id(custom_field, custom_field_value, id)
        customized = custom_field_value.customized
        return super unless customized.is_a?(Issue) && customized.trashed? && id.present?

        id.to_s
      end

      def cast_single_value(custom_field, value, customized = nil)
        return super unless customized.is_a?(Issue) && customized.trashed? && value.present?

        TrashedCustomValue.find_by(source_attachment_id: value)&.attachments&.first
      end
    end
  end
end
