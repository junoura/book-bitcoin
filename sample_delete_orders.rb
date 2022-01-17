require_relative './ruby_coincheck_client-master/lib/ruby_coincheck_client'
require_relative './sample_api_key'
cc = CoincheckClient.new(USER_KEY, USER_SECRET_KEY)
response = cc.delete_orders(id: "4241528606").body
puts "response = #{response}"
