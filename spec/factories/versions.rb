# frozen_string_literal: true

FactoryBot.define do
  factory :version do
    sequence(:name) { |n| "version-#{n}" }
  end
end
