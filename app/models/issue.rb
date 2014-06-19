class Issue < ActiveRecord::Base 
	
#	===========================
# 	Association declarations:
#	===========================
 
 
	belongs_to :subsystem
	belongs_to :ticket
	belongs_to :affected_object
	
	has_many :todos
	has_many :issue_tracks, :dependent => :destroy
 
#	============================
#	 Validations declarations:
#	============================
	validates_presence_of :issue_type
	validates_presence_of :description
	validates_presence_of :estimated_complete_date
	validates_presence_of :affected_resources
	
	validates_numericality_of :estimated_effort
#	=====================
#	 Complex validations:
#	=====================
  
  
  def fields_not_to_clean
    ["description"]
  end
  
  def before_update
     old_record = Issue.find(self.id)
     if old_record.status != self.status
       issue_track = IssueTrack.new
       self.export_attributes(issue_track,true)
       issue_track.issue = self
       issue_track.create
     end
     
  end
  
  def after_create
       issue_track = IssueTrack.new
       self.export_attributes(issue_track,true)
       issue_track.issue = self
       issue_track.create
  
  end

def validate 
#	first check whether combo fields have been selected
	 is_valid = true
	 if is_valid
		 is_valid = ModelHelper::Validations.validate_combos([{:project_name => self.project_name},{:ticket_name => self.ticket_name}],self) 
	end
	
	if is_valid
		 is_valid = ModelHelper::Validations.validate_combos([{:issue_type => self.issue_type}],self) 
	end
	
	#now check whether fk combos combine to form valid foreign keys
	 if is_valid
		 is_valid = set_ticket
	 end
	 if is_valid
		 is_valid = ModelHelper::Validations.validate_combos([{:system_name => self.system_name},{:subsystem_name => self.subsystem_name}],self) 
	end
	#now check whether fk combos combine to form valid foreign keys
	 if is_valid
		 is_valid = set_subsystem
	 end
	 if is_valid
		 is_valid = ModelHelper::Validations.validate_combos([{:system_name => self.system_name},{:subsystem_name => self.subsystem_name},{:affected_object_type_name => self.affected_object_type_name},{:affected_object_name => self.affected_object_name}],self) 
	end
	#now check whether fk combos combine to form valid foreign keys
	 if is_valid
		 is_valid = set_affected_object
	 end
	#validates uniqueness for this record
	 if self.new_record? && is_valid
		 validate_uniqueness
	 end
end

def validate_uniqueness
	 exists = Issue.find_by_project_name_and_ticket_name_and_issue_type_and_status_and_system_name_and_subsystem_name_and_affected_object_type_name_and_affected_object_name_and_description(self.project_name,self.ticket_name,self.issue_type,self.status,self.system_name,self.subsystem_name,self.affected_object_type_name,self.affected_object_name,self.description)
	 if exists != nil 
		errors.add_to_base("There already exists a record with the combined values of fields: 'project_name' and 'ticket_name' and 'issue_type' and 'status' and 'system_name' and 'subsystem_name' and 'affected_object_type_name' and 'affected_object_name' and 'assigned_to' ")
	end
end 
#	===========================
#	 foreign key validations:
#	===========================
def set_subsystem

	subsystem = Subsystem.find_by_system_name_and_subsystem_name(self.system_name,self.subsystem_name)
	 if subsystem != nil 
		 self.subsystem = subsystem
		 return true
	 else
		errors.add_to_base("combination of: 'system_name' and 'subsystem_name'  is invalid- it must be unique")
		 return false
	end
end
 
def set_ticket

	ticket = Ticket.find_by_project_name_and_ticket_name(self.project_name,self.ticket_name)
	 if ticket != nil 
		 self.ticket = ticket
		 return true
	 else
		errors.add_to_base("combination of: 'project_name' and 'ticket_name'  is invalid- it must be unique")
		 return false
	end
end
 
def set_affected_object

	affected_object = AffectedObject.find_by_system_name_and_subsystem_name_and_affected_object_type_name_and_affected_object_name(self.system_name,self.subsystem_name,self.affected_object_type_name,self.affected_object_name)
	 if affected_object != nil 
		 self.affected_object = affected_object
		 return true
	 else
		errors.add_to_base("combination of: 'system_name' and 'subsystem_name' and 'affected_object_type_name' and 'affected_object_name'  is invalid- it must be unique")
		 return false
	end
end
 
#	===========================
#	 lookup methods:
#	===========================
#	------------------------------------------------------------------------------------------
#	Lookup methods for the foreign composite key of id field: subsystem_id
#	------------------------------------------------------------------------------------------
 
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



#	------------------------------------------------------------------------------------------
#	Lookup methods for the foreign composite key of id field: ticket_id
#	------------------------------------------------------------------------------------------
 
def self.get_all_project_names

	project_names = Ticket.find_by_sql('select distinct project_name from tickets').map{|g|[g.project_name]}
end



def self.get_all_ticket_names

	ticket_names = Ticket.find_by_sql('select distinct ticket_name from tickets').map{|g|[g.ticket_name]}
end



def self.ticket_names_for_project_name(project_name)

	ticket_names = Ticket.find_by_sql("Select distinct ticket_name from tickets where project_name = '#{project_name}'").map{|g|[g.ticket_name]}

	ticket_names.unshift("<empty>")
 end



#	------------------------------------------------------------------------------------------
#	Lookup methods for the foreign composite key of id field: affected_object_id
#	------------------------------------------------------------------------------------------
 
def self.get_all_system_names

	system_names = AffectedObject.find_by_sql('select distinct system_name from affected_objects').map{|g|[g.system_name]}
end



def self.get_all_subsystem_names

	subsystem_names = AffectedObject.find_by_sql('select distinct subsystem_name from affected_objects').map{|g|[g.subsystem_name]}
end



def self.subsystem_names_for_system_name(system_name)

	subsystem_names = AffectedObject.find_by_sql("Select distinct subsystem_name from affected_objects where system_name = '#{system_name}'").map{|g|[g.subsystem_name]}

	subsystem_names.unshift("<empty>")
 end



def self.get_all_affected_object_type_names

	affected_object_type_names = AffectedObject.find_by_sql('select distinct affected_object_type_name from affected_objects').map{|g|[g.affected_object_type_name]}
end



def self.affected_object_type_names_for_subsystem_name_and_system_name(subsystem_name, system_name)

	affected_object_type_names = AffectedObject.find_by_sql("Select distinct affected_object_type_name from affected_objects where subsystem_name = '#{subsystem_name}' and system_name = '#{system_name}'").map{|g|[g.affected_object_type_name]}

	affected_object_type_names.unshift("<empty>")
 end



def self.get_all_affected_object_names

	affected_object_names = AffectedObject.find_by_sql('select distinct affected_object_name from affected_objects').map{|g|[g.affected_object_name]}
end



def self.affected_object_names_for_affected_object_type_name_and_subsystem_name_and_system_name(affected_object_type_name, subsystem_name, system_name)

	affected_object_names = AffectedObject.find_by_sql("Select distinct affected_object_name from affected_objects where affected_object_type_name = '#{affected_object_type_name}' and subsystem_name = '#{subsystem_name}' and system_name = '#{system_name}'").map{|g|[g.affected_object_name]}

	affected_object_names.unshift("<empty>")
 end






end
