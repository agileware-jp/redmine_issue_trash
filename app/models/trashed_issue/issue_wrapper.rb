# frozen_string_literal: true

class TrashedIssue
  class IssueWrapper
    attr_reader :object, :child_ids, :relations

    def initialize(attributes)
      @object = Issue.new(attributes.except('custom_field_values', 'child_ids', 'relations', 'journals',
                                            'watcher_user_ids'))
      @object.trashed = true
      @object.priority_id = attributes['priority_id']
      @object.custom_field_values = attributes['custom_field_values'] || {}
      @object.watcher_users = User.where(id: attributes['watcher_user_ids'])
      @child_ids = attributes['child_ids'] || []
      @relations = (attributes['relations'] || []).map { |attr| IssueRelation.new(attr) }
      build_jornals(attributes)
    end

    def tracker
      super || Tracker.new(name: "#{I18n.t(:missing_record_prefix)} #{I18n.t(:field_tracker)}")
    end

    def author
      super || User.anonymous
    end

    def status
      super || IssueStatus.new(name: "#{I18n.t(:missing_record_prefix)} #{I18n.t(:field_tracker)}")
    end

    def priority
      super || IssuePriority.new(name: "#{I18n.t(:missing_record_prefix)} #{I18n.t(:field_priority)}")
    end

    def assigned_to
      return nil if @object.assigned_to_id.blank?

      super || User.anonymous
    end

    def fixed_version
      return nil if @object.fixed_version_id.blank?

      super || Version.new(id: @object.fixed_version_id, project: project,
                           name: "#{I18n.t(:missing_record_prefix)} #{I18n.t(:field_version)}")
    end

    def method_missing(name, *args)
      if @object.respond_to?(name)
        @object.send(name, *args)
      else
        super
      end
    end

    def respond_to_missing?(symbol, _include_private)
      !@object.respond_to?(symbol)
    end

    private

    def build_jornals(attributes)
      return if attributes['journals'].blank?

      @object.journals = attributes['journals'].map do |journal_attributes|
        Journal.new(journal_attributes.except('details')).tap do |journal|
          journal.details = journal_attributes['details'].map do |detail_attributes|
            JournalDetail.new(detail_attributes)
          end
        end
      end

      @object.journals.each do |journal|
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
        end
      end
    end
  end
end
