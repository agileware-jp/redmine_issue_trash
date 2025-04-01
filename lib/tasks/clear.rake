# frozen_string_literal: true

namespace :redmine_issue_trash do
  task clear: :environment do
    days = ENV['days'].presence&.to_i || 30

    trashed_issues = TrashedIssue.where('created_at <= ?', days.days.ago)
    return unless trashed_issues

    ActiveRecord::Base.transaction do
      attachment_ids = trashed_issues.map do |trashed|
        trashed.rebuild.custom_field_values.map do |cfv|
          next unless cfv.custom_field.field_format == 'attachment'
          cfv.value
        end
      end.flatten.compact.uniq
      Attachment.where(id: attachment_ids).delete_all if attachment_ids

      trashed_issues.destroy_all
    end
  end
end
