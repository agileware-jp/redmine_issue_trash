# frozen_string_literal: true

require File.expand_path('../rails_helper', __dir__)

RSpec.describe 'Issue restoration', type: :request do
  let(:user) { create(:user, admin: true) }
  let(:tracker) { create(:tracker) }
  let(:cf) { create(:issue_custom_field, field_format: 'attachment', trackers: [tracker], is_for_all: true) }

  before do
    allow_any_instance_of(User).to receive(:deliver_security_notification) { nil }
    allow(User).to receive(:current) { user }
  end

  subject { post '/restored_issues', params: { id: trashed.id } }
  let!(:trashed) do
    # create issue with attachment type custom field
    cf_attachment = create(:attachment)
    issue = create(:issue, tracker: tracker, custom_field_values: { cf.id => cf_attachment.id })
    cf_attachment.update(container: issue.custom_values.first)
    issue.watcher_users << create(:user)

    issue.destroy
    TrashedIssue.last
  end

  context 'when successfully restored' do
    it { expect { subject }.to change(Issue, :count).by(1) }
    it { expect { subject }.to change(TrashedIssue, :count).by(-1) }
    it 'redirects to the restored issue' do
      subject
      expect(response).to redirect_to assigns(:issue)
      expect(flash[:notice]).to eq 'Issue was successfully restored.'
    end
    it 'Custom field attachments are retained on restored issue' do
      subject
      issue = Issue.order(updated_on: :desc).first
      attachment = Attachment.order(created_on: :desc).first
      expect(issue.custom_field_values.first.value.to_i).to eq(attachment.id)
    end
  end

  context 'when restoration failed' do
    before :each do
      allow_any_instance_of(Issue).to receive(:subject).and_return nil
    end
    it { expect { subject }.to_not change(Issue, :count) }
    it { expect { subject }.to_not change(TrashedIssue, :count) }
    it 'redirects to the trashed issue' do
      subject
      expect(response).to redirect_to assigns(:trashed)
      expect(flash[:error]).to eq 'Subject cannot be blank'
    end
  end
end
