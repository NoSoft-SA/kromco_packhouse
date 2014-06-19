class RailsErrorMail < ActionMailer::Base

  def set_error_details(err)
   @subject = "Kromco Mes Web Exception"
   @recipients = "hans@kromco.co.za"
   @from = "Kromco Mes Web System"
   @sent_on = Time.now
   @body['error'] = err
   
  end
end
