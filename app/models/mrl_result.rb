class MrlResult < ActiveRecord::Base 

#	===========================
# 	Association declarations:
#	===========================
 
  attr_accessor :farm_code, :remark1_ptlocation, :label_printed
 

	belongs_to :spray_program_result
 
#	============================
#	 Validations declarations:
#	============================
  validates_presence_of :mrl_result_type_code
	validates_presence_of :mrl_result
	validates_numericality_of :sequence_number
#	=====================
#	 Complex validations:
#	=====================
def validate 
#	first check whether combo fields have been selected
	 is_valid = true
	 if is_valid
		 #is_valid = ModelHelper::Validations.validate_combos([{:commodity_code => self.commodity_code}],self) 
	end
	#now check whether fk combos combine to form valid foreign keys
	 if is_valid
		 #is_valid = set_spray_program_result
	 end
end

#	===========================
#	 foreign key validations:
#	===========================
def set_spray_program_result

	spray_program_result = SprayProgramResult.find_by_commodity_code(self.commodity_code)
	 if spray_program_result != nil 
		 self.spray_program_result = spray_program_result
		 return true
	 else
		errors.add_to_base("value of field: 'commodity_code' is invalid- it must be unique")
		 return false
	end
end
 
#	===========================
#	 lookup methods:
#	===========================


#=======================================
#  mrl printing
#======================================

def print_label(http_conn)
    begin
      data = build_mrl_label_data
      print_instruction = build_print_instruction(data)
      
      puts "Print Instruction: " + print_instruction
      
      self.update_attribute(:mrl_label_text, print_instruction)
      http_conn.get("/" + print_instruction,nil)
      puts "mrl label printed"
      
      puts "Instruction has been returned!"
      return print_instruction
    rescue
        self.destroy if self.mrl_label_text!= "null" && (self.mrl_result==nil || self.mrl_result=="")
       raise "Label could not be printed, Reason: " + $!
    end
end

def build_mrl_label_data
    data = Hash.new
    
    date = Time.now.strftime("%d/%m/%Y")
    sample_no = self.sample_no
    producer_no = self.spray_program_result.grower_commitment.farm.remark1_ptlocation
    orchard = self.orchard_code
    #farm_record = self.spray_program_result.grower_commitment.farm
    #delivery_record = Delivery.find_by_farm_id(farm_record.id)
    cultivar = self.spray_program_result.rmt_variety.rmt_variety_code
    test_type = "LCMSMS"
    
    data.store("F1", date)
    data.store("F2", sample_no)
    data.store("F3", producer_no)
    data.store("F4", orchard)
    data.store("F5", cultivar)
    data.store("F6", test_type)
    
    return data
    
end

def build_print_instruction(label_data)
    label_instruction = "<ProductLabel Status=\"true\""
    label_instruction += " Code=\""
    label_instruction += "MRL" + "\" F0=\"" + "E2" + "\""
    
    for i in 1..label_data.length()
        key = "F" + i.to_s
        val = ""
        if label_data.has_key?(key)
            val = label_data[key].to_s
            field = key + "=\"" + val +"\""
            label_instruction += field + " "
        end
    end
    label_instruction += "Msg=\"OK\" />"
    puts label_instruction
    return label_instruction
    
end

def MrlResult.print_mrl_job(spray_program_result_id, mrl_result_type_code, puc_code, orchard_code, farm_code, rmt_variety_code, mrl_print_msg, user_name)
    begin
  
        #see if mrl_results record exists(for parent spray_program_result) with same mrl_result_type
        mrl_results_record = MrlResult.find_by_mrl_result_type_code_and_spray_program_result_id(mrl_result_type_code, spray_program_result_id)
        if mrl_results_record!= nil
            if mrl_results_record.mrl_label_text!=nil
              return mrl_print_msg += "mrl label has already been printed for the selected mrl_result_type"
            else
#              file_name = user_name + "_mrl_label_" + Time.now.strftime("%m_%d_%Y_%H_%M_%S") + ".bat"
#              file = File.new(file_name,"w")
#              file.puts "ruby \"app\\models\\mrl_label_printing.rb\"" + " " + mrl_results_record.id.to_s
#              file.close
#
#              result = eval "\`" + "\"" + file_name + "\"" + "\"`"
#              puts result.to_s
              puts "==================================="
              puts "======1. implement printing ======="
              puts "Globals.mrl_label_printer_name = " + Globals.mrl_label_printer_name.to_s
              puts "Globals.mrl_label_print_format = " + Globals.mrl_label_print_format
              mrl_result_print_command = MrlResultPrintCommand.new(Globals.mrl_label_printer_name,Globals.mrl_label_print_format,1)#Printer????....Num of labels????
              print = mrl_result_print_command.print(Time.now.strftime("%d/%m/%Y"),mrl_results_record.sample_no,mrl_results_record.spray_program_result.grower_commitment.farm.remark1_ptlocation,mrl_results_record.orchard_code,mrl_results_record.spray_program_result.rmt_variety.rmt_variety_code,"LCMSMS")
              puts "=================================== " + print.to_s
              mrl_results_record.update_attribute(:mrl_label_text,print)
              mrl_print_msg += "MRL Label has been printed for the selected mrl_result_type!"
              
#              File.delete file_name
              return mrl_print_msg
            end
        else
            @new_mrl_results_record = MrlResult.new
            @new_mrl_results_record.puc_code = puc_code #session[:new_delivery].puc_code
            @new_mrl_results_record.orchard_code = orchard_code #session[:new_delivery].orchard_code
            @new_mrl_results_record.mrl_result_type_code = mrl_result_type_code #session[:new_delivery].mrl_result_type
            #sequence_number calculation
            sequence_number = nil
            mrl_results_overall = MrlResult.find_by_sql("select * from mrl_results")
            if mrl_results_overall != nil
                mrl_results_seq = MrlResult.find_by_sql("select MAX(sequence_number) AS seq_num from mrl_results")
                sequence_number = mrl_results_seq[0].seq_num.to_i + 1
            else
                sequence_number = 1
                puts "HEREEEEEE!!!!"
            end
            @new_mrl_results_record.sequence_number = sequence_number
            @new_mrl_results_record.created_on = Time.now.strftime("%d/%m/%Y")
            sample_no = farm_code.to_s + "/" + rmt_variety_code.to_s + "/" + sequence_number.to_s
            @new_mrl_results_record.sample_no = sample_no
            @new_mrl_results_record.spray_program_result_id = spray_program_result_id
            #@new_mrl_results_record.mrl_result = ""
#            @new_mrl_results_record.mrl_label_text = nil
            @new_mrl_results_record.save
            puts "mrl results record saved"
            
#            file_name = user_name + "_mrl_label_" + Time.now.strftime("%m_%d_%Y_%H_%M_%S") + ".bat"
#            file = File.new(file_name,"w")
#            file.puts "ruby \"app\\models\\mrl_label_printing.rb\"" + " " + @new_mrl_results_record.id.to_s
#            file.close
#
#            result = eval "\`" + "\"" + file_name + "\"" + "\"`"
#            puts result.to_s
            puts "==================================="
            puts "======2. implement printing ======="
            mrl_result_print_command = MrlResultPrintCommand.new(Globals.mrl_label_printer_name,Globals.mrl_label_print_format,1)#Printer????....Num of labels????
            print = mrl_result_print_command.print(Time.now.strftime("%d/%m/%Y"),@new_mrl_results_record.sample_no,@new_mrl_results_record.spray_program_result.grower_commitment.farm.remark1_ptlocation,@new_mrl_results_record.orchard_code,@new_mrl_results_record.spray_program_result.rmt_variety.rmt_variety_code,"LCMSMS")
            puts "=================================== " + print.to_s
              
            mrl_print_msg += "MRL Label has been printed for the selected mrl_result_type!"
            
#            File.delete file_name
            return mrl_print_msg
        end  
    rescue
        raise "MRL Label could not be printed: " + $!
    end
end

#=======================================
#  end mrl printing
#======================================

#*************************************
# Henry
#************************************

def set_puc_code(id)
self.puc_code = GrowerCommitment.find_by_id(id).farm.remark1_ptlocation 
end

def set_farm_code(id)
 self.farm_code = GrowerCommitment.find_by_id(id).farm_code
 
end

def generate_sequence_number(id)
ids = id

  if MrlResult.find_by_sql("select max(sequence_number) as sequence_number from mrl_results where  spray_program_result_id = #{ids}   ") != nil
    max_sequence_number_arra = MrlResult.find_by_sql("select max(sequence_number) as sequence_number from mrl_results where  spray_program_result_id = #{ids} ")
    max_sequence_number = max_sequence_number_arra[0].sequence_number.to_i + 1

  else
    max_sequence_number = 1 
  end
  
  return max_sequence_number
end
def generate_sample_no (id)


    self.sample_no = self.farm_code.to_s+"/"+SprayProgramResult.find_by_id(id).rmt_variety_code+"/"+generate_sequence_number(id).to_s

end

end
