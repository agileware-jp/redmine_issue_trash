# frozen_string_literal: true

RSpec.configure do |config|
  config.include FactoryBot::Syntax::Methods

  config.before(:suite) do
    FactoryBot.definition_file_paths << File.expand_path('../factories', __dir__)
    FactoryBot.find_definitions
  end
end
