class EdiOutProcessHistory < ActiveRecord::Base 

  belongs_to :edi_out_proposal

  # Create a history record from an EdiOutProposal record.
  def self.log_history_from( edi_out_proposal, starting_at, ending_at, filename, in_memory=false)
    self.create!( :process_started_at   => starting_at,
                  :process_completed_at => ending_at,
                  :record_map           => edi_out_proposal.record_map,
                  :record_id            => edi_out_proposal.record_id,
                  :flow_type            => edi_out_proposal.flow_type,
                  :process_attempts     => edi_out_proposal.process_attempts,
                  :edi_out_filename     => filename,
                  :out_destination_dir  => edi_out_proposal.out_destination_dir,
                  :transfer_mechanism   => edi_out_proposal.transfer_mechanism,
                  :organization_code    => edi_out_proposal.organization_code,
                  :hub_address          => edi_out_proposal.hub_address,
                  :edi_out_proposal_id  => edi_out_proposal.id
                )
    edi_out_proposal.destroy unless in_memory
  end

end

