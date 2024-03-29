class MesControlFile < ActiveRecord::Base

  CARTON = 1
  BIN = 2
  PALLET = 3
  BIN_TICKET = 4
  DEPOT_INTAKE = 5
  JOB = 6
  PRODUCTION_INTAKE = 7
  ORDER = 8
  LOAD = 9
  BIN_ORDER =30

  # EDI Out flow types:
  EDI_PS = 10
  EDI_PO = 11
  EDI_PI = 12
  EDI_PM = 13
  EDI_MT = 14
  EDI_PF = 18
  EDI_TI = 19
  INTAKE_DELIVERY_NUMBER = 15
  RMT_BIN_TRIP = 26
  ASSET_TRANS_NUM = 27
  QC_INSPECTION      = 28
  QC_INSPECTION_TEST = 29

  def MesControlFile.next_seq(object_type)
    
     kind = case object_type
         when 1 then "CARTON"
         when 2 then "REBIN"
         when 3 then "PALLET"
         else
          raise "unknown mes_control file type: " + object_type.to_s 
       end
    
    begin
     RwRun.get_object_nums(kind,1)
    rescue
     raise "A new mes control number for type: " + object_type.to_s + " could not be obtained. Reported exception: " + $!
    end
     
  end
 

  def MesControlFile.next_seq_web(object_type,batch_size = nil)
   query = "SELECT max(sequence_number)as maxval
           FROM
           public.mes_control_files where 
           (object_type = '#{object_type}')"
           
   val = connection.select_one(query)
   seq = MesControlFile.find_by_object_type_and_sequence_number(object_type,val["maxval"])
   if ! batch_size
     if seq.sequence_number.nil?
       seq.sequence_number = 1
     else
       seq.sequence_number += 1
     end
   else
     seq.sequence_number += batch_size
   end
   
#   seq.update
   seq.save
   
   if val["maxval"]== nil
     return 1
   else
    return seq.sequence_number
   end
  end

  def MesControlFile.next_org_seq_web(org_name,role_name)  
    seq = PartiesRole.find_by_party_name_and_role_name(org_name,role_name)
    if(!seq.sequence_number)
      return nil
    else
      seq.sequence_number += 1
    end

    seq.update
    return seq.sequence_number
  end  

  # Get the next sequence number for an EDI flow.
  # These sequence numbers go from 1 to 999 and then start at 1 again.
  def MesControlFile.next_seq_edi(object_type)

    unless [EDI_PS, EDI_PO, EDI_PI, EDI_PM, EDI_MT, EDI_PF,
            EDI_TI].include? object_type
      raise "unknown EDI mes_control file type: #{object_type.to_s}"
    end

    query = "SELECT max(sequence_number)as maxval
           FROM
           public.mes_control_files where 
           (object_type = '#{object_type}')"

     val = connection.select_one(query)
     seq = MesControlFile.find_by_object_type_and_sequence_number(object_type,val["maxval"])
     if seq.sequence_number.nil?
       seq.sequence_number = 1
     else
       seq.sequence_number += 1
     end
     # Wrap around if sequence number is too big:
     seq.sequence_number = 1 if seq.sequence_number > 999

     seq.save

     seq.sequence_number
  end

  # Rollback the sequence number for an EDI flow.
  # Raises an error if the number is not what was expected.
  def MesControlFile.prev_seq_edi(object_type, seq_no)

    unless [EDI_PS, EDI_PO, EDI_PI, EDI_PM, EDI_MT, EDI_PF,
            EDI_TI].include? object_type
      raise "unknown EDI mes_control file type: #{object_type.to_s}"
    end

    # query = "SELECT max(sequence_number)as maxval
    #        FROM
    #        public.mes_control_files where 
    #        (object_type = '#{object_type}')"

    #  val = connection.select_one(query)
    #  seq = MesControlFile.find_by_object_type_and_sequence_number(object_type,val["maxval"])
     seq = MesControlFile.find_by_object_type(object_type)
     if seq.sequence_number != seq_no
       raise "Cannot rollback EDI sequence number, the sequence has moved forward."
     else
       seq.sequence_number -= 1
     end
     # Wrap back around if sequence number is too small:
     seq.sequence_number = 999 if seq.sequence_number < 1

     seq.save

     seq.sequence_number
  end

end
