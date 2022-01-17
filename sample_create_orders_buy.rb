require_relative './ruby_coincheck_client-master/lib/ruby_coincheck_client'
require_relative './sample_api_key'
cc = CoincheckClient.new(USER_KEY, USER_SECRET_KEY)
response = cc.create_orders(rate: "4900000", amount: "0.01", order_type: "buy").body
puts "response = #{response}"
