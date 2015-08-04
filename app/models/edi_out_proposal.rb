# EDI Out proposal - records for processing into an EDI out flow.
class EdiOutProposal < ActiveRecord::Base
  # Only load the helper if it hasn't already been loaded:
  require 'edi/lib/edi/edi_helper' if $".grep( /edi_helper/ ).empty?

  has_many :edi_out_process_histories
  has_many :edi_errors

  # Create an in-memory EDI Out proposal with the attributes of the model in the parameters.
  # Return an EDI outflow of type +flow_type+ as a string.
  #
  # The EdiOutProposal is not persisted.
  def self.make_edi_string( model, flow_type )
    attr_hash = hash_from_model model

    EdiHelper.load_edi_files_for_web_context

    # Create the in-memory proposal record.
    edi_out_proposal = self.new(:flow_type           => flow_type.downcase,
                                :record_map          => attr_hash.to_yaml,
                                :out_destination_dir => '')

    # Get the OutProcess to return EDI output as a string.
    out_process = OutProcessInMemory.new
    out_process.run( edi_out_proposal )
  end

  # Create an EDI Out proposal (or proposals) with the attributes of the model in the parameters.
  # In some cases the model might be a hash of values rather than a model.
  # If the options hash has <tt>:organization_code</tt> and <tt>:hub_address</tt> values,
  # these will be used instead of derived from the model.
  # If the organisation does not receive EDI files, the EdiOutDestination#get_edi_out_destinations
  # method will return an empty array and no proposal will be created.
  def self.send_doc( model, flow_type, options={} )
    if model.is_a? Hash
      rec_id = nil
    else
      rec_id = model.id
    end
    attr_hash = hash_from_model model

    edi_out_destinations = get_edi_out_destinations( flow_type, model, options )

    # get_edi_out_destinations will return an empty array if the model's organization does not recieve EDI files.
    if edi_out_destinations.empty?
      nil
    else
	#RAILS_DEFAULT_LOGGER.info("NAE EDI_OUT_PROP edi_out_destinations.length.to_s "+ edi_out_destinations.length.to_s)
      edi_out_destinations.each do |edi_out_destination|
	#RAILS_DEFAULT_LOGGER.info("NAE EDI_OUT_PROP edi_out_destination.flow_type.downcase.to_s "+ edi_out_destination.flow_type.downcase.to_s)	 	
	#RAILS_DEFAULT_LOGGER.info("NAE EDI_OUT_PROP edi_out_destination.organization_code.to_s "+ edi_out_destination.organization_code.to_s)	 
	#RAILS_DEFAULT_LOGGER.info("NAE EDI_OUT_PROP edi_out_destination.hub_address.to_s "+ edi_out_destination.hub_address.to_s)	 	
        # Create the proposal record.
        self.create(:flow_type           => edi_out_destination.flow_type.downcase,
                    :record_map          => attr_hash.to_yaml,
                    :record_id           => rec_id,
                    :process_attempts    => 0,
                    :out_destination_dir => edi_out_destination.out_destination_dir,
                    :transfer_mechanism  => edi_out_destination.transfer_mechanism,
                    :organization_code   => edi_out_destination.organization_code,
                    :hub_address         => edi_out_destination.hub_address
                   )
      end
    end
  end

  # Create a hash from a model's attributes.
  def self.hash_from_model( model )
    attr_hash = {}
    # If model is hash, use it.
    # Transform all values to strings.
    if model.is_a? Hash
      model.each do |k,v|
        if [Date, Time, DateTime].include? v.class
          attr_hash[k] = v.strftime("%d/%b/%Y %H:%M:%S")
        else
          attr_hash[k] = v.to_s
        end
      end
    else
      model.to_map.each do |k,v|
        if [Date, Time, DateTime].include? v.class
          attr_hash[k] = v.strftime("%d/%b/%Y %H:%M:%S")
        else
          attr_hash[k] = v.to_s
        end
      end
    end
    attr_hash
  end

  # Get the edi out destination.
  #
  # Raises an EdiDestinationError if unable to find a destination for the proposal.
  def self.get_edi_out_destinations( flow_type, model, options )
    edi_out_destinations, org_err, hub_err = EdiOutDestination.find_for_flow_and_model( flow_type.downcase, model, options )
    if edi_out_destinations && edi_out_destinations.any? {|a| a.nil? }
      raise EdiDestinationError, "This EDI proposal cannot be created: Unable to derive the EDI destination. FLOW: #{flow_type}. ORG: #{org_err}. HUB: #{hub_err}."
    end
    edi_out_destinations
  end

  # Is there a queued proposal with matching flow_type and record_id?
  def self.has_queued_proposal_for(flow_type, id)
    EdiOutProposal.exists?(['flow_type = ? AND record_id = ?', flow_type.downcase, id])
  end

  # Run a joiner for an EDI flow type and return the output.
  def self.run_joiner_for(flow_type)
    configs = YAML::load(File.read(EdiHelper::APP_ROOT + '/edi/config/config.yml'))
    cmd = configs['joiner_commands'][flow_type.upcase]

    return "<h2>EDI joiner</h2>\n<h3>Result:</h3>\n<p>There is no joiner defined for \"#{flow_type.upcase}\".</p>" if cmd.nil?

    run_res = `#{cmd}`

    ar        = run_res.split "\n"
    no_files  = 0
    combining = []
    created   = []
    is_ok     = false
    no_work   = false

    ar.each do |l|
      if l =~ /Joining\s(\d+)\sfiles/
        no_files = $1.to_i # capture group
      end
      if l =~ /Combining\s(.+)\.\.\./
        combining << File.basename($1)
      end
      if l =~ /created file\s(.+)\sin/
        created << File.basename($1)
      end
      if l =~ /Joining complete\./
        is_ok = true
      end
      if l =~ /No #{flow_type.upcase} files to process/
        no_work = true
      end
    end

    show_res = %Q|<p><a href="#" onclick="jQuery('#full_res_#{flow_type}').toggle();return false" style="text-decoration: none; color: #333;">Full Output &#10162;</a></p><pre id='full_res_#{flow_type}' style='display:none'>#{run_res.gsub("\n", "<br />")}</pre>|

    s = "<h2>EDI joiner was run</h2>\n<h3>Result:</h3>\n"
    if is_ok
      s << "<p>Join complete. #{no_files} file#{no_files == 1 ? ' was' : 's were'} joined.</p><p>Joined file:<ul>"
      created.each {|f| s << "<li><strong>#{f}</strong></p>" }
      s << "</ul></p><p>Combined files:<ul>"
      combining.each {|f| s << "<li>#{f}</p>" }
      s << "</ul></p>#{show_res}"
    elsif no_work
      s << "<p>There are no files to join.</p>#{show_res}"
    else
      s << %Q|<p><strong>Join failed. The full output is shown below:</strong></p>\n#{show_res.sub('display:none', '')}|
    end

    s
  end

end

