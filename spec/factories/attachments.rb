# frozen_string_literal: true

FactoryBot.define do
  factory :attachment do
    file { Rack::Test::UploadedFile.new(Rails.root.join('test/fixtures/files/testfile.txt')) }
    author { association :user }
  end
end
