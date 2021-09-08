# frozen_string_literal: true

FactoryBot.define do
  factory :project do
    sequence(:name) { |n| "project-#{n}" }
    sequence(:identifier) { |n| "project-identifier-#{n}" }
  end
end
