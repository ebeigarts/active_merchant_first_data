module ActiveMerchant #:nodoc:
  module Billing #:nodoc:
    class FirstDataResponse < ActiveMerchant::Billing::FirstData::Response

      def initialize response_parameters
        self.parameters=response_parameters
      end

    end
  end
end
