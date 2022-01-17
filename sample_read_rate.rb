require_relative './ruby_coincheck_client-master/lib/ruby_coincheck_client'
cc = CoincheckClient.new
response = cc.read_rate(pair: "btc_jpy").body
puts "response(btc_jpy) = #{response}"
response = cc.read_rate(pair: "etc_jpy").body
puts "response(etc_jpy) = #{response}"
response = cc.read_rate(pair: "fct_jpy").body
puts "response(fct_jpy) = #{response}"
response = cc.read_rate(pair: "mona_jpy").body
puts "response(mona_jp) = #{response}"
response = cc.read_rate(pair: "plt_jpy").body
puts "response(plt_jpy) = #{response}"

