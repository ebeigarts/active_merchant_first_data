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
          recc_pmnt_id.present? && recc_pmnt_expiry.present?
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

        def recc_pmnt_id
          @parameters[:recc_pmnt_id]
        end

        def recc_pmnt_expiry
          @parameters[:recc_pmnt_expiry]
        end

        def three_dee_secure
          @parameters[:'3dsecure']
        end

        def result_text
          FDL_RESPONSE_CODES["c#{result_code}".to_sym]
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
