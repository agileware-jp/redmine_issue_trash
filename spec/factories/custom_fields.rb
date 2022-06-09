# frozen_string_literal: true

FactoryBot.define do
  factory :issue_custom_field, class: 'IssueCustomField' do
    sequence(:name) { |n| "custom_field-#{n}" }
    field_format { 'string' }
  end
end
