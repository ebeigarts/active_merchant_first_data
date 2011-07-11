require "spec_helper"

describe ActiveMerchant::Billing::FirstDataGateway do
  before do
    if ENV['MERCHANT_ID']
      @gateway = ActiveMerchant::Billing::FirstDataGateway.new(
        :pem => File.read("#{File.dirname(__FILE__)}/../../certs/#{ENV['MERCHANT_ID']}_keystore.pem"),
        :pem_password => ENV['PEM_PASSWORD']
      )
    else
      @gateway = ActiveMerchant::Billing::FirstDataGateway.new(:pem => nil, :pem_password => nil)
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
      :cardnr => '5437551000000012',
      :validMONTH => '01',
      :validYEAR => @valid_year,
      :cvc2 => '589'
    }
  end

  it "should be present" do
    @gateway.should be_present
  end

  it "should be in test mode" do
    @gateway.test?.should be_true
  end

  it "should not purchase for 10 Ls without IP" do
    lambda {
      response = @gateway.purchase(1000)
      # response.should have_key(:error)
    }.should raise_error
  end

  describe "Remote" do

    it "1) should purchase for 10 Ls (Visa)" do
      VCR.use_cassette('remote_1_purchase') do
        response = @gateway.purchase(1000, :client_ip_addr => @valid_ip)
        response[:transaction_id].should =~ @valid_response[:trans_id]
        @trans_id = response[:transaction_id]
      end

      VCR.use_cassette('remote_1_result_created') do
        response = @gateway.result(@trans_id, :client_ip_addr => @valid_ip)
        response[:result].should == "CREATED"
      end

      enter_credit_card_data(@trans_id, @visa_card_params)

      VCR.use_cassette('remote_1_result_ok') do
        response = @gateway.result(@trans_id, :client_ip_addr => @valid_ip)
        response[:result].should == "OK"
        response[:result_code].should == "000"
      end

      VCR.use_cassette('remote_1_credit') do
        response = @gateway.credit(1000, @trans_id)
        response[:result].should == "OK"
        response[:result_code].should == "400"
      end
    end

    it "2) should purchase for 10 Ls (Master)" do
      VCR.use_cassette('remote_2_purchase') do
        response = @gateway.purchase(1000, :client_ip_addr => @valid_ip)
        response[:transaction_id].should =~ @valid_response[:trans_id]
        @trans_id = response[:transaction_id]
      end

      VCR.use_cassette('remote_2_result_created') do
        response = @gateway.result(@trans_id, :client_ip_addr => @valid_ip)
        response[:result].should == "CREATED"
      end

      enter_credit_card_data(@trans_id, @master_card_params)

      VCR.use_cassette('remote_2_result_ok') do
        response = @gateway.result(@trans_id, :client_ip_addr => @valid_ip)
        response[:result].should == "OK"
        response[:result_code].should == "000"
      end
    end

    it "3) should authorize and capture 10 Ls (Visa)" do
      VCR.use_cassette('remote_3_authorize') do
        response = @gateway.authorize(1000, :client_ip_addr => @valid_ip)
        response[:transaction_id].should =~ @valid_response[:trans_id]
        @trans_id = response[:transaction_id]
      end

      VCR.use_cassette('remote_3_result_created') do
        response = @gateway.result(@trans_id, :client_ip_addr => @valid_ip)
        response[:result].should == "CREATED"
      end

      enter_credit_card_data(@trans_id, @visa_card_params)

      VCR.use_cassette('remote_3_result_ok') do
        response = @gateway.result(@trans_id, :client_ip_addr => @valid_ip)
        response[:result].should == "OK"
        response[:result_code].should == "000"
      end

      VCR.use_cassette('remote_3_capture') do
        response = @gateway.capture(1000, @trans_id, :client_ip_addr => @valid_ip)
        response[:result].should == "OK"
        response[:result_code].should == "000"
      end

      # # Laikam nav tāds pakalpojums
      # response = @gateway.credit(1000, @trans_id)
      # response[:result].should == "OK"
      # response[:result_code].should == "400"
    end

    it "4) should authorize and capture 10 Ls (Master)" do
      VCR.use_cassette('remote_4_authorize') do
        response = @gateway.authorize(1000, :client_ip_addr => @valid_ip)
        response[:transaction_id].should =~ @valid_response[:trans_id]
        @trans_id = response[:transaction_id]
      end

      VCR.use_cassette('remote_4_result_created') do
        response = @gateway.result(@trans_id, :client_ip_addr => @valid_ip)
        response[:result].should == "CREATED"
      end

      enter_credit_card_data(@trans_id, @master_card_params)

      VCR.use_cassette('remote_4_result_ok') do
        response = @gateway.result(@trans_id, :client_ip_addr => @valid_ip)
        response[:result].should == "OK"
        response[:result_code].should == "000"
      end

      VCR.use_cassette('remote_4_capture') do
        response = @gateway.capture(1000, @trans_id, :client_ip_addr => @valid_ip)
        response[:result].should == "OK"
        response[:result_code].should == "000"
      end
    end

    it "5) should be invalid with incorrect exp date" do
      VCR.use_cassette('remote_5_purchase') do
        response = @gateway.purchase(1000, :client_ip_addr => @valid_ip)
        response[:transaction_id].should =~ @valid_response[:trans_id]
        @trans_id = response[:transaction_id]
      end

      enter_credit_card_data(@trans_id, @visa_card_params.merge!({
        :validMONTH => '12',
        :validYEAR => '12'
      }))

      VCR.use_cassette('remote_5_result_failed') do
        response = @gateway.result(@trans_id, :client_ip_addr => @valid_ip)
        response[:result].should == "FAILED"
      end
    end

    # Laikam nav tāds piesēgts
    it "6) should have successful 3D-Secure authentication" do
      VCR.use_cassette('remote_6_purchase') do
        response = @gateway.purchase(1000, :client_ip_addr => @valid_ip)
        response[:transaction_id].should =~ @valid_response[:trans_id]
        @trans_id = response[:transaction_id]
      end

      enter_credit_card_data(@trans_id, @master_card_params.merge!({
        :cardnr => '5437551000000014'
      }))

      VCR.use_cassette('remote_6_result_created') do
        response = @gateway.result(@trans_id, :client_ip_addr => @valid_ip)
        response[:result].should == "CREATED"
        response[:'3dsecure'].should == 'FAILED'
      end
    end

    it "7) should have unsuccessful 3D-Secure authentication" do
      VCR.use_cassette('remote_7_purchase') do
        response = @gateway.purchase(1000, :client_ip_addr => @valid_ip)
        response[:transaction_id].should =~ @valid_response[:trans_id]
        @trans_id = response[:transaction_id]
      end

      enter_credit_card_data(@trans_id, @master_card_params.merge!({
        :cardnr => '4314220000000032',
        :cvc2 => '213'
      }))

      VCR.use_cassette('remote_7_result_created') do
        response = @gateway.result(@trans_id, :client_ip_addr => @valid_ip)
        response[:result].should == "CREATED"
        response[:'3dsecure'].should == 'FAILED'
      end
    end

    it "8) should have 3D-Secure authentication error" do
      VCR.use_cassette('remote_8_purchase') do
        response = @gateway.purchase(1000, :client_ip_addr => @valid_ip)
        response[:transaction_id].should =~ @valid_response[:trans_id]
        @trans_id = response[:transaction_id]
      end

      enter_credit_card_data(@trans_id, @master_card_params.merge!({
        :cardnr => '4314220000000031',
        :cvc2 => '123'
      }))

      VCR.use_cassette('remote_8_result_created') do
        response = @gateway.result(@trans_id, :client_ip_addr => @valid_ip)
        response[:result].should == "CREATED"
        response[:'3dsecure'].should == 'FAILED'
      end
    end

    it "9) should have blacklisted IP" do
      VCR.use_cassette('remote_9_purchase_blacklist') do
        lambda {
          response = @gateway.purchase(1000, :client_ip_addr => @blocked_ip)
          # response.should have_key(:error)
        }.should raise_error
      end
    end

    it "10) reversal for SMS authorization from case '1'" do
      VCR.use_cassette('remote_10_purchase') do
        response = @gateway.purchase(1000, :client_ip_addr => @valid_ip)
        response[:transaction_id].should =~ @valid_response[:trans_id]
        @trans_id = response[:transaction_id]
      end

      enter_credit_card_data(@trans_id, @visa_card_params)

      VCR.use_cassette('remote_10_result_ok') do
        response = @gateway.result(@trans_id, :client_ip_addr => @valid_ip)
        response[:result].should == "OK"
        response[:result_code].should == "000"
      end

      VCR.use_cassette('remote_10_credit') do
        response = @gateway.credit(1000, @trans_id)
        response[:result].should == "OK"
        response[:result_code].should == "400"
      end
    end

    it "11) reversal for DMS transaction from case '3'" do
      VCR.use_cassette('remote_11_authorize') do
        response = @gateway.authorize(1000, :client_ip_addr => @valid_ip)
        response[:transaction_id].should =~ @valid_response[:trans_id]
        @trans_id = response[:transaction_id]
      end

      enter_credit_card_data(@trans_id, @visa_card_params)

      VCR.use_cassette('remote_11_result_ok') do
        response = @gateway.result(@trans_id, :client_ip_addr => @valid_ip)
        response[:result].should == "OK"
        response[:result_code].should == "000"
      end

      VCR.use_cassette('remote_11_capture') do
        response = @gateway.capture(1000, @trans_id, :client_ip_addr => @valid_ip)
        response[:result].should == "OK"
        response[:result_code].should == "000"
      end

      VCR.use_cassette('remote_11_credit') do
        response = @gateway.credit(1000, @trans_id)
        response[:result].should == "OK"
        response[:result_code].should == "400"
      end
    end

    it "12) should close business day" do
      VCR.use_cassette('remote_12_close_business_day') do
        response = @gateway.close_day
        response[:result].should == "OK"
        response[:result_code].should == "500"
      end
    end
  end

  def submit_form(url, params = {})
    ActiveMerchant::Billing::FirstDataGateway.logger.debug "SUBMIT_FORM: #{url}, params: #{params.inspect}"
    uri = URI.parse(url)
    VCR.use_cassette("submit_#{uri.request_uri}_#{params.values.sort.join('_')}".downcase.parameterize('_')[0,90]) do
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
  def enter_credit_card_data(trans_id, params = {})
    redirect_uri = URI(ActiveMerchant::Billing::FirstDataGateway.test_redirect_url)
    params.reverse_merge!({
      :trans_id => trans_id,
      :cardname => "TEST"
    })
    response_body = submit_form(redirect_uri.to_s, params)
    response_body.should =~ /PAYMENT TRANSACTION PROCESSING/

    # second, ... form
    while response_body =~ /action="([^"]+)/
      url = $1
      if url.start_with?("/")
        url = redirect_uri.scheme + "://" + redirect_uri.host + url
      end
      ActiveMerchant::Billing::FirstDataGateway.logger.debug "URL:" + url.to_s
      # break if we are redirecting back
      break unless url.include?(redirect_uri.host)
      # get input field names, values into params
      params = {}
      response_body.split(/input/i).collect{ |input| input.scan(/name="([^\"]*)".*value="([^\"]*)"/i).flatten }.reject(&:blank?).
        each { |k, v| params[k] = v }
      response_body = submit_form(url, params)
    end
  end
end
