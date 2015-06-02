module ActiveMerchant #:nodoc:
  module Billing #:nodoc:
    module FirstData
      class Response

        FDL_RESPONSE_CODES = {
          c000: "Approved",
          c001: "Approved, honour with identification",
          c002: "Approved for partial amount",
          c003: "Approved for VIP",
          c004: "Approved, update track 3",
          c005: "Approved, account type specified by card issuer",
          c006: "Approved for partial amount, account type specified by card issuer",
          c007: "Approved, update ICC",
          c100: "Decline (general, no comments)",
          c101: "Decline, expired card",
          c102: "Decline, suspected fraud",
          c103: "Decline, card acceptor contact acquirer",
          c104: "Decline, restricted card",
          c105: "Decline, card acceptor call acquirer's security department",
          c106: "Decline, allowable PIN tries exceeded",
          c107: "Decline, refer to card issuer",
          c108: "Decline, refer to card issuer's special conditions",
          c109: "Decline, invalid merchant",
          c110: "Decline, invalid amount",
          c111: "Decline, invalid card number",
          c112: "Decline, PIN data required",
          c113: "Decline, unacceptable fee",
          c114: "Decline, no account of type requested",
          c115: "Decline, requested function not supported",
          c116: "Decline, not sufficient funds",
          c117: "Decline, incorrect PIN",
          c118: "Decline, no card record",
          c119: "Decline, transaction not permitted to cardholder",
          c120: "Decline, transaction not permitted to terminal",
          c121: "Decline, exceeds withdrawal amount limit",
          c122: "Decline, security violation",
          c123: "Decline, exceeds withdrawal frequency limit",
          c124: "Decline, violation of law",
          c125: "Decline, card not effective",
          c126: "Decline, invalid PIN block",
          c127: "Decline, PIN length error",
          c128: "Decline, PIN kay synch error",
          c129: "Decline, suspected counterfeit card",
          c200: "Pick-up (general, no comments)",
          c201: "Pick-up, expired card",
          c202: "Pick-up, suspected fraud",
          c203: "Pick-up, card acceptor contact card acquirer",
          c204: "Pick-up, restricted card",
          c205: "Pick-up, card acceptor call acquirer's security department",
          c206: "Pick-up, allowable PIN tries exceeded",
          c207: "Pick-up, special conditions",
          c208: "Pick-up, lost card",
          c209: "Pick-up, stolen card",
          c210: "Pick-up, suspected counterfeit card",
          c300: "Status message: file action successful",
          c301: "Status message: file action not supported by receiver",
          c302: "Status message: unable to locate record on file",
          c303: "Status message: duplicate record, old record replaced",
          c304: "Status message: file record field edit error",
          c305: "Status message: file locked out",
          c306: "Status message: file action not successful",
          c307: "Status message: file data format error",
          c308: "Status message: duplicate record, new record rejected",
          c309: "Status message: unknown file",
          c400: "Accepted (for reversal)",
          c500: "Status message: reconciled, in balance",
          c501: "Status message: reconciled, out of balance",
          c502: "Status message: amount not reconciled, totals provided",
          c503: "Status message: totals for reconciliation not available",
          c504: "Status message: not reconciled, totals provided",
          c600: "Accepted (for administrative info)",
          c601: "Status message: impossible to trace back original transaction",
          c602: "Status message: invalid transaction reference number",
          c603: "Status message: reference number/PAN incompatible",
          c604: "Status message: POS photograph is not available",
          c605: "Status message: requested item supplied",
          c606: "Status message: request cannot be fulfilled - required documentation is not available",
          c700: "Accepted (for fee collection)",
          c800: "Accepted (for network management)",
          c900: "Advice acknowledged, no financial liability accepted",
          c901: "Advice acknowledged, finansial liability accepted",
          c902: "Decline reason message: invalid transaction",
          c903: "Status message: re-enter transaction",
          c904: "Decline reason message: format error",
          c905: "Decline reason message: acqiurer not supported by switch",
          c906: "Decline reason message: cutover in process",
          c907: "Decline reason message: card issuer or switch inoperative",
          c908: "Decline reason message: transaction destination cannot be found for routing",
          c909: "Decline reason message: system malfunction",
          c910: "Decline reason message: card issuer signed off",
          c911: "Decline reason message: card issuer timed out",
          c912: "Decline reason message: card issuer unavailable",
          c913: "Decline reason message: duplicate transmission",
          c914: "Decline reason message: not able to trace back to original transaction",
          c915: "Decline reason message: reconciliation cutover or checkpoint error",
          c916: "Decline reason message: MAC incorrect",
          c917: "Decline reason message: MAC key sync error",
          c918: "Decline reason message: no communication keys available for use",
          c919: "Decline reason message: encryption key sync error",
          c920: "Decline reason message: security software/hardware error - try again",
          c921: "Decline reason message: security software/hardware error - no action",
          c922: "Decline reason message: message number out of sequence",
          c923: "Status message: request in progress",
          c940: "Decline, blocked by fraud filter",
          c950: "Decline reason message: violation of business arrangement",
          c198: "Declined, call Card Processing Centre",
          c197: "Declined, call AmEx"
        }

        def initialize response_parameters
          self.parameters=response_parameters
        end

        def ok?
          result == "OK"
        end

        def success?
          ok?
        end

        def recurring?
          recc_pmnt_id.present? && recc_pmnt_expiry.present?
        end

        def result
          parameters[:result]
        end

        def authorization
          transaction_id
        end

        def transaction_id
          parameters[:transaction_id]
        end

        def result_code
          parameters[:result_code]
        end

        def recc_pmnt_id
          parameters[:recc_pmnt_id]
        end

        def recc_pmnt_expiry
          parameters[:recc_pmnt_expiry]
        end

        def three_dee_secure
          parameters[:'3dsecure']
        end

        def message
          result_text
        end

        def result_message
          result_text
        end

        def result_text
          FDL_RESPONSE_CODES["c#{result_code}".to_sym]
        end

        def []
          parameters
        end

        def [](value)
          parameters[value]
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
