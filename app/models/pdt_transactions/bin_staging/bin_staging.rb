require 'rexml/document'

class BinStaging < PDTTransaction

  include REXML

  def build_default_screen
    field_configs = Array.new
    field_configs[field_configs.length] = {:type=>"text_box", :name=>"bin_number", :is_required=>"true"}

    buttons = {"B1Label"=>"submit", "B1Enable"=>"false", "B1Submit"=>"bin_scanned", "B2Label"=>"", "B2Enable"=>"false", "B3Submit"=>"", "B3Enable"=>"false"}
    screen_attributes = {:content_header_caption=>"scan bin", :auto_submit=>"true",:auto_submit_to=>"bin_scanned"}
    result_screen = PdtScreenDefinition.gen_screen_xml(field_configs, buttons, screen_attributes, nil)
  end

  def scan_bin
    build_default_screen
  end

  def bin_scanned
    bin = pdt_screen_def.get_input_control_value("bin_number")

    http = Net::HTTP.new(Globals.pdt_presort_staging_ip, Globals.pdt_presort_staging_port)
    request = Net::HTTP::Post.new("/services/pre_sorting/bins_scanned")
    parameters = {'bin1' => bin}
    request.set_form_data(parameters)
    response = http.request(request)

    doc = Document.new response.body
    msgs = []
    caption = ""
    doc.root.elements.each do |element|
      if(element.name=='bins')
        result = element.elements[1]
        status = result.attributes['result_status']
        caption = "#{status} : bin_number(#{bin})"
        if(result.attributes['msg'])
          msgs = result.attributes['msg'].split("\n")
        else
          set_repeat_process_flag
          return nil
        end
      elsif(element.name=='error')
        caption = "Error : bin_number(#{bin})"
        msgs << element.attributes['msg']
      end
    end
    result_screen = PDTTransaction.build_msg_screen_definition(nil,nil,nil,msgs, caption)
    return result_screen
  end

end