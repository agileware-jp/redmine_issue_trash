# frozen_string_literal: true

FactoryBot.define do
  factory :user do
    login { Faker::Internet.unique.username }
    firstname { Faker::Name.first_name }
    lastname { Faker::Name.last_name }
    mail { Faker::Internet.unique.email }
    language { 'en' }
  end
end
