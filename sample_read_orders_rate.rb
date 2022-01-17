require_relative './ruby_coincheck_client-master/lib/ruby_coincheck_client'
cc = CoincheckClient.new
response = cc.read_orders_rate(order_type: "buy", amount: "0.01").body
puts "response = #{response}"
response = cc.read_orders_rate(order_type: "sell", amount: "0.01").body
puts "response = #{response}"
