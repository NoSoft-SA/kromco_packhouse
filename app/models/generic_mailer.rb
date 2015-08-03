class GenericMailer < ActionMailer::Base

  def set_generic_alerts_mail_details(transaction_status,process_alert_def,user)
   @subject = "Generic Kromco Alert email"
   @recipients =  user.email_address
   @from = "MesWebSystem@kromco.co.za"
   @sent_on = Time.now
   @body['transaction_status'] = transaction_status
   @body['process_alert_definition'] = process_alert_def

   StatusMan.log_sent_mail(transaction_status.id,transaction_status.transaction_status_object_id,transaction_status.status_type_code,nil,process_alert_def.process_alert_name,@recipients,transaction_status.email_message,@subject)
  end

  def generic_alerts_mail_with_override( transaction_status, process_alert_def, options={} )
   @subject                          = options[:subject] || "Generic Kromco Alert email"
   @recipients                       = options[:recipients] || process_alert_def.email_recipients
   @from                             = options[:from] || "MesWebSystem@kromco.co.za"
   @sent_on                          = Time.now
   @body['transaction_status']       = transaction_status
   @body['process_alert_definition'] = process_alert_def
   @body['override_message']         = options[:body]

   StatusMan.log_sent_mail(transaction_status.id,
                           transaction_status.transaction_status_object_id,
                           transaction_status.status_type_code,
                           nil,
                           process_alert_def.process_alert_name,
                           @recipients,
                           transaction_status.email_message,
                           @subject)
  end

  def vanilla_mail(options={})
    subject     options[:subject] || "Generic Kromco mail"
    recipients  options[:recipients]
    from        "MesWebSystem@kromco.co.za"
    sent_on     Time.now
    body        :text => options[:text]

    if options[:has_attachment]
      attachment :content_type        => options[:attachment_mime] || "text/plain",
                 :content_disposition => "attachment",
                 :filename            => options[:attachment_filename],
                 :body                => options[:attachment_text]
    end
  end

end
