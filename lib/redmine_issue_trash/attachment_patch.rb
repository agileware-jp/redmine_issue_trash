# frozen_string_literal: true

module RedmineIssueTrash
  module AttachmentPatch
    module Prepend
      module ClassMethods
        # app/views/trashed_issues/show.html.erb:66
        #   <%= textilizable @issue, :description, :attachments => @trashed.attachments %>
        # @trashed.attachments(TrashedIssue::IssueWrapper#attachments)に#idがAttachmentを使っているため
        def latest_attach(attachments, filename)
          super(attachments.reject { |attachment| attachment.id.blank? }, filename)
        end
      end

      def self.prepended(mod)
        mod.singleton_class.prepend(ClassMethods)
      end
    end
  end
end
