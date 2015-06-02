# rspec spec/active_merchant/billing/first_data/response_spec.rb
require "spec_helper"

describe ActiveMerchant::Billing::FirstData::Response do

  before :all do
    @transaction_id = "e+oClP4em8uBDozaZ4CBBbipEcM="
    @recc_pmnt_id = "test123"
    @recc_pmnt_expiry = "0120"

    @result_ok = "OK"
    @result_created = "CREATED"

    @result_code = "000"
    @three_dee_secure = "AUTHENTICATED"
  end

  context "backwards compatability" do
    before :all do
      @response_hash = ActiveSupport::HashWithIndifferentAccess.new
      @response_hash[:transaction_id] = @transaction_id
      @response_hash[:result_code] = @result_code

      @response_old_style = ActiveMerchant::Billing::FirstDataResponse.new @response_hash
    end

    it "should be able to access transaction_id from response object as would from hash" do
      expect(@response_old_style[:transaction_id]).to eq @transaction_id
    end

    it "should be return correct result message" do
      expect(@response_old_style.result_message).to eq "Approved"
    end

  end

  context "basic" do
    before :all do
      @response_hash = ActiveSupport::HashWithIndifferentAccess.new

      @response_hash[:transaction_id] = @transaction_id
      @response_hash[:result] = @result_ok
      @response_hash[:result_code] = @result_code
      @response_hash[:result] = @result_created
      @response_hash[:recc_pmnt_id] = @recc_pmnt_id
      @response_hash[:recc_pmnt_expiry] = @recc_pmnt_expiry
      @response_hash[:'3dsecure'] = @three_dee_secure

      @response = ActiveMerchant::Billing::FirstData::Response.new @response_hash
    end

    it "should return same parameters as passed" do
      expect(@response.parameters).to eq @response_hash
    end

    it "should return transaction_id" do
      expect(@response.transaction_id).to eq @transaction_id
    end

    it "should return transaction_id" do
      expect(@response.three_dee_secure).to eq @three_dee_secure
    end

    it "should return correct result for response" do
      expect(@response.result_code).to eq @result_code
    end

    it "should return result_text Approved for result_code 000" do
      expect(@response.result_text).to eq "Approved"
    end

  end

  context "business logic methods" do
    context "result" do
      before :all do
        @ok_response_hash = ActiveSupport::HashWithIndifferentAccess.new
        @nok_response_hash = ActiveSupport::HashWithIndifferentAccess.new

        @ok_response_hash[:result] = @result_ok
        @nok_response_hash[:result] = @result_created

        @ok_response = ActiveMerchant::Billing::FirstData::Response.new @ok_response_hash
        @nok_response = ActiveMerchant::Billing::FirstData::Response.new @nok_response_hash
      end

      it "should be ok if result is ok" do
        expect(@ok_response.ok?).to eq true
      end

      it "other than ok should not be ok" do
        expect(@nok_response.ok?).to eq false
      end

      it "should return correct result for ok response" do
        expect(@ok_response.result).to eq @result_ok
      end

      it "should return correct result for ok response" do
        expect(@nok_response.result).to eq @result_created
      end
    end

    context "recurring" do
      before :all do
        @ok_response_hash = ActiveSupport::HashWithIndifferentAccess.new
        @nok_response_hash = ActiveSupport::HashWithIndifferentAccess.new

        @ok_response_hash[:recc_pmnt_id] = @recc_pmnt_id
        @ok_response_hash[:recc_pmnt_expiry] = @recc_pmnt_expiry

        @ok_response = ActiveMerchant::Billing::FirstData::Response.new @ok_response_hash
        @nok_response = ActiveMerchant::Billing::FirstData::Response.new @nok_response_hash
      end

      it "should be recurring if recc_pmnt_id and recc_pmnt_expiry present" do
        expect(@ok_response.recurring?).to eq true
      end

      it "should return false if there is no recc_pmnt_id and recc_pmnt_expiry" do
        expect(@nok_response.recurring?).to eq false
      end

      it "should match value for recc_pmnt_id for recurring response" do
        expect(@ok_response.recc_pmnt_id).to eq @recc_pmnt_id
      end

      it "should match value for recc_pmnt_expiry for recurring response" do
        expect(@ok_response.recc_pmnt_expiry).to eq @recc_pmnt_expiry
      end

      it "should not return value for recc_pmnt_id for recurring response" do
        expect(@nok_response.recc_pmnt_id).to eq nil
      end

      it "should not return value for recc_pmnt_expiry for recurring response" do
        expect(@nok_response.recc_pmnt_expiry).to eq nil
      end
    end
  end
end
