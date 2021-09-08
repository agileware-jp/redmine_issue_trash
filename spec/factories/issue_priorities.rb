# frozen_string_literal: true

FactoryBot.define do
  factory :issue_priority do
    sequence(:name) { |n| "issue_priority-#{n}" }
  end
end
