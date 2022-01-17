require_relative './ruby_coincheck_client-master/lib/ruby_coincheck_client'
require_relative './sample_api_key'
cc = CoincheckClient.new(USER_KEY, USER_SECRET_KEY)
response = cc.create_orders(market_buy_amount: 60000, order_type: "market_buy").body
puts "response = #{response}"
