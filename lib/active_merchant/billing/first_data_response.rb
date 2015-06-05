module ActiveMerchant #:nodoc:
  module Billing #:nodoc:
    class FirstDataResponse < Response
      RESPONSE_CODES = {
        "000" => "Approved",
        "001" => "Approved, honour with identification",
        "002" => "Approved for partial amount",
        "003" => "Approved for VIP",
        "004" => "Approved, update track 3",
        "005" => "Approved, account type specified by card issuer",
        "006" => "Approved for partial amount, account type specified by card issuer",
        "007" => "Approved, update ICC",
        "100" => "Decline (general, no comments)",
        "101" => "Decline, expired card",
        "102" => "Decline, suspected fraud",
        "103" => "Decline, card acceptor contact acquirer",
        "104" => "Decline, restricted card",
        "105" => "Decline, card acceptor call acquirer's security department",
        "106" => "Decline, allowable PIN tries exceeded",
        "107" => "Decline, refer to card issuer",
        "108" => "Decline, refer to card issuer's special conditions",
        "109" => "Decline, invalid merchant",
        "110" => "Decline, invalid amount",
        "111" => "Decline, invalid card number",
        "112" => "Decline, PIN data required",
        "113" => "Decline, unacceptable fee",
        "114" => "Decline, no account of type requested",
        "115" => "Decline, requested function not supported",
        "116" => "Decline, not sufficient funds",
        "117" => "Decline, incorrect PIN",
        "118" => "Decline, no card record",
        "119" => "Decline, transaction not permitted to cardholder",
        "120" => "Decline, transaction not permitted to terminal",
        "121" => "Decline, exceeds withdrawal amount limit",
        "122" => "Decline, security violation",
        "123" => "Decline, exceeds withdrawal frequency limit",
        "124" => "Decline, violation of law",
        "125" => "Decline, card not effective",
        "126" => "Decline, invalid PIN block",
        "127" => "Decline, PIN length error",
        "128" => "Decline, PIN kay synch error",
        "129" => "Decline, suspected counterfeit card",
        "197" => "Declined, call AmEx",
        "198" => "Declined, call Card Processing Centre",
        "200" => "Pick-up (general, no comments)",
        "201" => "Pick-up, expired card",
        "202" => "Pick-up, suspected fraud",
        "203" => "Pick-up, card acceptor contact card acquirer",
        "204" => "Pick-up, restricted card",
        "205" => "Pick-up, card acceptor call acquirer's security department",
        "206" => "Pick-up, allowable PIN tries exceeded",
        "207" => "Pick-up, special conditions",
        "208" => "Pick-up, lost card",
        "209" => "Pick-up, stolen card",
        "210" => "Pick-up, suspected counterfeit card",
        "300" => "Status message: file action successful",
        "301" => "Status message: file action not supported by receiver",
        "302" => "Status message: unable to locate record on file",
        "303" => "Status message: duplicate record, old record replaced",
        "304" => "Status message: file record field edit error",
        "305" => "Status message: file locked out",
        "306" => "Status message: file action not successful",
        "307" => "Status message: file data format error",
        "308" => "Status message: duplicate record, new record rejected",
        "309" => "Status message: unknown file",
        "400" => "Accepted (for reversal)",
        "500" => "Status message: reconciled, in balance",
        "501" => "Status message: reconciled, out of balance",
        "502" => "Status message: amount not reconciled, totals provided",
        "503" => "Status message: totals for reconciliation not available",
        "504" => "Status message: not reconciled, totals provided",
        "600" => "Accepted (for administrative info)",
        "601" => "Status message: impossible to trace back original transaction",
        "602" => "Status message: invalid transaction reference number",
        "603" => "Status message: reference number/PAN incompatible",
        "604" => "Status message: POS photograph is not available",
        "605" => "Status message: requested item supplied",
        "606" => "Status message: request cannot be fulfilled - required documentation is not available",
        "700" => "Accepted (for fee collection)",
        "800" => "Accepted (for network management)",
        "900" => "Advice acknowledged, no financial liability accepted",
        "901" => "Advice acknowledged, finansial liability accepted",
        "902" => "Decline reason message: invalid transaction",
        "903" => "Status message: re-enter transaction",
        "904" => "Decline reason message: format error",
        "905" => "Decline reason message: acqiurer not supported by switch",
        "906" => "Decline reason message: cutover in process",
        "907" => "Decline reason message: card issuer or switch inoperative",
        "908" => "Decline reason message: transaction destination cannot be found for routing",
        "909" => "Decline reason message: system malfunction",
        "910" => "Decline reason message: card issuer signed off",
        "911" => "Decline reason message: card issuer timed out",
        "912" => "Decline reason message: card issuer unavailable",
        "913" => "Decline reason message: duplicate transmission",
        "914" => "Decline reason message: not able to trace back to original transaction",
        "915" => "Decline reason message: reconciliation cutover or checkpoint error",
        "916" => "Decline reason message: MAC incorrect",
        "917" => "Decline reason message: MAC key sync error",
        "918" => "Decline reason message: no communication keys available for use",
        "919" => "Decline reason message: encryption key sync error",
        "920" => "Decline reason message: security software/hardware error - try again",
        "921" => "Decline reason message: security software/hardware error - no action",
        "922" => "Decline reason message: message number out of sequence",
        "923" => "Status message: request in progress",
        "940" => "Decline, blocked by fraud filter",
        "950" => "Decline reason message: violation of business arrangement"
      }

      attr_accessor :authorization, :error_code, :error_message, :parameters, :success, :message

      def initialize params, options={}
        success = params[:result] == 'OK'
        message = RESPONSE_CODES[options[:result_code]]

        unless success
          error_code = options[:result_code]
          error_message = message
        end

        super success, message, params, options.merge(
          authorization: params[:transaction_id]
        )

        self.parameters=params
      end

      def success?
        success
      end

      def recurring?
        recc_pmnt_id.present? && recc_pmnt_expiry.present?
      end

      [:recc_pmnt_expiry, :recc_pmnt_id, :result, :result_code, :transaction_id].each do |name|
        define_method name do
          parameters[name]
        end
      end

      def _3d_secure
        parameters[:'3dsecure']
      end

      def result_message
        result_text
      end

      def result_text
        RESPONSE_CODES[result_code]
      end

      def [](value)
        parameters[value]
      end
    end
  end
end
