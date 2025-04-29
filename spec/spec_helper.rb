# frozen_string_literal: true

require 'bundler/setup'
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))

require 'faker'
require 'rspec/its'
require 'single_cov'

# avoid coverage failure from lower docker versions not running all tests
SingleCov.setup :rspec

require 'docker'
ENV['DOCKER_API_USER']  ||= 'debbie_docker'
ENV['DOCKER_API_PASS']  ||= '*************'
ENV['DOCKER_API_EMAIL'] ||= 'debbie_docker@example.com'

RSpec.shared_context 'local paths' do
  def project_dir
    File.expand_path(File.join(File.dirname(__FILE__), '..'))
  end
end

RSpec.shared_context 'check for swarm' do
  before do |example|
    next if ENV['RUN_SWARM_TESTS']
    next unless described_class && described_class.include?(Docker::Swarm)
    skip 'Swarm mode is required to run this test'
  end
end

module SpecHelpers
  def skip_slow_test
    skip "Disabled because ENV['RUN_SLOW_TESTS'] not set" unless ENV['RUN_SLOW_TESTS']
  end

  def skip_without_auth
    skip "Disabled because of missing auth" if ENV['DOCKER_API_USER'] == 'debbie_docker'
  end
end

Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each { |f| require f }

RSpec.configure do |config|
  config.mock_with :rspec
  config.color = true
  config.formatter = :documentation
  config.tty = true
  config.include SpecHelpers
  config.include_context 'local paths'
  config.include_context 'check for swarm'
end
