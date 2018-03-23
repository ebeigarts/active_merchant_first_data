First Data Latvia gateway for Active Merchant
=============================================

[![Build Status](https://travis-ci.org/ebeigarts/active_merchant_first_data.svg?branch=master)](https://travis-ci.org/ebeigarts/active_merchant_first_data)

## Install

```bash
$ gem install active_merchant_first_data
```

## Usage

```ruby
require "active_merchant_first_data"

gateway = ActiveMerchant::Billing::FirstDataGateway.new(
  pem:  File.read("1234567_keystore.pem"),
  pem_password: "5x64jq8n234c"
)

# Authorize for 10 euros (1000 euro cents)
response = gateway.authorize(1000, client_ip_addr: '127.0.0.1')

# Use this url to enter credit card data
gateway.redirect_url(response.authorization)

# Capture the money
gateway.capture(1000, response.authorization, client_ip_addr: '127.0.0.1')
```

## First Data test environment setup

1. Generate a new certificate

    ```bash
    $ openssl req -newkey rsa:2048 -keyout spec/certs/1234567_key.pem -out spec/certs/1234567_req.pem -subj "/C=lv/O=example.com/CN=1234567" -outform PEM
    Enter PEM pass phrase: 81f174259v45
    ```

2. [Request your certificate using `1234567_req.pem`](https://secureshop-test.firstdata.lv/report/keystore_.do)

3. Copy the 3 files you received in e-mail to `spec/certs/`:

    ```
    1234567.pem
    1234567_certificate_chain.p7.pem
    ECOMM.pem
    ```

4. Convert the certificates and keys to `1234567_keystore.pem`

    ```bash
    $ openssl pkcs12 -export -in spec/certs/1234567.pem -out spec/certs/1234567_keystore.p12 -certfile spec/certs/ECOMM.pem -inkey spec/certs/1234567_key.pem
    Enter pass phrase for 1234567_key.pem: 81f174259v45
    Enter Export Password: <empty>
    ```

    ```bash
    $ openssl pkcs12 -in spec/certs/1234567_keystore.p12 > spec/certs/1234567_keystore.pem
    Enter Import Password: <empty>
    Enter PEM pass phrase: 5x64jq8n234c
    ```

5. [Set your WAN IP address](https://secureshop-test.firstdata.lv/report/merchantlist.do)

## Mocking in (RSpec) tests
Perhaps the best way to mock responses in tests is to disallow remote connections altogether
and then control what responses specific requests receive.

For example, to mock response to the `#purchase` request with WebMock you'd:

```rb
before do
  body = {
    "TRANSACTION_ID" => "e+oClP4em8uBDozaZ4CBBbipEcM="
  }.merge(options).map{ |k, v| "#{k}: #{v}" }.join("\n")

  WebMock.stub_request(:post, %r'firstdata.lv').
    with(body: hash_including("command" => "v")).
    to_return(body: body)
end
```

Peruse `first_data_gateway.rb` to find out which command letters map to which methods.  
Additionally, have a look at `spec/cassettes` for response body examples.
