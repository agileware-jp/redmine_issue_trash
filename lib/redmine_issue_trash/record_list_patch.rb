# frozen_string_literal: true

module RedmineIssueTrash
  module RecordListPatch
    module Prepend
      def cast_single_value(custom_field, value, customized = nil)
        return super unless customized.is_a?(Issue) && customized.trashed? && value.present?

        record = target_class.find_by(id: value)
        return record if record.present?

        case target_class.to_s
        when 'User'
          User.anonymous
        when 'Version'
          Version.new(id: value, project: customized.project,
                      name: "#{I18n.t(:missing_record_prefix)} #{I18n.t(:field_version)}")
        when 'CustomFieldEnumeration'
          CustomFieldEnumeration.new(name: "#{I18n.t(:missing_record_prefix)} #{I18n.t(:label_enumerations)}")
        end
      end
    end
  end
end
