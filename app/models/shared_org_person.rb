# Include in a model that belongs_to PartiesRole.
# Allows you to create a party, party_role and organisation/person at the same time
# as creating an instance of the model.
#
# Also delete them together.
module SharedOrgPerson
  attr_accessor :organisation_name,:party_type_name, :first_name, :last_name


  def party_is_org
    self.party_type_name == Party::ORGANIZATION
  end

  def org_and_person_names_valid?
    self.organisation_name.strip!
    self.first_name.strip!
    self.last_name.strip!

    party_is_valid = true

    if party_is_org
      if self.organisation_name.blank?
        self.errors.add(:organisation_name, 'can not be blank')
        party_is_valid = false
      end
    else
      if self.first_name.blank? || self.last_name.blank?
        self.errors.add(:first_name, 'can not be blank') if self.first_name.blank?
        self.errors.add(:last_name, 'can not be blank') if self.last_name.blank?
        party_is_valid = false
      end
    end
    party_is_valid
  end

  def save_with_party_role( role_name )
    ActiveRecord::Base.transaction do
      # Find or create person/org.
      if party_is_org
        org = Organization.find_by_short_description(self.organisation_name)
        if org.nil?
          org = Organization.create!({:short_description => self.organisation_name, :medium_description => self.organisation_name})
        end
        party_name = self.organisation_name
      else
        person = Person.find_by_first_name_and_last_name(self.first_name, self.last_name)
        if person.nil?
          person = Person.create!({:first_name => self.first_name, :last_name => self.last_name})
        end
        party_name = [self.first_name, self.last_name].join('_')
      end

      # Find/create PartyRole.
      parties_role = PartiesRole.find_by_party_name_and_party_type_name_and_role_name(party_name, self.party_type_name, role_name)
      if parties_role.nil?
        parties_role = PartiesRole.create!({:party_type_name => self.party_type_name,
                                            :party_name      => party_name,
                                            :role_name       => role_name })
      end

      self.parties_role_id = parties_role.id
      self.save!
    end
  end

  def delete_with_party_role
    ActiveRecord::Base.transaction do
      parties_role = self.parties_role
      party        = parties_role.party
      no_roles     = party.parties_roles.count

      self.destroy
      parties_role.destroy

      if no_roles == 1
        if party.party_type_name == Party::ORGANIZATION
          Organization.find(:first, :conditions => ['party_id = ?', party.id]).destroy
        else
          Person.find(:first, :conditions => ['party_id = ?', party.id]).destroy
          party.destroy
        end
      end
    end
  end

  # Set the virtual attributes from Org/Person.
  def populate_virtual_attrs
    parties_role         = PartiesRole.find(self.parties_role_id)
    self.party_type_name = parties_role.party_type_name

    if Party::ORGANIZATION == parties_role.party_type_name
      self.organisation_name = parties_role.party_name
    else
      person = Person.find_by_party_id(parties_role.party_id)
      self.first_name = person.first_name
      self.last_name  = person.last_name
    end
    parties_role
  end

end
