ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"
require "minitest/mock"

# Load all support files
Dir[Rails.root.join("test", "support", "**", "*.rb")].sort.each { |f| require f }

module ActiveSupport
  class TestCase
    include FactoryBot::Syntax::Methods
    include JsonTestHelpers
    include MembershipTestHelpers

    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    # fixtures :all

    # Add more helper methods to be used by all tests here...
  end
end
