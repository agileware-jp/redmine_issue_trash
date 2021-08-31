# frozen_string_literal: true

class RestoredIssuesController < ApplicationController
  def create
    @trashed = TrashedIssue.find(params[:id])
    @issue = @trashed.rebuild
    @issue.init_journal(User.current, 'チケットを復元しました') # TODO

    begin
      ActiveRecord::Base.transaction do
        @issue.save!
        @trashed.destroy!
      end
      redirect_to @issue, notice: 'success' # TODO
    rescue ActiveRecord::RecordInvalid
      redirect_to @trashed, flash: { error: 'error' } # TODO
    end
  end
end
