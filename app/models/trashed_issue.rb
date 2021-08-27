# frozen_string_literal: true

class TrashedIssue < ActiveRecord::Base
  belongs_to :project
  has_many :trashed_custom_values, dependent: :destroy
  belongs_to :deleted_by, class_name: 'User'

  acts_as_attachable view_permission: :view_files
  acts_as_event datetime: :created_at,
                title: lambda { |i|
                         I18n.t('trashed_issue.event_title',
                                id: i.attributes_json['id'],
                                subject: i.attributes_json['subject'])
                       },
                description: nil,
                author: :deleted_by,
                url: ->(i) { { controller: :trashed_issues, action: :show, id: i.id } },
                type: ->(_) { 'del' } # for del-icon
  acts_as_activity_provider scope: -> { joins(:project) },
                            author_key: :deleted_by_id,
                            timestamp: "#{table_name}.created_at"

  class << self
    # for activity_provider
    def visible(user, options)
      projects = if options[:project].blank?
                   Project.all
                 elsif options[:with_subprojects]
                   Project.where(id: options[:project].self_and_descendants)
                 else
                   Project.where(id: options[:project])
                 end
      allowed_projects = projects.merge(Project.allowed_to(user, :view_trashed_issues))
      where(project: allowed_projects).or(where(project: projects, deleted_by: user))
    end

    def copy_from(issue)
      return if issue.is_private?

      create!(
        project: issue.project,
        attributes_json: attributes(issue),
        deleted_by: User.current
      ).tap do |i|
        i.attachments = issue.attachments.map do |attachment|
          attachment.copy(container: i)
        end

        Attachment.where(container: issue.custom_values).each do |attachment|
          i.trashed_custom_values.create!(
            source_attachment_id: attachment.id,
            attachments: [attachment.copy]
          )
        end
      end
    end

    def attributes(issue)
      issue.attributes.except('lock_version', 'lft', 'rgt').merge(
        'custom_field_values' => issue.custom_values.map { |cv| [cv.custom_field_id, cv.value] }.to_h,
        'child_ids' => issue.children.ids,
        'relations' => issue.relations.map(&:attributes),
        'watcher_user_ids' => issue.watcher_user_ids,
        'journals' => issue.journals.map { |j| j.attributes.merge('details' => j.details.map(&:attributes)) }
      )
    end
  end

  def rebuild
    IssueWrapper.new(attributes_json).tap do |i|
      i.attachments = attachments.map do |attachment|
        attachment.copy(container: i)
      end
    end
  end

  def restore!
    ActiveRecord::Base.transaction do
      rebuild.save!
      destroy!
    end
  end
end
