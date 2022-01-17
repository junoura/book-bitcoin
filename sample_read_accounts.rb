require_relative './ruby_coincheck_client-master/lib/ruby_coincheck_client'
USER_KEY = "0vvp4HBmfM_tff3a"
USER_SECRET_KEY = "rDwrpjtR5--j8Vg20cQoRtvvfatpsLGn"
cc = CoincheckClient.new(USER_KEY, USER_SECRET_KEY)
response = cc.read_balance.body
puts "response = #{response}"
