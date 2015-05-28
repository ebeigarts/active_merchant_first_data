module ActiveMerchant #:nodoc:
  module Billing #:nodoc:
    module FirstData
      class Response

        def initialize response_parameters
          self.parameters=response_parameters
        end

        def ok?
          result == "OK"
        end

        def recurring?
          @parameters[:recc_pmnt_expiry].present? || @parameters[:recc_pmnt_id].present?
        end

        def result
          @parameters[:result]
        end

        def transaction_id
          @parameters[:transaction_id]
        end

        def result_code
          @parameters[:result_code]
        end

        def parameters
          @parameters
        end

        private
          def parameters=(value)
            @parameters=value
          end
      end
    end
  end
end
