# coding: utf-8
# check_price_and_sell.rb
# 価格が指定した価格になるのを待ってbitcoinを成行で売却する
# 引数は売却に使用するBitcoinの金額と価格

require_relative './ruby_coincheck_client-master/lib/ruby_coincheck_client'

# ログの出力設定
# 動作の記録を外部ファイルに保存して、後から検証できるようにします。
require 'logger'
log = Logger.new("./#{$0}.log")

# APIキーの読み込み
require_relative './sample_api_key.rb'

# 引数が与えられなかった場合、引数を説明するメッセージを出して終了します。
if ARGV.length != 2
  puts "USAGE: ruby #{$0} 売却に使用するBitcoinの金額 Bitcoinの単価"
  exit
end

# 引数の取得
# 引数として与えられる情報を取得します。
amount_of_btc = ARGV[0].to_f
log.info("amount_of_btc = #{amount_of_btc}")
rate_of_btc_requested = ARGV[1].to_f
log.info("rate_of_btc_requested = #{rate_of_btc_requested}")

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
# 指定したBitcoinより口座にあるBitcoinが少なかったらエラーとします。
if amount_of_btc > amount_of_btc_kouza_before
  puts "Bitcoinが不足しています"
  log.error("Bitcoinが不足しています")
  exit
end

# 価格の取得
# 「価格」を取得します。
response = cc.read_orders_rate(order_type: "sell", amount: "#{amount_of_btc}").body
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

loop do  
  # 「価格」を取得します。
  response = cc.read_orders_rate(order_type: "sell", amount: "#{amount_of_btc}").body
  response_hash = JSON.parse(response)
  rate_of_btc = response_hash['rate'].to_f
  # 指定された「価格」が取得された「価格」に達した場合売買を行います。
  if rate_of_btc > rate_of_btc_requested
    puts "指定した価格に達しました(現在:#{rate_of_btc} 目標:#{rate_of_btc_requested})"
    log.info("指定した価格に達しました(現在:#{rate_of_btc} 目標:#{rate_of_btc_requested})")
    # 実際の売買を行います。
    response = cc.create_orders(amount: "#{amount_of_btc}", order_type: "market_sell").body
    response_hash = JSON.parse(response)
    response_success = response_hash['success']
    if response_success
      response_id = response_hash['id']
      response_amount = response_hash['amount']
      response_created_at = response_hash['created_at']
      puts "#{amount_of_btc}BTCを成行で売却注文しました。"
      log.info("#{amount_of_btc}BTCを成行で売却注文しました。")
    else
      response_error = response_hash['error']
      puts "error = #{response_error}"
      log.error("error:#{response_error}")
    end
    break
  else
    puts "指定した価格に達していません(#{Time.now} 現在:#{rate_of_btc} 目標:#{rate_of_btc_requested})"
  end

  sleep 60
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
diff_of_jpy = amount_of_jpy_kouza_after - amount_of_jpy_kouza_before
diff_of_btc = amount_of_btc_kouza_before - amount_of_btc_kouza_after
actual_rate = diff_of_jpy / diff_of_btc
puts "使用したBTC = #{diff_of_btc}"
puts "得られた日本円 = #{diff_of_jpy}"
puts "レート = #{actual_rate}"
puts "BTC#{diff_of_btc}をレート約#{actual_rate}で成行で売却し、日本円#{diff_of_jpy}を得ました。"
log.info("BTC#{diff_of_btc}をレート約#{actual_rate}で成行で売却し、日本円#{diff_of_jpy}を得ました。")
