# frozen_string_literal: true

require File.expand_path('../../rails_helper', __dir__)

RSpec.describe TrashedIssue::IssueWrapper, type: :model do
  before :each do
    allow(User).to receive(:current).and_return create(:user)
  end

  describe 'attachments of journals' do
    let(:wrapped_issue) { TrashedIssue::IssueWrapper.new(trashed_issue.attributes_json, trashed_issue) }
    let(:trashed_issue) do
      create(:issue).destroy
      TrashedIssue.first
    end

    it 'accesses attachments of the trashed issue' do
      expect(trashed_issue).to receive(:attachments)
      wrapped_issue.journals.first.attachments
    end
  end
end
