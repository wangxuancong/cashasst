class RunTaskJob < ActiveJob::Base
  
  queue_as :default

  def perform(*args)
    Task.running.each do |task|
    	policies = task.policies.not_triggered
    	if policies.present?
        price = current_price(task.account.name, task.symbol)
        return if price.blank?
	    	policies.each do |policy|
          if policy.trigger_price_upper > BigDecimal.new(price.to_s) and BigDecimal.new(price.to_s) > policy.trigger_price_lower
	    			notice = "当前价格为:#{price}, 在#{policy.trigger_price_lower}与#{policy.trigger_price_upper}之间, 下单"
            huobi_order = Huobi::Order.new(task.account.name)
            result = huobi_order.new_order(task.account.spot_id, task.symbol, side(policy[:change_type]), policy.market_price.to_f, policy.change_num.to_f)
            if result["status"] != 'ok'
              send_mail("下单失败", task.account.email, "#{notice}失败")
              LOG.info "下单失败: #{result["err-msg"]}"
            else
              send_mail("下单成功", task.account.email, "#{notice}成功")
              policy.triggered = 1
              policy.save
              LOG.info "下单成功"
            end
          else
            LOG.info "当前价格为:#{price}, 不在#{policy.trigger_price_lower}与#{policy.trigger_price_upper}之间"
	    		end
	    	end
	    else
	    	LOG.info "无策略可执行"
    	end
    end
  end

  private
  def current_price(account_name, symbol)
  	market = Huobi::Market.new(account_name)
  	data = market.trade_detail(symbol)
  	if data["status"] == 'ok'
      price = data["tick"]["data"][0]["price"]
      LOG.info "当前#{symbol}价钱为#{price}"
  		return price
  	end
  end

  def side(change_type)
    change_type == 0 ? "buy-limit" : "sell-limit"
  end

  def send_mail(subject, to, body = nil)
    NoticeMailer.send_mail(subject, to, body).deliver
  end

end
