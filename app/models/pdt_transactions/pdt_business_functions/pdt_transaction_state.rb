#---------------------------------------------------------------
# HANS definition:
# This class represents a state that can exist for a transaction
# It implements the behaviour common to all pdt states, and thus
# the client developer will have to inherit from it to create
# states that are specific to their pdt transactions 
#---------------------------------------------------------------
class PDTTransactionState
  attr_accessor  :pdt_screen_def,:parent
  
 def initialize(parent)
   @parent = parent
 end

  def authorise_scan(program, permission, user)
      begin
        user = User.find_by_user_name(user) if user.class.to_s == "String"

        query = "SELECT
                 public.security_permissions.id
                 FROM
                 public.security_groups_security_permissions
                 INNER JOIN public.security_groups ON (public.security_groups_security_permissions.security_group_id = public.security_groups.id)
                  INNER JOIN public.security_permissions ON (public.security_groups_security_permissions.security_permission_id = public.security_permissions.id)
                  INNER JOIN public.program_users ON (public.security_groups.id = public.program_users.security_group_id)
                  INNER JOIN public.programs ON (public.program_users.program_id = public.programs.id)
                  WHERE
                  (public.program_users.user_id = #{user.id}) AND
                  (public.security_permissions.security_permission = '#{permission}') AND
                  (public.programs.program_name = '#{program}')"

        @val  = User.connection.select_one(query)

        return @val != nil
      rescue
        puts "Authorisation exception: " + $!.to_s
        return false
      end
    end

 #protected
 # PdtTransaction's authorize is the default implementation
 # Overridable if really needed
 def authorise
   @parent.authorise
 end

 def friendly_name
   return self.parent.class.name + ":" + self.class.name
 end
#----------------------------------------------------------
# derived class can return a permission name
# to authorise the user against. If authorisation is needed
# derived class must override this method and return the
# name of the permission or return "yes"- in which case the
# program function_name is treated as the permission name
#----------------------------------------------------------
 def permission?()
    return nil 
 end
#----------------------------------------------------------

 #______________________
 # 4. AMENDMENT
 #______________________
 def can_redo
   true
 end
 
#----------------------------------------------------------
# used to check wether the request made to the pdt server
# is a screen submission or a menu selection.It this by
# examining the mode of the submitted pdt_acreen_def
#----------------------------------------------------------
#protected
  def is_screen_request
    if @pdt_screen_def.mode.to_s == PdtScreenDefinition.const_get("MENUSELECT").to_s
       return true
     else
       return false
     end
  end
#----------------------------------------------------------
 
##----------------------------------------------------------
## This method allows the client developer to pass in the
## values that are entered by the user and check if they 
## ae valid i.e. that they contains something
##----------------------------------------------------------
#  def is_valid_inputs?(input1,input2=nil,input3=nil)
#    input_array = Array.new
#    input_array.push(input1)
#    input_array.push(input2) if input2 != nil
#    input_array.push(input3) if input3 != nil
#    
#    for input in  input_array
#      if input.strip == "" || input == nil
#         return false
#      end
#    end
#    
#  end
##----------------------------------------------------------

#----------------------------------------------------------
# this method is used by the parent transaction to notify 
# the active state that the transaction has completed.The 
# state can override it and do what it needs to do on
# receipt of the notification
#----------------------------------------------------------
  def transaction_done()
    puts "........." + self.class.name + " has been notified"
  end
#----------------------------------------------------------
   
end