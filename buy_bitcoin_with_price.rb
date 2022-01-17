# coding: utf-8
# buy_bitcoin_with_price.rb
# bitcoinを成行で購入する
# 引数は購入に使用するBitcoinの金額

require_relative './ruby_coincheck_client-master/lib/ruby_coincheck_client'

# ログの出力設定
# 動作の記録を外部ファイルに保存して、後から検証できるようにします。
require 'logger'
log = Logger.new("./#{$0}.log")

# APIキーの読み込み
require_relative './sample_api_key.rb'

# 引数が与えられなかった場合、引数を説明するメッセージを出して終了します。
if ARGV.length != 2
  puts "USAGE: ruby #{$0} 購入に使用する日本円の金額 Bitcoinの単価"
  exit
end

# 引数の取得
# 引数として与えられる情報を取得します。
amount_of_jpy = ARGV[0].to_f
rate_of_btc_requested = ARGV[1].to_f
amount_of_btc = amount_of_jpy / rate_of_btc_requested

# 現在の状況把握(日本円、暗号資産)
# 現在、Coincheckの口座にどれだけの日本円、暗号資産があるかを確認します。
cc = CoincheckClient.new(USER_KEY, USER_SECRET_KEY)
response = cc.read_balance.body
response_hash = JSON.parse(response)
amount_of_jpy_kouza = response_hash['jpy'].to_f
puts "現在の総資産"
puts "jpy = #{amount_of_jpy_kouza}"
puts "btc = #{response_hash['btc']}"

# 入力チェック
# 指定した日本円より口座にある日本円が少なかったらエラーとします。
if amount_of_jpy > amount_of_jpy_kouza
  puts "日本円が不足しています"
  log.error("日本円が不足しています")
  exit
end

# 価格の取得
# 「価格」を取得します。
response = cc.read_orders_rate(order_type: "buy", amount: "#{amount_of_btc}").body
response_hash = JSON.parse(response)
rate_of_btc = response_hash['rate'].to_f
# 指定された「価格」が取得された「価格」より1割以上差がある場合、エラーとします。
if rate_of_btc_requested > rate_of_btc * 1.1
  puts "指定した価格が高すぎます"
  log.error("指定した価格が高すぎます")
  exit
end
if rate_of_btc_requested < rate_of_btc * 0.9
  puts "指定した価格が低すぎます"
  log.error("指定した価格が低すぎます")
  exit
end

# 暗号資産の取引
# 実行してよいか確認をします。
puts "Bitcoinを#{amount_of_btc}BTC(#{amount_of_jpy}円分)レート#{rate_of_btc_requested}で指値購入"\
     "します。よろしいですか？(Y N)"
ans = STDIN.gets.chomp
if ans != 'Y' && ans != 'y'
  puts "取引を中止します"
  log.info("取引を中止します")
  exit
end
  
# 実際の売買を行います。
response = cc.create_orders(rate: "#{rate_of_btc_requested}", amount: "#{amount_of_btc}",
                            order_type: "buy").body
response_hash = JSON.parse(response)
response_success = response_hash['success']
if response_success
  response_id = response_hash['id']
  response_rate = response_hash['rate']
  response_amount = response_hash['amount']
  response_created_at = response_hash['created_at']
  log.info("id:#{response_id}, rate:#{response_rate}, amount:#{response_amount}, 
  created_at:#{response_created_at}")
  puts "Bitcoinを#{amount_of_btc}BTC(#{amount_of_jpy}円分)レート#{rate_of_btc_requested}で"\
       "指値購入注文しました。"
  log.info("Bitcoinを#{amount_of_btc}BTC(#{amount_of_jpy}円分)レート#{rate_of_btc_requested}で"\
           "指値購入注文しました。")
else
  response_error = response_hash['error']
  puts "error = #{response_error}"
  log.error("error:#{response_error}")
end
