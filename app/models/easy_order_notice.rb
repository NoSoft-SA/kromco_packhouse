class EasyOrderNotice < ActionMailer::Base

  def notify_marketer_order_created(msg,subj,recepient)
    @subject = "New order created: #{subj}"
    @recipients = recepient
    @from = "MesWebSystem@kromco.co.za"
    @sent_on = Time.now
    @body['msg'] = msg
  end

  def notify_order_created(msg,subj)
    @subject = "New mq/mo order created: #{subj}"
    @recipients =  "marketlogistics@kromco.co.za"
    @from = "MesWebSystem@kromco.co.za"
    @sent_on = Time.now
    @body['msg'] = msg
    #@body['order_number'] = order_number
  end
  
  def notify_order_updated(msg,subj)
    @subject = "Order Updated: #{subj}"
    @recipients =  "marketlogistics@kromco.co.za"
    @from = "MesWebSystem@kromco.co.za"
    @sent_on = Time.now
    @body['msg'] = msg
    #@body['order_number'] = order_number
  end

  def notify_can_upgrade(msg,subj)
    @subject = "Order upgrade notification: #{subj}"
    @recipients ="marketlogistics@kromco.co.za"
    @from = "MesWebSystem@kromco.co.za"
    @sent_on = Time.now
    @body['msg'] = msg
    #@body['order_number'] = order_number

  end

  def notify_price(msg,subj)
    @subject = "Order Price notification: #{subj}"
    @recipients =  "payments@kromco.co.za"
    @from = "MesWebSystem@kromco.co.za"
    @sent_on = Time.now
    @body['msg'] = msg
    #@body['order_number'] = order_number

  end


end