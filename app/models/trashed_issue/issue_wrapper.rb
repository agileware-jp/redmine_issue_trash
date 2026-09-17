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
      expose_trashed_attachments(trashed_issue)
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

    # 本体はインライン添付・attachment: リンク・{{thumbnail}} マクロを、
    # 描画対象オブジェクトの #attachments から解決する。
    # 本文の描画対象はこの wrapper だが、カスタムフィールドの描画対象は
    # CustomFieldValue#customized、つまり内側の Issue になるため、
    # 内側の Issue 自身が正しい添付を返す必要がある。
    #
    # TrashedIssue#rebuild が復元用に持たせるのは未保存のコピーで id が nil。
    # これが本体へ渡ると、Redmine 7.0 は
    # Redmine::WikiFormatting::InlineAttachmentsScrubber の
    # sort_by { [created_on, id] } で nil と Integer を比較して ArgumentError になり、
    # 6.1 でも AttachmentPatch に除外されて添付を解決できない。
    #
    # そこで読み出しはゴミ箱側の保存済み添付に固定する。復元
    # (RestoredIssuesController) は association の autosave がコピーを保存するので、
    # この上書きの影響を受けない。
    def expose_trashed_attachments(trashed_issue)
      __getobj__.define_singleton_method(:attachments) { trashed_issue.attachments }
    end

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
