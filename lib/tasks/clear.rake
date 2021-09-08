# frozen_string_literal: true

namespace :redmine_issue_trash do
  task clear: :environment do
    days = ENV['days'].presence&.to_i || 30

    TrashedIssue.where('created_at <= ?', days.days.ago).destroy_all
  end
end
