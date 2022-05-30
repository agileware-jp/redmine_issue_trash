# frozen_string_literal: true

class RestoredIssuesController < ApplicationController
  def create
    @trashed = TrashedIssue.find(params[:id])
    @issue = @trashed.rebuild
    @issue.watcher_users = []
    @issue.init_journal(User.current, t(:notes_issue_restored))

    begin
      ActiveRecord::Base.transaction do
        @issue.save!
        # avoid conflict with Journal#add_watcher in Redmine5 or later
        @issue.watcher_users = User.where(id: @issue.watcher_user_ids | @trashed.attributes_json['watcher_user_ids'])
        @trashed.destroy!
      end
      redirect_to @issue, notice: t(:notice_issue_restored)
    rescue ActiveRecord::RecordInvalid
      redirect_to @trashed, flash: { error: @issue.errors.full_messages.join("\n") }
    end
  end
end
