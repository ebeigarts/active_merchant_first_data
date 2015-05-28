# rspec spec/active_merchant/billing/first_data/gateway_spec.rb
require "spec_helper"

describe ActiveMerchant::Billing::FirstData::Gateway do
  before do
    if ENV['MERCHANT_ID']
      @gateway = ActiveMerchant::Billing::FirstData::Gateway.new(
        :pem => File.read("#{File.dirname(__FILE__)}/../../certs/#{ENV['MERCHANT_ID']}_keystore.pem"),
        :pem_password => ENV['PEM_PASSWORD']
      )
    else
      @gateway = ActiveMerchant::Billing::FirstData::Gateway.new(:pem => nil, :pem_password => nil)
    end

    @valid_ip = '127.0.0.1'
    @blocked_ip = '192.168.1.2'

    @valid_year = '13'

    @valid_response = {
      :trans_id => /^.{28}$/
    }

    @visa_card_params = {
      :cardnr => "4314229999999913",
      :validMONTH => '01',
      :validYEAR => @valid_year,
      :cvc2 => '123'
    }

    @master_card_params = {
      :cardnr => '5437551000000014',
      :validMONTH => '01',
      :validYEAR => @valid_year,
      :cvc2 => '589'
    }

    @master_card_params_2 = {
      :cardnr => '5437551000000020',
      :validMONTH => '01',
      :validYEAR => @valid_year,
      :cvc2 => '589'
    }
  end

  it "should be present" do
    expect(@gateway.present?).to be true
  end

  it "should be in test mode" do
    expect(@gateway.test?).to eq true
  end

  it "should not purchase for 10 EUR without IP" do
    expect { response = @gateway.purchase(1000) }.to raise_error
  end

  describe "Remote" do

    it "1) should purchase for 10 EUR (Visa)" do
      VCR.use_cassette('remote_1_purchase') do
        response = @gateway.purchase(1000, :client_ip_addr => @valid_ip)
        expect(response[:transaction_id]).to match @valid_response[:trans_id]
        @trans_id = response[:transaction_id]
      end

      VCR.use_cassette('remote_1_result_created') do
        response = @gateway.result(@trans_id, :client_ip_addr => @valid_ip)
        expect(response[:result]).to eq "CREATED"
      end

      enter_credit_card_data(@trans_id, @visa_card_params)

      VCR.use_cassette('remote_1_result_ok') do
        response = @gateway.result(@trans_id, :client_ip_addr => @valid_ip)

        expect(response[:result]).to eq "OK"
        expect(response[:result_code]).to eq "000"
      end

      VCR.use_cassette('remote_1_credit') do
        response = @gateway.refund(1000, @trans_id)


        expect(response[:result]).to eq "OK"
        expect(response[:result_code]).to eq "400"
      end
    end

    it "2) should purchase for 10 EUR (Master)" do
      VCR.use_cassette('remote_2_purchase') do
        response = @gateway.purchase(1000, :client_ip_addr => @valid_ip)
        expect(response[:transaction_id]).to match @valid_response[:trans_id]
        @trans_id = response[:transaction_id]
      end

      VCR.use_cassette('remote_2_result_created') do
        response = @gateway.result(@trans_id, :client_ip_addr => @valid_ip)
        expect(response[:result]).to eq "CREATED"
      end

      enter_credit_card_data(@trans_id, @master_card_params)

      VCR.use_cassette('remote_2_result_ok') do
        response = @gateway.result(@trans_id, :client_ip_addr => @valid_ip)
        expect(response[:result]).to eq "OK"
        expect(response[:result_code]).to eq "000"
      end
    end

    it "3) should authorize and capture 10 EUR (Visa)" do
      VCR.use_cassette('remote_3_authorize') do
        response = @gateway.authorize(1000, :client_ip_addr => @valid_ip)
        expect(response[:transaction_id]).to match @valid_response[:trans_id]
        @trans_id = response[:transaction_id]
      end

      VCR.use_cassette('remote_3_result_created') do
        response = @gateway.result(@trans_id, :client_ip_addr => @valid_ip)
        expect(response[:result]).to eq "CREATED"
      end

      enter_credit_card_data(@trans_id, @visa_card_params)

      VCR.use_cassette('remote_3_result_ok') do
        response = @gateway.result(@trans_id, :client_ip_addr => @valid_ip)
        expect(response[:result]).to eq "OK"
        expect(response[:result_code]).to eq "000"
      end

      VCR.use_cassette('remote_3_capture') do
        response = @gateway.capture(1000, @trans_id, :client_ip_addr => @valid_ip)
        expect(response[:result]).to eq "OK"
        expect(response[:result_code]).to eq "000"
      end
    end

    it "4) should authorize and capture 10 EUR (Master)" do
      VCR.use_cassette('remote_4_authorize') do
        response = @gateway.authorize(1000, :client_ip_addr => @valid_ip)
        expect(response[:transaction_id]).to match @valid_response[:trans_id]
        @trans_id = response[:transaction_id]
      end

      VCR.use_cassette('remote_4_result_created') do
        response = @gateway.result(@trans_id, :client_ip_addr => @valid_ip)
        expect(response[:result]).to eq "CREATED"
      end

      enter_credit_card_data(@trans_id, @master_card_params)

      VCR.use_cassette('remote_4_result_ok') do
        response = @gateway.result(@trans_id, :client_ip_addr => @valid_ip)
        expect(response[:result]).to eq "OK"
        expect(response[:result_code]).to eq "000"
      end

      VCR.use_cassette('remote_4_capture') do
        response = @gateway.capture(1000, @trans_id, :client_ip_addr => @valid_ip)
        expect(response[:result]).to eq "OK"
        expect(response[:result_code]).to eq "000"
      end
    end

    it "5) should be invalid with incorrect exp date" do
      VCR.use_cassette('remote_5_purchase') do
        response = @gateway.purchase(1000, :client_ip_addr => @valid_ip)
        expect(response[:transaction_id]).to match @valid_response[:trans_id]
        @trans_id = response[:transaction_id]
      end

      enter_credit_card_data(@trans_id, @visa_card_params.merge!({
        :validMONTH => '12',
        :validYEAR => '12'
      }))

      VCR.use_cassette('remote_5_result_failed') do
        response = @gateway.result(@trans_id, :client_ip_addr => @valid_ip)
        expect(response[:result]).to eq "FAILED"
      end
    end

    it "6) should have successful 3D-Secure authentication" do
      VCR.use_cassette('remote_6_purchase') do
        response = @gateway.purchase(1000, :client_ip_addr => @valid_ip)
        expect(response[:transaction_id]).to match @valid_response[:trans_id]
        @trans_id = response[:transaction_id]
      end

      enter_credit_card_data(@trans_id, @master_card_params.merge!({
        :cardnr => '5437551000000014'
      }))

      VCR.use_cassette('remote_6_result_created') do
        response = @gateway.result(@trans_id, :client_ip_addr => @valid_ip)
        expect(response[:result]).to eq "OK"
        expect(response[:'3dsecure']).to eq "AUTHENTICATED"
      end
    end

    it "7) should have unsuccessful 3D-Secure authentication" do
      VCR.use_cassette('remote_7_purchase') do
        response = @gateway.purchase(1000, :client_ip_addr => @valid_ip)
        expect(response[:transaction_id]).to match @valid_response[:trans_id]
        @trans_id = response[:transaction_id]
      end

      enter_credit_card_data(@trans_id, @master_card_params.merge!({
        :cardnr => '4314220000000032',
        :cvc2 => '213'
      }))

      VCR.use_cassette('remote_7_result_created') do
        response = @gateway.result(@trans_id, :client_ip_addr => @valid_ip)
        expect(response[:result]).to eq "DECLINED"
        expect(response[:'3dsecure']).to eq "DECLINED"
      end
    end

    it "8) should have 3D-Secure authentication error" do
      VCR.use_cassette('remote_8_purchase') do
        response = @gateway.purchase(1000, :client_ip_addr => @valid_ip)
        expect(response[:transaction_id]).to match @valid_response[:trans_id]
        @trans_id = response[:transaction_id]
      end

      enter_credit_card_data(@trans_id, @master_card_params.merge!({
        :cardnr => '4314220000000031',
        :cvc2 => '123'
      }))

      VCR.use_cassette('remote_8_result_created') do
        response = @gateway.result(@trans_id, :client_ip_addr => @valid_ip)
        expect(response[:result]).to eq "DECLINED"
        expect(response[:'3dsecure']).to eq "DECLINED"
      end
    end

    it "9) should have blacklisted IP" do
      VCR.use_cassette('remote_9_purchase_blacklist') do
        expect { response = @gateway.purchase(1000, :client_ip_addr => @blocked_ip) }.to raise_error
      end
    end

    it "10) reversal for SMS authorization from case '1'" do
      VCR.use_cassette('remote_10_purchase') do
        response = @gateway.purchase(1000, :client_ip_addr => @valid_ip)
        expect(response[:transaction_id]).to match @valid_response[:trans_id]
        @trans_id = response[:transaction_id]
      end

      enter_credit_card_data(@trans_id, @visa_card_params)

      VCR.use_cassette('remote_10_result_ok') do
        response = @gateway.result(@trans_id, :client_ip_addr => @valid_ip)
        expect(response[:result]).to eq "OK"
        expect(response[:result_code]).to eq "000"
      end

      VCR.use_cassette('remote_10_credit') do
        response = @gateway.refund(1000, @trans_id)
        expect(response[:result]).to eq "OK"
        expect(response[:result_code]).to eq "400"
      end
    end

    it "11) reversal for DMS transaction from case '3'" do
      VCR.use_cassette('remote_11_authorize') do
        response = @gateway.authorize(1000, :client_ip_addr => @valid_ip)
        expect(response[:transaction_id]).to match @valid_response[:trans_id]
        @trans_id = response[:transaction_id]
      end

      enter_credit_card_data(@trans_id, @visa_card_params)

      VCR.use_cassette('remote_11_result_ok') do
        response = @gateway.result(@trans_id, :client_ip_addr => @valid_ip)
        puts "Response"
        puts response.inspect
        puts response.class
        expect(response[:result]).to eq "OK"
        expect(response[:result_code]).to eq "000"
      end

      VCR.use_cassette('remote_11_capture') do
        response = @gateway.capture(1000, @trans_id, :client_ip_addr => @valid_ip)
        expect(response[:result]).to eq "OK"
        expect(response[:result_code]).to eq "000"
      end

      VCR.use_cassette('remote_11_credit') do
        response = @gateway.refund(1000, @trans_id)
        expect(response[:result]).to eq "OK"
        expect(response[:result_code]).to eq "400"
      end
    end

    it "12) should close business day" do
      VCR.use_cassette('remote_12_close_business_day') do
        response = @gateway.close_day
        expect(response[:result]).to eq "OK"
        expect(response[:result_code]).to eq "500"
      end
    end
  end


  describe "Recurring" do
    before(:each) do
      @prefix = 'test1'
      # uncomment to generate unique biller_client_id
      # @prefix = Time.now.to_i.to_s
    end

    it "13) should register recurring payment with 3D-Secure authentication" do
      @biller_client_id = @prefix + '_13'
      VCR.use_cassette('remote_13_recurring') do
        response = @gateway.recurring(1000,
          :currency => 'EUR',
          :client_ip_addr => @valid_ip,
          :description => 'monthly subscription #13',
          :biller_client_id => @biller_client_id,
          :perspayee_expiry => '1222' # December 2022
        )
        expect(response[:transaction_id]).to match @valid_response[:trans_id]
        @trans_id = response[:transaction_id]
      end

      VCR.use_cassette('remote_13_result_created') do
        response = @gateway.result(@trans_id, :client_ip_addr => @valid_ip)
        expect(response[:result]).to eq "CREATED"
      end

      enter_credit_card_data(@trans_id, @master_card_params, 'submit_13')

      VCR.use_cassette('remote_13_result_ok') do
        response = @gateway.result(@trans_id, :client_ip_addr => @valid_ip)
        expect(response[:result]).to eq "OK"
        expect(response[:result_code]).to eq "000"
        expect(response[:recc_pmnt_id]).to eq @biller_client_id
        expect(response[:recc_pmnt_expiry]).to eq @master_card_params[:validMONTH] + @master_card_params[:validYEAR]
      end
    end

    it "14) should register recurring payment with non-3D" do
      @biller_client_id = @prefix + '_14'
      VCR.use_cassette('remote_14_recurring') do
        response = @gateway.recurring(1000,
          :currency => 'EUR',
          :client_ip_addr => @valid_ip,
          :description => 'monthly subscription #14',
          :biller_client_id => @biller_client_id,
          :perspayee_expiry => '0119' # January 2019
        )
        expect(response[:transaction_id]).to match @valid_response[:trans_id]
        @trans_id = response[:transaction_id]
      end

      VCR.use_cassette('remote_14_result_created') do
        response = @gateway.result(@trans_id, :client_ip_addr => @valid_ip)
        expect(response[:result]).to eq "CREATED"
      end

      enter_credit_card_data(@trans_id, @visa_card_params, 'submit_14')

      VCR.use_cassette('remote_14_result_ok') do
        response = @gateway.result(@trans_id, :client_ip_addr => @valid_ip)
        expect(response[:result]).to eq "OK"
        expect(response[:result_code]).to eq "000"
        expect(response[:recc_pmnt_id]).to eq @biller_client_id
        expect(response[:recc_pmnt_expiry]).to eq @visa_card_params[:validMONTH] + @visa_card_params[:validYEAR]
      end
    end

    it "15) should not register recurring payment with too large amount" do
      @biller_client_id = @prefix + '_15'
      VCR.use_cassette('remote_15_recurring') do
        response = @gateway.recurring(9999,
          :currency => 'EUR',
          :client_ip_addr => @valid_ip,
          :description => 'monthly subscription #15',
          :biller_client_id => @biller_client_id,
          :perspayee_expiry => '0119' # January 2019
        )
        expect(response[:transaction_id]).to match @valid_response[:trans_id]
        @trans_id = response[:transaction_id]
      end

      VCR.use_cassette('remote_15_result_created') do
        response = @gateway.result(@trans_id, :client_ip_addr => @valid_ip)
        expect(response[:result]).to eq "CREATED"
      end

      enter_credit_card_data(@trans_id, @visa_card_params, 'submit_15')

      VCR.use_cassette('remote_15_result_failed') do
        response = @gateway.result(@trans_id, :client_ip_addr => @valid_ip)
        expect(response[:result]).to eq "FAILED"
        expect(response[:result_code]).to eq "100"
        expect(response[:recc_pmnt_id]).to eq @biller_client_id
        expect(response[:recc_pmnt_expiry]).to eq @visa_card_params[:validMONTH] + @visa_card_params[:validYEAR]
      end
    end

    it "16) should execute recurring payment from test case 13" do
      @biller_client_id = @prefix + '_16'
      VCR.use_cassette('remote_16_recurring') do
        response = @gateway.recurring(1000,
          :currency => 'EUR',
          :client_ip_addr => @valid_ip,
          :description => 'monthly subscription #16',
          :biller_client_id => @biller_client_id,
          :perspayee_expiry => '1222' # December 2022
        )
        expect(response[:transaction_id]).to match @valid_response[:trans_id]
        @trans_id = response[:transaction_id]
      end

      enter_credit_card_data(@trans_id, @master_card_params, 'submit_16')

      VCR.use_cassette('remote_16_result_ok') do
        response = @gateway.result(@trans_id, :client_ip_addr => @valid_ip)
        expect(response[:result]).to eq "OK"
      end

      VCR.use_cassette('remote_16_execute_ok') do
        response = @gateway.execute_recurring(1000,
          :currency => 'EUR',
          :client_ip_addr => @valid_ip,
          :description => 'next monthly subscription #16',
          :biller_client_id => @biller_client_id
        )
        expect(response[:result]).to eq "OK"
        expect(response[:result_code]).to eq "000"
      end

    end

    it "17) should not execute recurring payment with too large amount from test case 14" do
      @biller_client_id = @prefix + '_17'
      VCR.use_cassette('remote_17_recurring') do
        response = @gateway.recurring(1000,
          :currency => 'EUR',
          :client_ip_addr => @valid_ip,
          :description => 'monthly subscription #17',
          :biller_client_id => @biller_client_id,
          :perspayee_expiry => '0119' # January 2019
        )
        expect(response[:transaction_id]).to match @valid_response[:trans_id]
        @trans_id = response[:transaction_id]
      end

      VCR.use_cassette('remote_17_result_created') do
        response = @gateway.result(@trans_id, :client_ip_addr => @valid_ip)
        expect(response[:result]).to eq "CREATED"
      end

      enter_credit_card_data(@trans_id, @visa_card_params, 'submit_17')

      VCR.use_cassette('remote_17_result_ok') do
        response = @gateway.result(@trans_id, :client_ip_addr => @valid_ip)
        expect(response[:result]).to eq "OK"
      end

      VCR.use_cassette('remote_17_execute_failed') do
        response = @gateway.execute_recurring(9999,
          :currency => 'EUR',
          :client_ip_addr => @valid_ip,
          :description => 'next monthly subscription #17',
          :biller_client_id => @biller_client_id
        )
        expect(response[:result]).to eq "FAILED"
        expect(response[:result_code]).to eq "100"
      end

    end

    # it "18) should register recurring payment with non-3D" do
    #   pending "does not test anything new"
    # end

    it "19) should delete recurring payment from test case 14" do
      @biller_client_id = @prefix + '_19'
      VCR.use_cassette('remote_19_recurring') do
        response = @gateway.recurring(1000,
          :currency => 'EUR',
          :client_ip_addr => @valid_ip,
          :description => 'monthly subscription #19',
          :biller_client_id => @biller_client_id,
          :perspayee_expiry => '0119' # January 2019
        )
        expect(response[:transaction_id]).to match @valid_response[:trans_id]
        @trans_id = response[:transaction_id]
      end

      enter_credit_card_data(@trans_id, @master_card_params, 'submit_19')

      VCR.use_cassette('remote_19_result_ok') do
        response = @gateway.result(@trans_id, :client_ip_addr => @valid_ip)
        expect(response[:result]).to eq "OK"
      end

      VCR.use_cassette('remote_19_execute_failed') do
        response = @gateway.execute_recurring(9876,
          :currency => 'EUR',
          :client_ip_addr => @valid_ip,
          :description => 'next monthly subscription #19',
          :biller_client_id => @biller_client_id
        )
        expect(response[:result]).to eq "FAILED"
        expect(response[:result_code]).to eq "200"
      end

    end

    it "21) should overwrite card data together with payment" do
      @biller_client_id = @prefix + '_21'
      VCR.use_cassette('remote_21_recurring') do
        response = @gateway.recurring(1000,
          :currency => 'EUR',
          :client_ip_addr => @valid_ip,
          :description => 'monthly subscription #21',
          :biller_client_id => @biller_client_id,
          :perspayee_expiry => '1222' # December 2022
        )
        expect(response[:transaction_id]).to match @valid_response[:trans_id]
        @trans_id = response[:transaction_id]
      end

      VCR.use_cassette('remote_21_result_created') do
        response = @gateway.result(@trans_id, :client_ip_addr => @valid_ip)
        expect(response[:result]).to eq "CREATED"
      end

      enter_credit_card_data(@trans_id, @master_card_params, 'submit_21')

      VCR.use_cassette('remote_21_result_ok') do
        response = @gateway.result(@trans_id, :client_ip_addr => @valid_ip)
        expect(response[:result]).to eq "OK"
      end

      VCR.use_cassette('remote_21_overwrite') do
        response = @gateway.recurring(1000,
          :currency => 'EUR',
          :client_ip_addr => @valid_ip,
          :description => 'updated monthly subscription #21',
          :biller_client_id => @biller_client_id,
          :perspayee_expiry => '1222', # December 2022
          :perspayee_overwrite => 1
        )
        expect(response[:transaction_id]).to match @valid_response[:trans_id]
        @trans_id = response[:transaction_id]
      end

      VCR.use_cassette('remote_21_overwrite_created') do
        response = @gateway.result(@trans_id, :client_ip_addr => @valid_ip)
        expect(response[:result]).to eq "CREATED"
      end

      enter_credit_card_data(@trans_id, @master_card_params_2, 'submit_21')

      VCR.use_cassette('remote_21_overwrite_ok') do
        response = @gateway.result(@trans_id, :client_ip_addr => @valid_ip)
        expect(response[:result]).to eq "OK"
        expect(response[:result_code]).to eq "000"
        expect(response[:recc_pmnt_id]).to eq @biller_client_id
        expect(response[:recc_pmnt_expiry]).to eq @master_card_params_2[:validMONTH] + @master_card_params_2[:validYEAR]
      end

    end

    it "23) should overwrite card data without payment" do
      @biller_client_id = @prefix + '_23'
      VCR.use_cassette('remote_23_recurring') do
        response = @gateway.recurring(1000,
          :currency => 'EUR',
          :client_ip_addr => @valid_ip,
          :description => 'monthly subscription #23',
          :biller_client_id => @biller_client_id,
          :perspayee_expiry => '0119' # January 2019
        )
        expect(response[:transaction_id]).to match @valid_response[:trans_id]
        @trans_id = response[:transaction_id]
      end

      VCR.use_cassette('remote_23_result_created') do
        response = @gateway.result(@trans_id, :client_ip_addr => @valid_ip)
        expect(response[:result]).to eq "CREATED"
      end

      enter_credit_card_data(@trans_id, @visa_card_params, 'submit_23')

      VCR.use_cassette('remote_23_result_ok') do
        response = @gateway.result(@trans_id, :client_ip_addr => @valid_ip)
        expect(response[:result]).to eq "OK"
      end

      VCR.use_cassette('remote_23_overwrite') do
        response = @gateway.update_recurring(
          :currency => 'EUR',
          :client_ip_addr => @valid_ip,
          :description => 'updated monthly subscription #23',
          :biller_client_id => @biller_client_id,
          :perspayee_expiry => '1222' # December 2022
        )
        expect(response[:transaction_id]).to match @valid_response[:trans_id]
        @trans_id = response[:transaction_id]
      end

      VCR.use_cassette('remote_23_overwrite_created') do
        response = @gateway.result(@trans_id, :client_ip_addr => @valid_ip)
        expect(response[:result]).to eq "CREATED"
      end

      enter_credit_card_data(@trans_id, @master_card_params_2, 'submit_23')

      VCR.use_cassette('remote_23_overwrite_ok') do
        response = @gateway.result(@trans_id, :client_ip_addr => @valid_ip)
        expect(response[:result]).to eq "OK"
        expect(response[:result_code]).to eq "000"
        expect(response[:recc_pmnt_id]).to eq @biller_client_id
        expect(response[:recc_pmnt_expiry]).to eq @master_card_params_2[:validMONTH] + @master_card_params_2[:validYEAR]
      end

    end

    it "24) reversal for test case 21" do
      @biller_client_id = @prefix + '_24'
      VCR.use_cassette('remote_24_recurring') do
        response = @gateway.recurring(1000,
          :currency => 'EUR',
          :client_ip_addr => @valid_ip,
          :description => 'monthly subscription #24',
          :biller_client_id => @biller_client_id,
          :perspayee_expiry => '1222' # December 2022
        )
        expect(response[:transaction_id]).to match @valid_response[:trans_id]
        @trans_id = response[:transaction_id]
      end

      VCR.use_cassette('remote_24_result_created') do
        response = @gateway.result(@trans_id, :client_ip_addr => @valid_ip)
        expect(response[:result]).to eq "CREATED"
      end

      enter_credit_card_data(@trans_id, @master_card_params, 'submit_24')

      VCR.use_cassette('remote_24_result_ok') do
        response = @gateway.result(@trans_id, :client_ip_addr => @valid_ip)
        expect(response[:result]).to eq "OK"
      end

      VCR.use_cassette('remote_24_overwrite') do
        response = @gateway.recurring(1000,
          :currency => 'EUR',
          :client_ip_addr => @valid_ip,
          :description => 'updated monthly subscription #24',
          :biller_client_id => @biller_client_id,
          :perspayee_expiry => '1222', # December 2022
          :perspayee_overwrite => 1
        )
        expect(response[:transaction_id]).to match @valid_response[:trans_id]
        @trans_id = response[:transaction_id]
      end

      enter_credit_card_data(@trans_id, @master_card_params_2, 'submit_24')

      VCR.use_cassette('remote_24_overwrite_ok') do
        response = @gateway.result(@trans_id, :client_ip_addr => @valid_ip)
        expect(response[:result]).to eq "OK"
      end

      VCR.use_cassette('remote_24_refund') do
        response = @gateway.refund(1000, @trans_id)
        expect(response[:result]).to eq "OK"
        expect(response[:result_code]).to eq "400"
      end

    end

    it "25) should close business day" do
      VCR.use_cassette('remote_25_close_business_day') do
        response = @gateway.close_day
        expect(response[:result]).to eq "OK"
        expect(response[:result_code]).to eq "500"
      end
    end

    it "26) return correct redirect url with transaction id" do
      expect(@gateway.redirect_url).to eq @gateway.test_redirect_url
    end

    it "27) return correct redirect url without transaction id" do
      expect(@gateway.redirect_url("2SGip+TK/dVYe+XMSeQuECMs//S=")).to eq @gateway.test_redirect_url + "?trans_id=2SGip%2BTK%2FdVYe%2BXMSeQuECMs%2F%2FS%3D"
    end
  end

  def submit_form(url, params, cassette_prefix)
    ActiveMerchant::Billing::FirstData::Gateway.logger.debug "SUBMIT_FORM: #{url}, params: #{params.inspect}"
    uri = URI.parse(url)
    VCR.use_cassette("#{cassette_prefix}_#{uri.request_uri}_#{params.values.sort.join('_')}".downcase.parameterize('_')[0,90]) do
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE
      response = http.post(uri.request_uri, params.collect { |key, value| "#{key}=#{CGI.escape(value.to_s)}" }.join("&"), {})
      # puts "RESPONSE CODE: #{response.code}"
      # puts "RESPONSE BODY: #{response.body}"
      response.body
    end
  end

  # Fills up and submits remote forms.
  def enter_credit_card_data(trans_id, params = {}, cassette_prefix = 'submit')
    redirect_uri = URI(ActiveMerchant::Billing::FirstData::Gateway.test_redirect_url)
    params.reverse_merge!({
      :trans_id => trans_id,
      :cardname => "TEST"
    })
    response_body = submit_form(redirect_uri.to_s, params, cassette_prefix)
    expect(response_body).to match /PAYMENT TRANSACTION PROCESSING/

    # second, ... form
    while response_body =~ /action="([^"]+)/
      url = $1
      if url.start_with?("/")
        url = redirect_uri.scheme + "://" + redirect_uri.host + url
      end
      ActiveMerchant::Billing::FirstData::Gateway.logger.debug "URL:" + url.to_s
      # break if we are redirecting back
      unless url.include?(redirect_uri.host)
        # sleep 5
        break
      end
      # get input field names, values into params
      params = {}
      response_body.split(/input/i).
        collect{ |input| input.scan(/name="([^\"]*)".*value="([^\"]*)"/im).flatten }.
        reject(&:blank?).
        each { |k, v| params[k] = v }
      # 3D Secure password
      if response_body =~ %r{<input type="password" name="password"/>}
        params["password"] = "password"
        params["submit"] = "OK"
      end
      response_body = submit_form(url, params, cassette_prefix)
      # puts response_body
    end
  end
end
