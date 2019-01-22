class GetLabelTemplates
  def self.call
    http = Net::HTTP.new(Globals.get_label_template_server , Globals.get_label_template_port)
    http.read_timeout = 12000 #360000=1hr                      100=1second
    response = http.get("/services/getpublishedlabellist ?xml=<GetPublishedLabelList PID=\"901\" /> ", 'Accept' => 'text/xml')
    if '200' == response.code
      response.body.split(',')
    else
      []
    end
  end
end