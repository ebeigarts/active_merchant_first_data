First Data gateway for Active Merchant
======================================

[![Continuous Integration status](https://secure.travis-ci.org/ebeigarts/active_merchant_first_data.png)](http://travis-ci.org/ebeigarts/active_merchant_first_data)

## Install

```bash
$ gem install active_merchant_first_data
```

## Usage

```ruby
require "active_merchant_first_data"
@gateway = ActiveMerchant::Billing::FirstDataGateway.new(
  :pem => "1234567_keystore.pem"
  :pem_password => "5x64jq8n234c"
)
```

## First Data test environment setup

1. Generate a new certificate

    ```bash
    $ openssl req -newkey rsa:1024 -keyout spec/certs/1234567_key.pem -out spec/certs/1234567_req.pem -subj "/C=lv/O=example.com/CN=1234567" -outform PEM
    Enter PEM pass phrase: 81f174259v45
    ```

2. [Request your certificate using `1234567_req.pem`](https://secureshop-test.firstdata.lv/report/keystore_.do)

3. Copy the 3 files you received in e-mail to `spec/certs/`:

    * 1234567.pem
    * 1234567_certificate_chain.p7.pem
    * ECOMM.pem

4. Convert the certificates and keys to `1234567_keystore.pem`

    ```bash
    $ openssl pkcs12 -export -in 1234567.pem -out spec/certs/1234567_keystore.p12 -certfile spec/certs/ECOMM.pem -inkey spec/certs/1234567_key.pem
    Enter pass phrase for 1234567_key.pem: 81f174259v45
    Enter Export Password: <empty>
    ```

    ```bash
    $ openssl pkcs12 -in spec/certs/1234567_keystore.p12 > spec/certs/1234567_keystore.pem
    Enter Import Password: <empty>
    Enter PEM pass phrase: 5x64jq8n234c
    ```

5. [Set your WAN IP address](https://secureshop-test.firstdata.lv/report/merchantlist.do)
