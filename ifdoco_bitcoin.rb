# coding: utf-8
# ifdoco_bitcoin.rb
# 価格が指定した価格になるのを待ってbitcoinを購入し、価格が指定した価格(利益確定の売却価格または損切りの
# 売却価格)になるのを待ってbitcoinを売却する
# 引数は売却に使用するBitcoinの金額と価格(購入と利益確定の売却価格、損切りの売却価格)

require_relative './ruby_coincheck_client-master/lib/ruby_coincheck_client'

# ログの出力設定
# 動作の記録を外部ファイルに保存して、後から検証できるようにします。
require 'logger'
log = Logger.new("./#{$0}.log")

# APIキーの読み込み
require_relative './sample_api_key.rb'

# 引数が与えられなかった場合、引数を説明するメッセージを出して終了します。
if ARGV.length != 4
  puts "USAGE: ruby #{$0} 日本円の金額 Bitcoinの購入単価 Bitcoinの利益確定売却単価 Bitcoinの損切り売却単価"
  exit
end

# 引数の取得
# 引数として与えられる情報を取得します。
amount_of_jpy = ARGV[0].to_f
rate_of_btc_buy = ARGV[1].to_f
rate_of_btc_profit = ARGV[2].to_f
rate_of_btc_loss = ARGV[3].to_f

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
if amount_of_jpy > amount_of_jpy_kouza_before
  puts "日本円が不足しています"
  log.error("日本円が不足しています")
  exit
end

# 「価格」を取得します。今回は成行での売買ですが、だいたいいくらで売買されるのかをつかむため、取得します。
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

# 指定された「価格」が取得された「価格」より1割以上差がある場合、エラーとします。
if rate_of_btc_buy > estimated_rate * 1.1
  puts "指定した価格が高すぎます"
  log.error("指定した価格が高すぎます")
  exit
end
if rate_of_btc_buy < estimated_rate * 0.9
  puts "指定した価格が低すぎます"
  log.error("指定した価格が低すぎます")
  exit
end
if rate_of_btc_profit > estimated_rate * 1.1
  puts "指定した価格が高すぎます"
  log.error("指定した価格が高すぎます")
  exit
end
if rate_of_btc_profit < estimated_rate * 0.9
  puts "指定した価格が低すぎます"
  log.error("指定した価格が低すぎます")
  exit
end
if rate_of_btc_loss > estimated_rate * 1.1
  puts "指定した価格が高すぎます"
  log.error("指定した価格が高すぎます")
  exit
end
if rate_of_btc_loss < estimated_rate * 0.9
  puts "指定した価格が低すぎます"
  log.error("指定した価格が低すぎます")
  exit
end

loop do  
  # 「価格」を取得します。
  response = cc.read_orders_rate(order_type: "buy", amount: "#{estimated_btc}").body
  # puts "response = #{response}"
  response_hash = JSON.parse(response)
  rate_of_btc = response_hash['rate'].to_f
  # puts "rate_of_btc = #{rate_of_btc}"
  # 指定された「価格」が取得された「価格」より1割以上差がある場合、エラーとします。
  if rate_of_btc < rate_of_btc_buy
    puts "指定した購入価格に達しました(現在:#{rate_of_btc} 目標:#{rate_of_btc_buy})"
    log.info("指定した購入価格に達しました(現在:#{rate_of_btc} 目標:#{rate_of_btc_buy})")
    # 実際の売買を行います。
    # response = cc.create_orders(amount: "#{estimated_btc}", order_type: "market_buy").body
    response = cc.create_orders(market_buy_amount: amount_of_jpy, order_type: "market_buy").body
    response_hash = JSON.parse(response)
    response_success = response_hash['success']
    if response_success
      response_id = response_hash['id']
      response_rate = response_hash['rate']
      response_amount = response_hash['amount']
      response_created_at = response_hash['created_at']
      puts "日本円#{amount_of_jpy}をレート約#{estimated_rate}で約#{estimated_btc}BTCを成行で"\
           "購入しました。"
      log.info("日本円#{amount_of_jpy}をレート約#{estimated_rate}で約#{estimated_btc}BTCを成行で"\
               "購入しました。")
    else
      response_error = response_hash['error']
      puts "error = #{response_error}"
      log.error("error:#{response_error}")
    end
    break
  else
    puts "指定した購入価格に達していません(#{Time.now} 現在:#{rate_of_btc} 目標:#{rate_of_btc_buy})"
  end

  sleep 5
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

loop do  
  # 「価格」を取得します。
  response = cc.read_orders_rate(order_type: "sell", amount: "#{estimated_btc}").body
  # puts "response = #{response}"
  response_hash = JSON.parse(response)
  rate_of_btc = response_hash['rate'].to_f
  # puts "rate_of_btc = #{rate_of_btc}"
  # 指定された「価格」が取得された「価格」より1割以上差がある場合、エラーとします。
  if rate_of_btc > rate_of_btc_profit
    puts "指定した利益確定価格に達しました(現在:#{rate_of_btc} 目標:#{rate_of_btc_profit})"
    log.info("指定した利益確定価格に達しました(現在:#{rate_of_btc} 目標:#{rate_of_btc_profit})")
    # 実際の売買を行います。
    response = cc.create_orders(amount: "#{estimated_btc}", order_type: "market_sell").body
    response_hash = JSON.parse(response)
    response_success = response_hash['success']
    if response_success
      response_id = response_hash['id']
      response_rate = response_hash['rate']
      response_amount = response_hash['amount']
      response_created_at = response_hash['created_at']
      puts "#{estimated_btc}BTCを成行で売却注文しました。"
      log.info("#{estimated_btc}BTCを成行で売却注文しました。")
    else
      response_error = response_hash['error']
      puts "error = #{response_error}"
      log.error("error:#{response_error}")
    end
    break
  else
    puts "指定した利益確定価格に達していません(#{Time.now} 現在:#{rate_of_btc} "\
         "目標:#{rate_of_btc_profit})"
  end
  if rate_of_btc < rate_of_btc_loss
    puts "指定した損切り価格に達しました(現在:#{rate_of_btc} 目標:#{rate_of_btc_loss})"
    log.info("指定した損切り価格に達しました(現在:#{rate_of_btc} 目標:#{rate_of_btc_loss})")
    # 実際の売買を行います。
    response = cc.create_orders(amount: "#{estimated_btc}", order_type: "market_sell").body
    response_hash = JSON.parse(response)
    response_success = response_hash['success']
    if response_success
      response_id = response_hash['id']
      response_rate = response_hash['rate']
      response_amount = response_hash['amount']
      response_created_at = response_hash['created_at']
      puts "#{estimated_btc}BTCを成行で売却注文しました。"
      log.info("#{estimated_btc}BTCを成行で売却注文しました。")
    else
      response_error = response_hash['error']
      puts "error = #{response_error}"
      log.error("error:#{response_error}")
    end
    break
  else
    puts "指定した損切り価格に達していません(#{Time.now} 現在:#{rate_of_btc} 目標:#{rate_of_btc_loss})"
  end

  sleep 5
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
puts "得られた日本円 = #{diff_of_jpy}"
puts "日本円#{diff_of_jpy}を得ました。"
log.info("日本円#{diff_of_jpy}を得ました。")
