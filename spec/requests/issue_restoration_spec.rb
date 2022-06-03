# frozen_string_literal: true

require File.expand_path('../rails_helper', __dir__)

RSpec.describe 'Issue restoration', type: :request do
  let(:user) { create(:user, admin: true) }

  before do
    allow_any_instance_of(User).to receive(:deliver_security_notification) { nil }
    allow(User).to receive(:current) { user }
  end

  subject { post '/restored_issues', params: { id: trashed.id } }
  let!(:trashed) do
    issue = create(:issue)
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
