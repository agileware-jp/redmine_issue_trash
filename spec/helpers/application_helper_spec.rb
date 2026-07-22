# frozen_string_literal: true

require File.expand_path('../rails_helper', __dir__)

RSpec.describe ApplicationHelper, type: :helper do
  # app/views/trashed_issues/show.html.erb:66
  # <%= textilizable @issue, :description, :attachments => @trashed.attachments %>
  describe '#textilizable' do
    subject { helper.textilizable(issue, :description, :attachments => trashed.attachments) }

    # TrashedIssuesController#show clears @issue.attachments after #rebuild, since
    # #rebuild's unsaved copies (id is nil) would otherwise duplicate @trashed.attachments
    # here and crash InlineAttachmentsScrubber's sort_by (see trashed_issue_show_spec.rb).
    let(:issue) { trashed.rebuild.tap { |i| i.attachments = [] } }
    let(:trashed) { TrashedIssue.first }
    let(:source_issue) { create(:issue, description: "![](testfile.jpg)\r\n") }
    let!(:attachment) { create(:attachment, container: source_issue) }

    before { source_issue.destroy }

    it { is_expected.to include('testfile.jpg') }
  end
end
