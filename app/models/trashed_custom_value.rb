# frozen_string_literal: true

class TrashedCustomValue < defined?(ApplicationRecord) == 'constant' ? ApplicationRecord : ActiveRecord::Base
  belongs_to :trashed_issue

  acts_as_attachable view_permission: :view_files

  delegate :project, to: :trashed_issue
end
