module ActiveMerchant #:nodoc:
  module Billing #:nodoc:
    class FirstDataGateway < ActiveMerchant::Billing::FirstData::Gateway

      def initialize options = {}
        ActiveMerchant::Billing::FirstData::Gateway.new options
      end

    end
  end
end
