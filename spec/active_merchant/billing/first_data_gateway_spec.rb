require "spec_helper"

describe ActiveMerchant::Billing::FirstDataGateway do
  # use_vcr_cassette "first_data_gateway"

  before do
    @gateway = ActiveMerchant::Billing::FirstDataGateway.new(
      :pem => File.read("#{File.dirname(__FILE__)}/../../certs/#{ENV['MERCHANT_ID']}_keystore.pem"),
      :pem_password => ENV['PEM_PASSWORD']
    )

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
      response = @gateway.purchase(1000, :client_ip_addr => @valid_ip)
      response[:transaction_id].should =~ @valid_response[:trans_id]
      @trans_id = response[:transaction_id]

      response = @gateway.result(@trans_id, :client_ip_addr => @valid_ip)
      response[:result].should == "CREATED"

      enter_credit_card_data(@trans_id, @visa_card_params)

      response = @gateway.result(@trans_id, :client_ip_addr => @valid_ip)
      response[:result].should == "OK"
      response[:result_code].should == "000"

      response = @gateway.credit(1000, @trans_id)
      response[:result].should == "OK"
      response[:result_code].should == "400"
    end

    it "2) should purchase for 10 Ls (Master)" do
      response = @gateway.purchase(1000, :client_ip_addr => @valid_ip)
      response[:transaction_id].should =~ @valid_response[:trans_id]
      @trans_id = response[:transaction_id]

      response = @gateway.result(@trans_id, :client_ip_addr => @valid_ip)
      response[:result].should == "CREATED"

      enter_credit_card_data(@trans_id, @master_card_params)

      response = @gateway.result(@trans_id, :client_ip_addr => @valid_ip)
      response[:result].should == "OK"
      response[:result_code].should == "000"
    end

    it "3) should authorize and capture 10 Ls (Visa)" do
      response = @gateway.authorize(1000, :client_ip_addr => @valid_ip)
      response[:transaction_id].should =~ @valid_response[:trans_id]
      @trans_id = response[:transaction_id]

      response = @gateway.result(@trans_id, :client_ip_addr => @valid_ip)
      response[:result].should == "CREATED"

      enter_credit_card_data(@trans_id, @visa_card_params)

      response = @gateway.result(@trans_id, :client_ip_addr => @valid_ip)
      response[:result].should == "OK"
      response[:result_code].should == "000"

      response = @gateway.capture(1000, @trans_id, :client_ip_addr => @valid_ip)
      response[:result].should == "OK"
      response[:result_code].should == "000"

      # # Laikam nav tāds pakalpojums
      # response = @gateway.credit(1000, @trans_id)
      # response[:result].should == "OK"
      # response[:result_code].should == "400"
    end

    it "4) should authorize and capture 10 Ls (Master)" do
      response = @gateway.authorize(1000, :client_ip_addr => @valid_ip)
      response[:transaction_id].should =~ @valid_response[:trans_id]
      @trans_id = response[:transaction_id]

      response = @gateway.result(@trans_id, :client_ip_addr => @valid_ip)
      response[:result].should == "CREATED"

      enter_credit_card_data(@trans_id, @master_card_params)

      response = @gateway.result(@trans_id, :client_ip_addr => @valid_ip)
      response[:result].should == "OK"
      response[:result_code].should == "000"

      response = @gateway.capture(1000, @trans_id, :client_ip_addr => @valid_ip)
      response[:result].should == "OK"
      response[:result_code].should == "000"
    end

    it "5) should be invalid with incorrect exp date" do
      response = @gateway.purchase(1000, :client_ip_addr => @valid_ip)
      response[:transaction_id].should =~ @valid_response[:trans_id]
      @trans_id = response[:transaction_id]

      enter_credit_card_data(@trans_id, @visa_card_params.merge!({
        :validMONTH => '12',
        :validYEAR => '12'
      }))

      response = @gateway.result(@trans_id, :client_ip_addr => @valid_ip)
      response[:result].should == "FAILED"
    end

    # Laikam nav tāds piesēgts
    it "6) should have successful 3D-Secure authentication" do
      response = @gateway.purchase(1000, :client_ip_addr => @valid_ip)
      response[:transaction_id].should =~ @valid_response[:trans_id]
      @trans_id = response[:transaction_id]

      enter_credit_card_data(@trans_id, @master_card_params.merge!({
        :cardnr => '5437551000000014'
      }))

      response = @gateway.result(@trans_id, :client_ip_addr => @valid_ip)
      response[:result].should == "CREATED"
      response[:'3dsecure'].should == 'FAILED'
      # pending
    end

    it "7) should have unsuccessful 3D-Secure authentication" do
      response = @gateway.purchase(1000, :client_ip_addr => @valid_ip)
      response[:transaction_id].should =~ @valid_response[:trans_id]
      @trans_id = response[:transaction_id]

      enter_credit_card_data(@trans_id, @master_card_params.merge!({
        :cardnr => '4314220000000032',
        :cvc2 => '213'
      }))

      response = @gateway.result(@trans_id, :client_ip_addr => @valid_ip)
      response[:result].should == "CREATED"
      response[:'3dsecure'].should == 'FAILED'
    end

    it "8) should have 3D-Secure authentication error" do
      response = @gateway.purchase(1000, :client_ip_addr => @valid_ip)
      response[:transaction_id].should =~ @valid_response[:trans_id]
      @trans_id = response[:transaction_id]

      enter_credit_card_data(@trans_id, @master_card_params.merge!({
        :cardnr => '4314220000000031',
        :cvc2 => '123'
      }))

      response = @gateway.result(@trans_id, :client_ip_addr => @valid_ip)
      response[:result].should == "CREATED"
      response[:'3dsecure'].should == 'FAILED'
    end

    it "9) should have blacklisted IP" do
      lambda {
        response = @gateway.purchase(1000, :client_ip_addr => @blocked_ip)
        # response.should have_key(:error)
      }.should raise_error
    end

    it "12) should close business day" do
      response = @gateway.close_day
      response[:result].should == "OK"
      response[:result_code].should == "500"
    end
  end

  def submit_form(url, params = {})
    ActiveMerchant::Billing::FirstDataGateway.logger.debug "SUBMIT_FORM: #{url}, params: #{params.inspect}"
    uri = URI.parse(url)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    response = http.post(uri.request_uri, params.collect { |key, value| "#{key}=#{CGI.escape(value.to_s)}" }.join("&"), {})
    # puts "RESPONSE CODE: #{response.code}"
    # puts "RESPONSE BODY: #{response.body}"
    response.body
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
