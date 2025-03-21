# frozen_string_literal: true

Redmine::Plugin.register :redmine_issue_trash do
  name 'Redmine Issue Trash'
  author 'Agileware Inc.'
  description 'This is a plugin for Redmine'
  author_url 'http://agileware.jp'
  version '1.0.3'

  activity_provider :trashed_issues
  project_module :issue_tracking do
    permission :view_trashed_issues, { trashed_issues: :show }, required: :member
  end
end

Rails.application.config.after_initialize do
  User.include RedmineIssueTrash::UserPatch::Include
  Issue.prepend RedmineIssueTrash::IssuePatch::Prepend
  Issue.include RedmineIssueTrash::IssuePatch::Include
  Project.include RedmineIssueTrash::ProjectPatch::Include
  Redmine::FieldFormat::RecordList.prepend RedmineIssueTrash::RecordListPatch::Prepend
  Redmine::FieldFormat::AttachmentFormat.prepend RedmineIssueTrash::AttachmentFormatPatch::Prepend
end
