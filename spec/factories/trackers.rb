# frozen_string_literal: true

FactoryBot.define do
  factory :tracker do
    sequence(:name) { |n| "tracker-#{n}" }
    default_status { association :issue_status }
  end
end
