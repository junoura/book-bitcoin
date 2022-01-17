require_relative './ruby_coincheck_client-master/lib/ruby_coincheck_client'
require_relative './sample_api_key.rb'
cc = CoincheckClient.new(USER_KEY, USER_SECRET_KEY)
response = cc.read_balance.body
puts "response = #{response}"
