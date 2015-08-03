module ModelHelper

class Validations


  def Validations.validate_combos(combos,model,no_error_display = nil,no_zero = nil)
    
    err_count = 0
    
    combos.each do |combo|
       combo.each do |field,value|
###          puts value.to_s.upcase
          if value == nil||value.to_s == "<empty>"||value.to_s.strip() == ""||value.to_s.upcase.index("SELECT")!= nil||(no_zero && value == 0)||(value.to_s == '0' && field.to_s.index("_id"))
             
             eval "model." + field.to_s + " = nil"
             model.errors.add(field.to_s," : You must select a value ") if !no_error_display
             err_count += 1
             
          end
      end
    
    end
    
    return err_count == 0
 
  end


end


end
