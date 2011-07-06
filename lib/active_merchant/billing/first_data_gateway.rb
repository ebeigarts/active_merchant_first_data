require "active_merchant"

module ActiveMerchant #:nodoc:
  module Billing #:nodoc:
    class FirstDataGateway < Gateway
      class_attribute :test_url, :live_url, :test_redirect_url, :live_redirect_url, :pem_file, :pem_password

      self.test_redirect_url = 'https://secureshop-test.firstdata.lv/ecomm/ClientHandler'
      self.live_redirect_url = 'https://secureshop.firstdata.lv/ecomm/ClientHandler'

      self.test_url = 'https://secureshop-test.firstdata.lv:8443/ecomm/MerchantHandler'
      self.live_url = 'https://secureshop.firstdata.lv:8443/ecomm/MerchantHandler'

      self.homepage_url = 'http://www.firstdata.lv/'
      self.display_name = 'First Data'

      self.ssl_strict = false
      self.default_currency = '428' # LVL (http://en.wikipedia.org/wiki/ISO_4217)
      self.money_format = :cents

      # Creates a new FirstDataGateway
      #
      # The gateway requires that a valid pem and password be passed
      # in the +options+ hash.
      #
      # Options:
      #
      # * <tt>:pem</tt> -- The First Data cert/key (REQUIRED)
      # * <tt>:pem_password</tt> -- The First Data password. (REQUIRED)
      #
      def initialize(options = {})
        requires!(options, :pem, :pem_password)
        @options = options
        super
      end

      # Perform a purchase, which is essentially an authorization and capture in a single operation.
      #
      # Registering of SMS transaction
      # @param int $amount transaction amount in minor units, mandatory 
      # @param int $currency transaction currency code, mandatory 
      # @param string $ip clientís IP address, mandatory
      # @param string $desc description of transaction, optional
      # @param string $language authorization language identificator, optional 
      # @return string TRANSACTION_ID
      #
      def purchase(amount, params = {})
        params = params.reverse_merge(
          :command => :v,
          :amount => amount,
          :currency => default_currency
        )
        requires!(params, :amount, :currency, :client_ip_addr)
        commit(params)
      end

      # Performs an authorization, which reserves the funds on the customer's credit card, but does not
      # charge the card.
      #
      # Registering of DMS authorisation
      # @param int $amount transaction amount in minor units, mandatory 
      # @param int $currency transaction currency code, mandatory 
      # @param string $ip clientís IP address, mandatory
      # @param string $desc description of transaction, optional
      # @param string $language authorization language identificator, optional 
      # @return string TRANSACTION_ID
      #
      def authorize(amount, params = {})
        params = params.reverse_merge(
          :command => :a,
          :msg_type => 'DMS',
          :amount => amount,
          :currency => default_currency
        )
        requires!(params, :amount, :currency, :client_ip_addr, :msg_type)
        commit(params)
      end

      # Captures the funds from an authorized transaction.
      #
      # Making of DMS transaction
      # @param int $auth_id id of previously made successeful authorisation
      # @param int $amount transaction amount in minor units, mandatory 
      # @param int $currency transaction currency code, mandatory 
      # @param string $ip clientís IP address, mandatory
      # @param string $desc description of transaction, optional
      # @return string RESULT, RESULT_CODE, RRN, APPROVAL_CODE
      #
      def capture(amount, trans_id, params = {})
        params = params.reverse_merge(
          :command => :t,
          :msg_type => 'DMS',
          :trans_id => trans_id,
          :amount => amount,
          :currency => default_currency
        )
        requires!(params, :trans_id, :amount, :currency, :client_ip_addr)
        commit(params)
      end

      # Transaction result
      #
      # @param int $trans_id transaction identifier, mandatory
      # @param string $ip clientís IP address, mandatory
      # @return string RESULT, RESULT_CODE, 3DSECURE, AAV, RRN, APPROVAL_CODE
      #
      def result(trans_id, params = {})
        params = params.reverse_merge(
          :command => :c,
          :trans_id => trans_id
        )
        requires!(params, :trans_id, :client_ip_addr)
        commit(params)
      end

      # credit() allows you to return money to a card that was previously billed.
      #
      # Transaction reversal
      # @param int $trans_id transaction identifier, mandatory
      # @param int $amount transaction amount in minor units, mandatory 
      # @return string RESULT, RESULT_CODE
      #
      def credit(amount, trans_id = nil)
        params = {
          :command => :r,
          :trans_id => trans_id,
          :amount => amount
        }
        requires!(params, :command, :trans_id, :amount)
        commit(params)
      end

      # Close business day.
      def close_day
        commit({ :command => :b })
      end

      def endpoint_url
        test? ? test_url : live_url
      end

      def redirect_url
        test? ? test_redirect_url : live_redirect_url
      end

      private

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
        raise response[:error] unless response[:error].blank?
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
