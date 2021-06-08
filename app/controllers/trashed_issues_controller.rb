# frozen_string_literal: true

class TrashedIssuesController < ApplicationController
  helper :issues
  helper :custom_fields
  helper :attachments
  helper :journals
  helper :watchers

  before_action :set_trashed_issue
  before_action :set_project
  before_action :authorize

  def show
    @issue = @trashed.rebuild
    @relations = @issue.relations
    @journals = @issue.journals
    @journals.each.with_index(1) do |journal, indice|
      journal.indice = indice
    end
  end

  private

  def set_trashed_issue
    @trashed = TrashedIssue.find(params[:id])
  end

  def set_project
    @project = @trashed.project
  end

  def authorize
    return true if @trashed.deleted_by == User.current

    super
  end

  helper_method def render_journal_actions(*args); end
end
