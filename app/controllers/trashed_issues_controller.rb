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
    # #rebuild sets @issue.attachments to unsaved copies (id is nil) built for
    # the restore flow (see RestoredIssuesController). The view always renders
    # attachments via @trashed.attachments, so clear these out here to avoid
    # mixing them with @trashed.attachments when textilizable merges both
    # lists, which crashes InlineAttachmentsScrubber's sort_by (id nil vs id
    # present with an equal created_on cannot be compared).
    @issue.attachments = []
    @relations = @issue.relations
    @journals = @issue.journals.sort_by(&:created_on)
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
