# frozen_string_literal: true

require File.expand_path('../rails_helper', __dir__)

RSpec.describe 'Trashed issue show', type: :request do
  let(:user) { create(:user, admin: true) }
  let(:tracker) { create(:tracker) }

  before do
    allow_any_instance_of(User).to receive(:deliver_security_notification) { nil }
    allow(User).to receive(:current) { user }
  end

  subject { get "/trashed_issues/#{trashed.id}" }

  let!(:trashed) do
    # create an issue with an image attached inline in the description, as reported:
    # deleting it and then opening it from the trash previously raised
    # ArgumentError: comparison of Array with Array failed
    # (InlineAttachmentsScrubber#initialize merges @trashed.attachments, which have
    # real ids, with the wrapped issue's own attachments, which are unsaved copies
    # with a nil id but the same created_on, and sort_by cannot compare the two).
    issue = create(:issue, tracker: tracker, description: "![](testfile.jpg)\r\n")
    create(:attachment, container: issue).update!(filename: 'testfile.jpg')

    issue.destroy
    TrashedIssue.last
  end

  it 'renders the trashed issue without an internal error' do
    subject
    expect(response).to have_http_status(:ok)
  end

  it 'resolves the inline image to the real attachment' do
    subject
    attachment = Attachment.find_by(filename: 'testfile.jpg')
    expect(response.body).to include("/attachments/download/#{attachment.id}/testfile.jpg")
  end
end
