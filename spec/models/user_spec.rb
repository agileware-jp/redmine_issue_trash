# frozen_string_literal: true

require File.expand_path('../rails_helper', __dir__)

RSpec.describe User, type: :model do
  let(:user) { create(:user) }

  describe 'destroy an event author' do
    subject { user.destroy! }
    before do
      User.anonymous # for creating the anonymous user
      TrashedIssue.create!(deleted_by: user)
    end

    it { expect { subject }.to_not raise_error }
    it { expect { subject }.to change(User, :count).by(-1) }
  end
end
