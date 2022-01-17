# coding: utf-8
# cancel_order.rb
# 注文をキャンセルする
# 引数はなし

require_relative './ruby_coincheck_client-master/lib/ruby_coincheck_client'

# ログの出力設定
# 動作の記録を外部ファイルに保存して、後から検証できるようにします。
require 'logger'
log = Logger.new("./#{$0}.log")

# APIキーの読み込み
require_relative './sample_api_key.rb'

# 現在の注文状況把握
order_id = ""
cc = CoincheckClient.new(USER_KEY, USER_SECRET_KEY)
response = cc.read_orders.body
response_hash = JSON.parse(response)

# 注文が残っている場合
if response_hash['orders'].count > 0
  puts "注文が#{response_hash['orders'].count}件残っています"
  response_hash['orders'].each{ |order|

    # 注文情報を表示します
    puts "注文 ID=#{order['id']} order_type=#{order['order_type']} レート=#{order['rate']} "\
         "BTC=#{order['pending_amount']} 日本円=#{order['rate'].to_f * order['pending_amount'].to_f}"
  }
else
# 注文が残っていない場合
  puts "未処理の注文はありません"
end
