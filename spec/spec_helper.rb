$:.unshift File.dirname(__FILE__) + '/../lib'

require "rubygems"
require "bundler/setup"
require "active_merchant_first_data"
require "logger"
require "vcr"

VCR.config do |c|
  c.cassette_library_dir = "spec/cassettes"
  c.stub_with :fakeweb
  # c.default_cassette_options = { :record => :new_episodes }
end

RSpec.configure do |config|
  config.extend VCR::RSpec::Macros
end

ActiveMerchant::Billing::Base.gateway_mode = :test
ActiveMerchant::Billing::FirstData::Gateway.ssl_strict = true
ActiveMerchant::Billing::FirstData::Gateway.logger = Logger.new(STDOUT)
ActiveMerchant::Billing::FirstData::Gateway.logger.level = Logger::WARN
# ActiveMerchant::Billing::FirstData::Gateway.wiredump_device = STDOUT
