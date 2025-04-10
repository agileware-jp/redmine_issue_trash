# frozen_string_literal: true

require File.expand_path('../rails_helper', __dir__)

RSpec.describe TrashedIssue, type: :model do
  before :each do
    allow(User).to receive(:current).and_return create(:user)
  end

  describe 'Callbacks' do
    let(:issue) { create(:issue) }
    it { expect { issue.destroy }.to change(TrashedIssue, :count).by(1) }

    context 'When an issue is private' do
      let(:issue) { create(:issue, is_private: true) }
      it { expect { issue.destroy }.not_to change(TrashedIssue, :count) }
    end

    context 'When the project is destroyed' do
      it { expect { issue.project.destroy }.not_to change(TrashedIssue, :count) }
    end
  end

  describe '#attachments' do
    subject(:attachments) do
      source_issue.destroy
      TrashedIssue.first.attachments
    end
    let(:source_issue) { create(:issue) }
    let!(:attachment) { create(:attachment, container: source_issue) }

    it { expect(attachments.count).to eq 1 }
    it { expect(attachments.first.digest).to eq attachment.digest }
    it { expect(attachments.first.author).to eq attachment.author }
  end

  describe '#rebuild' do
    subject(:issue) do
      source_issue.destroy
      TrashedIssue.first.rebuild
    end

    describe 'Project' do
      let(:source_issue) { create(:issue, project: project) }
      let(:project) { create(:project) }
      it { expect(issue.project).to eq project }
    end

    describe 'Tracker' do
      let(:source_issue) { create(:issue, tracker: tracker) }
      let(:tracker) { create(:tracker) }
      it { expect(issue.tracker).to eq tracker }
    end

    describe 'Subject' do
      let(:source_issue) { create(:issue, subject: subject) }
      let(:subject) { Faker::Lorem.word }
      it { expect(issue.subject).to eq subject }
    end

    describe 'Description' do
      let(:source_issue) { create(:issue, description: description) }
      let(:description) { Faker::Lorem.paragraph }
      it { expect(issue.description).to eq description }
    end

    describe 'Status' do
      let(:source_issue) { create(:issue, status: status) }
      let(:status) { create(:issue_status) }
      it { expect(issue.status).to eq status }
    end

    describe 'Priority' do
      let(:source_issue) { create(:issue, priority: priority) }
      let(:priority) { create(:issue_priority) }
      it { expect(issue.priority).to eq priority }
    end

    describe 'Assignee' do
      let(:source_issue) { create(:issue, assigned_to: user) }
      let(:user) { create(:user) }
      before :each do
        allow_any_instance_of(Issue).to receive(:assignable_users).and_return [user]
      end
      it { expect(issue.assigned_to).to eq user }
    end

    describe 'Version' do
      let(:source_issue) { create(:issue, project: project, fixed_version: version) }
      let(:project) { create(:project) }
      let(:version) { create(:version, project: project) }
      it { expect(issue.fixed_version).to eq version }
    end

    describe 'Parent' do
      let(:source_issue) { create(:issue, parent: parent_issue) }
      let(:parent_issue) { create(:issue) }
      it { expect(issue.parent).to eq parent_issue }
    end

    describe 'StartDate' do
      let(:source_issue) { create(:issue, start_date: start_date) }
      let(:start_date) { Faker::Date.backward }
      it { expect(issue.start_date).to eq start_date }
    end

    describe 'DueDate' do
      let(:source_issue) { create(:issue, due_date: due_date) }
      let(:due_date) { Faker::Date.forward }
      it { expect(issue.due_date).to eq due_date }
    end

    describe 'EstimatedHours' do
      let(:source_issue) { create(:issue, estimated_hours: estimated_hours) }
      let(:estimated_hours) { Faker::Number.decimal(l_digits: 2, r_digits: 1) }
      it { expect(issue.estimated_hours).to eq estimated_hours }
    end

    describe 'DoneRatio' do
      let(:source_issue) { create(:issue, done_ratio: done_ratio) }
      let(:done_ratio) { Faker::Number.within(range: 0..100) }
      it { expect(issue.done_ratio).to eq done_ratio }
    end

    describe 'Watchers' do
      let(:source_issue) { create(:issue, watcher_users: watcher_users) }
      let(:watcher_users) { create_list(:user, 3) }
      it { expect(issue.watcher_users).to eq watcher_users }
    end

    describe 'CustomFieldValues' do
      let(:source_issue) { create(:issue, tracker: tracker, custom_field_values: { cf.id => value }) }
      let(:tracker) { create(:tracker) }
      let(:cf) { create(:issue_custom_field, field_format: 'string', trackers: [tracker], is_for_all: true) }
      let(:value) { Faker::Lorem.word }
      it { expect(issue.custom_field_value(cf)).to eq value }
    end

    describe 'ChildIds' do
      let(:source_issue) { create(:issue) }
      let!(:child_issue) { create(:issue, parent: source_issue) }
      it { expect(issue.child_ids).to match_array [child_issue.id] }
    end

    describe 'Relations' do
      let(:source_issue) { create(:issue) }
      let(:issue_from) { create(:issue, project: source_issue.project) }
      before :each do
        IssueRelation.create!(issue_from: issue_from, issue_to: source_issue, relation_type: 'relates')
      end
      it {
        expect(issue.relations).to match_array [
          an_object_having_attributes(
            issue_from_id: issue.id,
            issue_to_id: issue_from.id,
            relation_type: 'relates'
          )
        ]
      }
    end

    describe 'Journals' do
      let(:source_issue) { create(:issue, subject: subject_before) }
      let(:notes) { 'change subject' }
      let(:user) { create(:user) }
      let(:subject_before) { 'before' }
      let(:subject_after) { 'after' }
      before :each do
        source_issue.reload.init_journal(user, notes)
        source_issue.update!(subject: subject_after)
      end
      it {
        expect(issue.journals).to match_array([
                                                an_object_having_attributes(
                                                  notes: notes,
                                                  user: user
                                                )
                                              ])
      }
      it {
        expect(issue.journals.first.details).to match_array([
                                                              an_object_having_attributes(
                                                                property: 'attr',
                                                                prop_key: 'subject',
                                                                old_value: subject_before,
                                                                value: subject_after
                                                              )
                                                            ])
      }
    end
  end

  describe '.copy_from!' do
    let(:issue) { create(:issue) }
    let(:user) { create(:user) }

    before do
      allow(User).to receive(:current).and_return(user)
    end

    context 'when the issue is private' do
      let(:issue) { create(:issue, is_private: true) }

      it 'does not create a trashed issue' do
        expect {
          TrashedIssue.copy_from!(issue)
        }.not_to change(TrashedIssue, :count)
      end
    end

    context 'when the issue is not private' do
      it 'creates a trashed issue' do
        expect {
          TrashedIssue.copy_from!(issue)
        }.to change(TrashedIssue, :count).by(1)
      end

      it 'sets the correct project' do
        trashed_issue = TrashedIssue.copy_from!(issue)
        expect(trashed_issue.project).to eq(issue.project)
      end

      it 'sets the correct deleted_by user' do
        trashed_issue = TrashedIssue.copy_from!(issue)
        expect(trashed_issue.deleted_by).to eq(user)
      end

      it 'sets attributes_json correctly' do
        custom_field = create(:issue_custom_field, field_format: 'text')
        custom_value = 'dummy text'
        issue.custom_values << CustomValue.create!(
          custom_field: custom_field,
          customized: issue,
          value: custom_value
        )
        trashed_issue = TrashedIssue.copy_from!(issue)

        expect(trashed_issue.attributes_json).to include(
          'id' => issue.id,
          'subject' => issue.subject,
          'project_id' => issue.project_id,
          'custom_field_values' => { custom_field.id.to_s => custom_value }
        )
      end

      it 'copies attachments' do
        attachment = create(:attachment, container: issue)
        trashed_issue = TrashedIssue.copy_from!(issue)

        expect(trashed_issue.attachments.count).to eq(1)
        expect(trashed_issue.attachments.first.digest).to eq(attachment.digest)
      end

      it 'copies custom value attachments' do
        custom_field = create(:issue_custom_field, field_format: 'attachment')
        custom_value = CustomValue.create!(custom_field: custom_field, customized: issue, value: '1')
        attachment = create(:attachment, container: custom_value)
        issue.custom_values << custom_value
        trashed_issue = TrashedIssue.copy_from!(issue)

        expect(trashed_issue.trashed_custom_values.count).to eq(1)
        expect(trashed_issue.trashed_custom_values.first.attachments.count).to eq(1)
        expect(trashed_issue.trashed_custom_values.first.attachments.first.digest).to eq(attachment.digest)
      end
    end
  end

  describe '.attributes' do
    let(:issue) { create(:issue) }

    describe 'custom field values' do
      let(:custom_field) { create(:issue_custom_field, field_format: field_format, multiple: multiple) }
      let(:field_format) { 'string' }
      let(:multiple) { false }

      subject { TrashedIssue.attributes(issue.reload)['custom_field_values'] }

      context 'string' do
        let(:value) { 'custom value' }
        before do
          CustomValue.create(customized: issue, custom_field: custom_field, value: value)
        end

        it 'get attributes' do
          is_expected.to eq({custom_field.id => 'custom value'})
        end
      end

      context 'Key Value' do
        let(:field_format) { 'enumeration' }
        before do
          custom_field.enumerations.create(name: 'value A')
          custom_field.enumerations.create(name: 'value B')
          custom_field.enumerations.create(name: 'value C')
        end

        context 'multiple=false' do
          let(:multiple) { false }
          before do
            CustomValue.create(customized: issue, custom_field: custom_field, value: 'value B')
          end
          it { is_expected.to eq({custom_field.id => 'value B'}) }
        end

        context 'multiple=true' do
          let(:multiple) { true }
          before do
            CustomValue.create(customized: issue, custom_field: custom_field, value: 'value A')
            CustomValue.create(customized: issue, custom_field: custom_field, value: 'value B')
          end
          it { is_expected.to eq({custom_field.id => ['value A', 'value B']}) }
        end
      end
    end
  end
end
