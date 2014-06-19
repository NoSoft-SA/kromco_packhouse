class AffectedObjectType < ActiveRecord::Base 
	
  validates_uniqueness_of  :affected_object_type_name
 
def self.get_all_system_names

	system_names = Subsystem.find_by_sql('select distinct system_name from subsystems').map{|g|[g.system_name]}
end



def self.get_all_subsystem_names

	subsystem_names = Subsystem.find_by_sql('select distinct subsystem_name from subsystems').map{|g|[g.subsystem_name]}
end



def self.subsystem_names_for_system_name(system_name)

	subsystem_names = Subsystem.find_by_sql("Select distinct subsystem_name from subsystems where system_name = '#{system_name}'").map{|g|[g.subsystem_name]}

	subsystem_names.unshift("<empty>")
 end






end
