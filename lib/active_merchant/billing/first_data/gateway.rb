require "active_merchant"

module ActiveMerchant #:nodoc:
  module Billing #:nodoc:
    module FirstData
      class Gateway < Gateway
        mattr_accessor :ssl_strict
        class_attribute :test_url, :live_url, :test_redirect_url, :live_redirect_url, :pem_file, :pem_password

        self.test_redirect_url = 'https://secureshop-test.firstdata.lv/ecomm/ClientHandler'
        self.live_redirect_url = 'https://secureshop.firstdata.lv/ecomm/ClientHandler'

        self.test_url = 'https://secureshop-test.firstdata.lv:8443/ecomm/MerchantHandler'
        self.live_url = 'https://secureshop.firstdata.lv:8443/ecomm/MerchantHandler'

        self.homepage_url = 'http://www.firstdata.lv/'
        self.display_name = 'First Data'

        self.default_currency = '978' # EUR (http://en.wikipedia.org/wiki/ISO_4217)
        self.money_format = :cents

        class Error < StandardError
          attr_reader :response

          def initialize(response, msg=nil)
            @response = response
            super(msg || response[:error])
          end
        end

        # Creates a new FirstDataGateway
        #
        # The gateway requires that a valid pem and password be passed
        # in the +options+ hash.
        #
        # @option options [String] :pem First Data cert/key (REQUIRED)
        # @option options [String] :pem_password First Data cert password (REQUIRED)
        #
        def initialize(options = {})
          requires!(options, :pem, :pem_password)
          @options = options
          super
        end

        # Perform a purchase, which is essentially an authorization and capture in a single operation.
        #
        # Registering of SMS transaction
        #
        # @param [Integer] amount transaction amount in minor units, mandatory
        # @option params [Integer, String] :currency transaction currency code, mandatory
        # @option params [String] :client_ip_addr client's IP address, mandatory
        # @option params [String] :description description of transaction, optional
        # @option params [String] :language authorization language identificator, optional
        # @return [ActiveSupport::HashWithIndifferentAccess] TRANSACTION_ID
        #
        def purchase(amount, params = {})
          params = params.reverse_merge(
            :command => :v,
            :amount => amount,
            :currency => default_currency
          )
          lookup_currency(params)
          requires!(params, :amount, :currency, :client_ip_addr)
          commit(params)
        end

        # Performs an authorization, which reserves the funds on the customer's credit card, but does not
        # charge the card.
        #
        # Registering of DMS authorisation
        #
        # @param [Integer] amount transaction amount in minor units, mandatory
        # @option params [Integer, String] :currency transaction currency code, mandatory
        # @option params [String] :client_ip_addr client's IP address, mandatory
        # @option params [String] :description description of transaction, optional
        # @option params [String] :language authorization language identificator, optional
        # @return [ActiveSupport::HashWithIndifferentAccess] TRANSACTION_ID
        #
        def authorize(amount, params = {})
          params = params.reverse_merge(
            :command => :a,
            :msg_type => 'DMS',
            :amount => amount,
            :currency => default_currency
          )
          lookup_currency(params)
          requires!(params, :amount, :currency, :client_ip_addr, :msg_type)
          commit(params)
        end

        # Captures the funds from an authorized transaction.
        #
        # Making of DMS transaction
        #
        # @param [Integer] amount transaction amount in minor units, mandatory
        # @param [Integer] trans_id id of previously made successeful authorisation
        # @option params [Integer, String] :currency transaction currency code, mandatory
        # @option params [String] :client_ip_addr client's IP address, mandatory
        # @option params [String] :description description of transaction, optional
        # @return [ActiveSupport::HashWithIndifferentAccess] RESULT, RESULT_CODE, RRN, APPROVAL_CODE
        #
        def capture(amount, trans_id, params = {})
          params = params.reverse_merge(
            :command => :t,
            :msg_type => 'DMS',
            :trans_id => trans_id,
            :amount => amount,
            :currency => default_currency
          )
          lookup_currency(params)
          requires!(params, :trans_id, :amount, :currency, :client_ip_addr)
          commit(params)
        end

        # Transaction result
        #
        # @param [Integer] trans_id transaction identifier, mandatory
        # @option params [String] :client_ip_addr client's IP address, mandatory
        # @return [ActiveSupport::HashWithIndifferentAccess] RESULT, RESULT_CODE, 3DSECURE, AAV, RRN, APPROVAL_CODE
        #
        def result(trans_id, params = {})
          params = params.reverse_merge(
            :command => :c,
            :trans_id => trans_id
          )
          requires!(params, :trans_id, :client_ip_addr)
          commit(params)
        end

        # refund() allows you to return money to a card that was previously billed.
        #
        # Transaction reversal
        #
        # @param [Integer] amount transaction amount in minor units, mandatory
        # @param [Integer] trans_id transaction identifier, mandatory
        # @return [ActiveSupport::HashWithIndifferentAccess] RESULT, RESULT_CODE
        #
        def refund(amount, trans_id = nil)
          params = {
            :command => :r,
            :trans_id => trans_id,
            :amount => amount
          }
          requires!(params, :command, :trans_id, :amount)
          commit(params)
        end

        def credit(amount, trans_id = nil)
          deprecated CREDIT_DEPRECATION_MESSAGE
          refund(amount, trans_id)
        end

        # Register new recurring payment along with the first payment
        #
        # @param [Integer] amount transaction amount in minor units, mandatory (up to 12 digits)
        # @option params [Integer, String] :currency transaction currency code, mandatory
        # @option params [String] :client_ip_addr client's IP address, mandatory
        # @option params [String] :description transaction details, mandatory (up to 125 characters)
        # @option params [String] :biller_client_id recurring payment identifier, mandatory (up to 30 characters)
        # @option params [String] :perspayee_expiry preferred deadline for a Recurring payment, mandatory (MMYY)
        #   (system will compare two expiry dates - recurring payment expiry date provided by Merchant and
        #   card expiry date provided by Cardholder. In response Merchant will receive back the earliest expiry dates of both).
        #   For example, Recurring payment date is 1214 but card expiry date 1213 then Merchant will receive back 1213.
        #   First Data system will save the earliest expiry date as Recurring payment expiry date.
        # @option params [Integer] :perspayee_overwrite set to 1 to overwrite existing recurring payment card data
        #   together with payment, optional
        # @option params [String] :language authorization language identificator, optional
        # @return [ActiveSupport::HashWithIndifferentAccess] TRANSACTION_ID
        #
        # Afterwards when transaction result is requested then result response includes also RECC_PMNT_ID and RECC_PMNT_EXPIRY
        #
        def recurring(amount, params = {})
          params = params.reverse_merge(
            :command => :z,
            :amount => amount,
            :currency => default_currency,
            :msg_type => 'SMS',
            :perspayee_gen => 1
          )
          lookup_currency(params)
          requires!(params, :amount, :currency, :client_ip_addr, :description, :biller_client_id, :perspayee_expiry)
          commit(params)
        end

        # Execute subsequent recurring payment
        #
        # @param [Integer] amount transaction amount in minor units, mandatory (up to 12 digits)
        # @option params [Integer, String] :currency transaction currency code, mandatory
        # @option params [String] :client_ip_addr client's IP address, mandatory
        #   (the same IP address which was provided when registered recurring payment)
        # @option params [String] :description transaction details, mandatory (up to 125 characters)
        # @option params [String] :biller_client_id recurring payment identifier, mandatory (up to 30 characters)
        # @return [ActiveSupport::HashWithIndifferentAccess] TRANSACTION_ID, RESULT, RESULT_CODE, RRN, APPROVAL_CODE
        #
        def execute_recurring(amount, params = {})
          params = params.reverse_merge(
            :command => :e,
            :amount => amount,
            :currency => default_currency
          )
          lookup_currency(params)
          requires!(params, :amount, :currency, :client_ip_addr, :description, :biller_client_id)
          commit(params)
        end

        # Overwriting existing recurring payment card data without payment
        #
        # @option params [Integer, String] :currency transaction currency code, mandatory
        # @option params [String] :client_ip_addr client's IP address, mandatory
        # @option params [String] :description transaction details, mandatory (up to 125 characters)
        # @option params [String] :biller_client_id existing recurring payment identifier, mandatory (up to 30 characters)
        # @option params [String] :perspayee_expiry preferred deadline for a Recurring payment, mandatory (MMYY)
        #   (system will compare two expiry dates - recurring payment expiry date provided by Merchant and
        #   card expiry date provided by Cardholder. In response Merchant will receive back the earliest expiry dates of both).
        #   For example, Recurring payment date is 1214 but card expiry date 1213 then Merchant will receive back 1213.
        #   First Data system will save the earliest expiry date as Recurring payment expiry date.
        # @option params [String] :language authorization language identificator, optional
        # @return [ActiveSupport::HashWithIndifferentAccess] TRANSACTION_ID
        #
        # Afterwards when transaction result is requested then result response includes also RECC_PMNT_ID and RECC_PMNT_EXPIRY
        #
        def update_recurring(params = {})
          params = params.reverse_merge(
            :command => :p,
            :amount => 0,
            :currency => default_currency,
            :msg_type => 'AUTH',
            :perspayee_gen => 1,
            :perspayee_overwrite => 1
          )
          lookup_currency(params)
          requires!(params, :currency, :client_ip_addr, :description, :biller_client_id, :perspayee_expiry)
          commit(params)
        end

        # Close business day.
        def close_day
          commit({ :command => :b })
        end

        def endpoint_url
          test? ? test_url : live_url
        end

        def redirect_url(trans_id = nil)
          url = test? ? test_redirect_url : live_redirect_url
          url += "?trans_id=#{CGI.escape trans_id}" if trans_id
          url
        end

        private
          def lookup_currency(params)
            params[:currency] = CURRENCY_CODES[params[:currency]] || params[:currency]
          end

          # Convert HTTP response body to a Ruby Hash.
          def parse(body)
            results = ActiveSupport::HashWithIndifferentAccess.new
            body.split(/[\r\n]+/).each do |pair|
              key, val = pair.split(": ")
              results[key.downcase] = val
            end
            results
          end

          def commit(params = {})
            response = parse(ssl_post(endpoint_url, post_data(params)))
            # FIXME: test cases 17 and 19 return unnecessary error even when result and result_code are present
            # should be removed when this issue is fixed on gataway side
            raise Error.new(response) if !response[:error].blank? && response[:result_code].blank?
            response
          end

          def post_data(params)
            post = PostData.new
            params.each { |k, v| post[k] = v }
            post.to_s
          end
      end
    end
  end
end
