# frozen_string_literal: true

class TrashedIssue
  class IssueWrapper < DelegateClass(Issue)
    attr_reader :child_ids, :relations

    class << self
      delegate :primary_key, :polymorphic_name, :has_query_constraints?, :composite_primary_key?, to: Issue
    end

    def initialize(attributes, trashed_issue)
      super(Issue.new(attributes.except(
                        'custom_field_values',
                        'child_ids',
                        'relations',
                        'journals',
                        'watcher_user_ids'
                      )))
      self.trashed = true
      self.priority_id = attributes['priority_id']
      self.custom_field_values = attributes['custom_field_values'] || {}
      self.watcher_users = User.where(id: attributes['watcher_user_ids'])
      @child_ids = attributes['child_ids'] || []
      @relations = (attributes['relations'] || []).map { |attr| IssueRelation.new(attr) }
      build_jornals(attributes, trashed_issue)
    end

    def tracker
      super || Tracker.new(name: "#{I18n.t(:missing_record_prefix)} #{I18n.t(:field_tracker)}")
    end

    def author
      super || User.anonymous
    end

    def status
      super || IssueStatus.new(name: "#{I18n.t(:missing_record_prefix)} #{I18n.t(:field_status)}")
    end

    def priority
      super || IssuePriority.new(name: "#{I18n.t(:missing_record_prefix)} #{I18n.t(:field_priority)}")
    end

    def assigned_to
      return nil if assigned_to_id.blank?

      super || User.anonymous
    end

    def fixed_version
      return nil if fixed_version_id.blank?

      super || Version.new(id: fixed_version_id, project: project,
                           name: "#{I18n.t(:missing_record_prefix)} #{I18n.t(:field_version)}")
    end

    private

    def build_jornals(attributes, trashed_issue)
      return if attributes['journals'].blank?

      self.journals = attributes['journals'].map do |journal_attributes|
        Journal.new(journal_attributes.except('details')).tap do |journal|
          journal.details = journal_attributes['details'].map do |detail_attributes|
            JournalDetail.new(detail_attributes)
          end
        end
      end

      journals.each do |journal|
        journal.singleton_class.class_eval do
          def visible_details(user = User.current)
            details.select do |detail|
              case detail.property
              when 'cf'
                detail.custom_field&.visible_by?(project, user)
              when 'relation'
                Issue.find_by_id(detail.value || detail.old_value)&.visible?(user) ||
                  Issue.new(id: detail.value || detail.old_value)
              else
                true
              end
            end
          end

          define_method :journalized do |*args|
            super(*args).tap do |issue|
              issue.define_singleton_method :attachments do
                trashed_issue.attachments
              end
            end
          end
        end
      end
    end
  end
end
