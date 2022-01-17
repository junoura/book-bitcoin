require_relative './ruby_coincheck_client-master/lib/ruby_coincheck_client'
USER_KEY = "your key"
USER_SECRET_KEY = "your secret key"
cc = CoincheckClient.new(USER_KEY, USER_SECRET_KEY)
response = cc.read_balance.body
puts "response = #{response}"
