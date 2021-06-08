# frozen_string_literal: true

FactoryBot.define do
  factory :issue do
    project
    tracker
    sequence(:subject) { |n| "issue-#{n}" }
    status { association :issue_status }
    priority { association :issue_priority }
    author { association :user }

    before(:create) do |issue|
      issue.project.trackers << issue.tracker if issue.project.trackers.exclude?(issue.tracker)
    end
  end
end
