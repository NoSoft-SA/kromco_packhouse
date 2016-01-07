class MffaPre < RecordPadder


  #override base class method
   def required_record_length(flow_type, record_type, current_length, must_have_size=false)
     required_record_length_for_mf(flow_type,record_type,current_length,must_have_size)
   end



end

