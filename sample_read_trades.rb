require_relative './ruby_coincheck_client-master/lib/ruby_coincheck_client'
cc = CoincheckClient.new
response = cc.read_trades.body
puts "response = #{response}"
