# frozen_string_literal: true

require File.expand_path('../rails_helper', __dir__)

RSpec.describe Issue, type: :model do
  describe '#destroy' do
    before :each do
      allow_any_instance_of(User).to receive(:deliver_security_notification) { nil }
      allow(User).to receive(:current).and_return create(:user, admin: true)
    end
    let!(:tracker) { create(:tracker) }
    let!(:issue) { create(:issue, tracker: tracker, assigned_to: nil) }

    context 'in invalid state' do
      it do
        WorkflowPermission.create!(
          tracker: tracker,
          old_status: issue.status,
          new_status_id: 0,
          role: create(:role, permissions: %i[add_issues]),
          field_name: 'assigned_to_id',
          rule: 'required'
        )
        expect(issue).not_to be_valid
        expect { issue.destroy! }.to change(Issue, :count).by(-1)
      end
    end
  end
end
