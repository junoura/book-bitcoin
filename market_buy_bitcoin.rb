# coding: utf-8
# market_buy_bitcoin.rb
# bitcoinを成行で購入する
# 引数は購入に使用する日本円の金額

require_relative './ruby_coincheck_client-master/lib/ruby_coincheck_client'

# ログの出力設定
# 動作の記録を外部ファイルに保存して、後から検証できるようにします。
require 'logger'
log = Logger.new("./#{$0}.log")

# APIキーの読み込み
require_relative './sample_api_key.rb'

# 引数が与えられなかった場合、引数を説明するメッセージを出して終了します。
if ARGV.length != 1
  puts "USAGE: ruby #{$0} 購入に使用する日本円の金額"
  exit
end

# 引数の取得
# 引数として与えられる情報を取得します。
amount_of_jpy = ARGV[0].to_f

# 現在の状況把握(日本円、暗号資産)
# 現在、Coincheckの口座にどれだけの日本円、暗号資産があるかを確認します。
cc = CoincheckClient.new(USER_KEY, USER_SECRET_KEY)
response = cc.read_balance.body
response_hash = JSON.parse(response)
amount_of_jpy_kouza_before = response_hash['jpy'].to_f
amount_of_btc_kouza_before = response_hash['btc'].to_f
puts "現在の総資産"
puts "jpy = #{amount_of_jpy_kouza_before}"
puts "btc = #{amount_of_btc_kouza_before}"

# 入力チェック
# 指定した日本円より口座にある日本円が少なかったらエラーとします。
if amount_of_jpy > amount_of_jpy_kouza_before
  puts "日本円が不足しています"
  log.error("日本円が不足しています")
  exit
end

# 価格の取得
# 「価格」を取得します。今回は成行での売買ですが、だいたいいくらで売買されるのかを把握するため、取得します。
estimated_rate = 0.0
estimated_btc = 0.0
# 1BTCでの価格を取得
response = cc.read_orders_rate(order_type: "buy", amount: "1.0").body
response_hash = JSON.parse(response)
response_success = response_hash['success']
if response_success
  estimated_rate = response_hash['rate'].to_f
end
estimated_btc = amount_of_jpy / estimated_rate
# 計算したBTC量での価格を取得
response = cc.read_orders_rate(order_type: "buy", amount: "#{estimated_btc}").body
response_hash = JSON.parse(response)
response_success = response_hash['success']
if response_success
  estimated_rate = response_hash['rate'].to_f
end
# その価格で購入できるBTC量を取得
estimated_btc = amount_of_jpy / estimated_rate

# 暗号資産の取引
# 実行してよいか確認をします。
puts "Bitcoinを想定レート#{estimated_rate}で購入します。よろしいですか？(Y N)"
ans = STDIN.gets.chomp
if ans != 'Y' && ans != 'y'
  puts "取引を中止します"
  log.info("取引を中止します")
  exit
end

# 実際の売買を行います。
response = cc.create_orders(market_buy_amount: amount_of_jpy, order_type: "market_buy").body
response_hash = JSON.parse(response)
response_success = response_hash['success']
if response_success
  response_id = response_hash['id']
  response_rate = response_hash['rate']
  response_amount = response_hash['amount']
  response_created_at = response_hash['created_at']
  puts "日本円#{amount_of_jpy}を成行で購入注文しました。"
  log.info("日本円#{amount_of_jpy}を成行で購入注文しました。")
else
  response_error = response_hash['error']
  puts "error = #{response_error}"
  log.error("error:#{response_error}")
end

# 注文が残っていないかチェックします
loop do
  response = cc.read_orders.body
  response_hash = JSON.parse(response)
  # 注文が残っている場合
  if response_hash['orders'].count > 0
    puts "注文処理中です。"
    sleep 1
  else
    break
  end
end

# 取引結果を表示します
response = cc.read_balance.body
response_hash = JSON.parse(response)
amount_of_jpy_kouza_after = response_hash['jpy'].to_f
amount_of_btc_kouza_after = response_hash['btc'].to_f
puts "現在の総資産"
puts "jpy = #{amount_of_jpy_kouza_after}"
puts "btc = #{amount_of_btc_kouza_after}"
diff_of_jpy = amount_of_jpy_kouza_before - amount_of_jpy_kouza_after
diff_of_btc = amount_of_btc_kouza_after - amount_of_btc_kouza_before
actual_rate = diff_of_jpy / diff_of_btc
puts "使用した日本円 = #{diff_of_jpy}"
puts "購入したBTC = #{diff_of_btc}"
puts "レート = #{actual_rate}"
puts "日本円#{diff_of_jpy}をレート約#{actual_rate}で約#{diff_of_btc}BTCを成行で購入しました。"
log.info("日本円#{diff_of_jpy}をレート約#{actual_rate}で約#{diff_of_btc}BTCを成行で購入しました。")
