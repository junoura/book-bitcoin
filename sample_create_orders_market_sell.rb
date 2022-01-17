require_relative './ruby_coincheck_client-master/lib/ruby_coincheck_client'
require_relative './sample_api_key'
cc = CoincheckClient.new(USER_KEY, USER_SECRET_KEY)
response = cc.create_orders(amount: "0.005", order_type: "market_sell").body
puts "response = #{response}"
