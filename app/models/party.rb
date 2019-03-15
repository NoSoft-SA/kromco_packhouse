class Party < ActiveRecord::Base

  attr_accessor :new_name, :new_first_name, :new_last_name # For renaming

  has_and_belongs_to_many :roles
  has_one :postal_address
  #has_and_belongs_to_many :groups
  has_many :parties_roles,:dependent => :destroy
  has_many :persons,:dependent => :destroy
  has_many :contact_methods_parties
  has_many :parties_postal_addresses


  ORGANIZATION = 'ORGANIZATION'
  PERSON       = 'PERSON'

  def self.get_party_role_id_for(party_name, role_name, party_type_name=ORGANIZATION)
    query = "SELECT public.parties_roles.id from public.parties_roles
             WHERE public.parties_roles.party_name = '#{Globals.sql_quotes(party_name)}'
             AND public.parties_roles.party_type_name = '#{party_type_name}'
             AND public.parties_roles.role_name = '#{role_name}'"
    parties = Party.find_by_sql(query)
    if parties.empty?
      raise MesScada::InfoError, "No party-role for Party: \"#{party_name}\" (#{party_type_name}), Role: \"#{role_name}\"."
    elsif parties.size > 1
      raise MesScada::InfoError, "More than one party-role for Party: \"#{party_name}\" (#{party_type_name}), Role: \"#{role_name}\". Expecting only one."
    else
      parties.first.id
    end
  end

  def formatted_contact_info
    s = ['<pre>']
    self.contact_methods_parties.each do |contact_method|
      s << "#{contact_method.contact_method_type_code.ljust(10)}: #{contact_method.contact_method_code}"
    end
    self.parties_postal_addresses.each do |postal_address|
      s << postal_address.formatted_address
    end
    s << '</pre>'
    s.join("\n")
  end

  def self.rename_party(from_name, params)
    to_name        = params[:new_name]
    new_first_name = params[:new_first_name]
    new_last_name  = params[:new_last_name]

    # validate names - from exists, to does not exist & is not blank...
    party = Party.find_by_party_name(from_name)
    raise MesScada::InfoError, "Party \"#{Globals.sql_quotes(from_name)}\" does not exist." if party.nil?
    party_id = party.id

    raise MesScada::InfoError, "\"#{Globals.sql_quotes(to_name)}\" is not a valid name for a party." if to_name.blank?
    new_party = Party.find_by_party_name(to_name)
    raise MesScada::InfoError, "Party \"#{Globals.sql_quotes(to_name)}\" already exists." unless new_party.nil? || new_party.id == party_id

    if new_last_name.nil?
      org_person_update = "UPDATE organizations SET short_description = '#{Globals.sql_quotes(to_name)}' WHERE party_id = #{party_id};"
    else
      raise MesScada::InfoError, "First and last names must be provided." if new_first_name.blank? || new_last_name.blank?
      org_person_update = "UPDATE people SET first_name = '#{Globals.sql_quotes(new_first_name)}', last_name = '#{Globals.sql_quotes(new_last_name)}' WHERE party_id = #{party_id};"
    end

    extras  = ''
    # Is this a farm?
    farm = PartiesRole.find_by_party_id_and_role_name(party_id, 'FARM')
    extras << "UPDATE farms SET party_name = '#{Globals.sql_quotes(to_name)}' WHERE party_name = '#{Globals.sql_quotes(from_name)}';\n" if farm
    # Is this a customer?
    # cust = PartiesRole.find_by_party_id_and_role_name(party_id, Customer::ROLE_NAME)
    # extras << "UPDATE customer_invoices SET customer = '#{Globals.sql_quotes(to_name)}' WHERE customer = '#{Globals.sql_quotes(from_name)}';\n" if cust

    # Is this a consignee?
    # cons = PartiesRole.find_by_party_id_and_role_name(party_id, 'CONSIGNEE')
    # extras << "UPDATE customer_invoices SET consignee = '#{Globals.sql_quotes(to_name)}' WHERE consignee = '#{Globals.sql_quotes(from_name)}';\n" if cons

    # Is this a supplier?
    # supp = PartiesRole.find_by_party_id_and_role_name(party_id, Supplier::ROLE_NAME)
    # extras << "UPDATE customer_invoices SET supplier = '#{Globals.sql_quotes(to_name)}' WHERE supplier = '#{Globals.sql_quotes(from_name)}';\n" if supp

    # Is this a final receiver?
    # fin_rec = PartiesRole.find_by_party_id_and_role_name(party_id, 'FINAL_RECEIVER')
    # extras << "UPDATE invoice_items SET final_receiver = '#{Globals.sql_quotes(to_name)}' WHERE final_receiver = '#{Globals.sql_quotes(from_name)}';\n" if fin_rec
    # extras << "UPDATE customer_invoices SET final_receiver = '#{Globals.sql_quotes(to_name)}' WHERE final_receiver = '#{Globals.sql_quotes(from_name)}';\n" if fin_rec

    Party.transaction do
      qry = <<-EOQ
      SET CONSTRAINTS ALL DEFERRED;
      UPDATE parties_roles            SET party_name = '#{Globals.sql_quotes(to_name)}' WHERE party_id = #{party_id};
      UPDATE parties_postal_addresses SET party_name = '#{Globals.sql_quotes(to_name)}' WHERE party_id = #{party_id};
      UPDATE contact_methods_parties  SET party_name = '#{Globals.sql_quotes(to_name)}' WHERE party_id = #{party_id};
      #{org_person_update}
      UPDATE parties                  SET party_name = '#{Globals.sql_quotes(to_name)}' WHERE id = #{party_id};
      #{extras}
      EOQ
      ActiveRecord::Base.connection.execute(qry)
    end
  end

  def Party.set_address_info(keys, values, change_only_for_org)
    if(keys['mobile'] && !values[keys['mobile']].to_s.strip.empty?)
      if(mobile_contact_party=get_contact_method('Mobile', 'ORGANIZATION', values[keys['org_name']]))
        if(!(mobile=ContactMethod.find(:first,:conditions=>"contact_method_code='#{values[keys['mobile']]}' and contact_method_type_code='Mobile'")))
          mobile = ContactMethod.new({:contact_method_code=>values[keys['mobile']], :contact_method_type_code=>'Mobile'})
          mobile.save!
        end
        mobile_contact_party.update_attributes({:contact_method_code=>values[keys['mobile']], :contact_method_id=>mobile.id})
      else
        if(!ContactMethod.find(:first,:conditions=>"contact_method_code='#{values[keys['mobile']]}' and contact_method_type_code='Mobile'"))
          mobile = ContactMethod.new({:contact_method_code=>values[keys['mobile']], :contact_method_type_code=>'Mobile'})
          mobile.save!
        end
        party = ContactMethodsParty.new({:party_type_name=>'ORGANIZATION', :party_name=>values[keys['org_name']],:contact_method_code=>values[keys['mobile']], :contact_method_type_code=>'Mobile',:from_date=>Time.now.to_date.to_formatted_s(:db),:thru_date=>Time.now.to_date.to_formatted_s(:db)})
        party.save!
      end
    end

    if(keys['email'] && !values[keys['email']].to_s.strip.empty?)
      if(email_contact_party=get_contact_method('E-mail', 'ORGANIZATION', values[keys['org_name']]))
        if(!(email=ContactMethod.find(:first,:conditions=>"contact_method_code='#{values[keys['email']]}' and contact_method_type_code='E-mail'")))
          email = ContactMethod.new({:contact_method_code=>values[keys['email']], :contact_method_type_code=>'E-mail'})
          email.save!
        end
        email_contact_party.update_attributes({:contact_method_code=>values[keys['email']], :contact_method_id=>email.id})
      else
        if(!ContactMethod.find(:first,:conditions=>"contact_method_code='#{values[keys['email']]}' and contact_method_type_code='E-mail'"))
          email = ContactMethod.new({:contact_method_code=>values[keys['email']], :contact_method_type_code=>'E-mail'})
          email.save!
        end
        party = ContactMethodsParty.new({:party_type_name=>'ORGANIZATION', :party_name=>values[keys['org_name']],:contact_method_code=>values[keys['email']], :contact_method_type_code=>'E-mail',:from_date=>Time.now.to_date.to_formatted_s(:db),:thru_date=>Time.now.to_date.to_formatted_s(:db)})
        party.save!
      end
    end

    # if((keys['city'] && !values[keys['city']].to_s.strip.empty?) && (keys['address1'] && !values[keys['address1']].to_s.strip.empty?) && (keys['address2'] && !values[keys['address2']].to_s.strip.empty?))
    if(postal_address_party=Party.get_party_postal_address(values[keys['org_name']], values[keys['postal_address_type_code']], 'ORGANIZATION'))
      if(!change_only_for_org)
        postal_address_party.postal_address.update_attributes({:city=>values[keys['city']],:address1=>values[keys['address1']],:address2=>values[keys['address2']], :postal_code=>values[keys['postal_code']]})
      else
        if(!PostalAddress.find(:first,:conditions=>"postal_address_type_code='#{values[keys['postal_address_type_code']]}' and city='#{values[keys['city']]}'"))
          postal_address = PostalAddress.new({:postal_address_type_code=>values[keys['postal_address_type_code']], :city=>values[keys['city']], :address1=>values[keys['address1']], :address2=>values[keys['address2']], :postal_code=>values[keys['postal_code']]})
          postal_address.save!
        end
      end
      postal_address_party.update_attributes({:city=>values[keys['city']],:address1=>values[keys['address1']],:address2=>values[keys['address2']]})
    else
      if(!PostalAddress.find(:first,:conditions=>"postal_address_type_code='#{values[keys['postal_address_type_code']]}' and city='#{values[keys['city']]}'"))
        postal_address = PostalAddress.new({:postal_address_type_code=>values[keys['postal_address_type_code']], :city=>values[keys['city']], :address1=>values[keys['address1']], :address2=>values[keys['address2']], :postal_code=>values[keys['postal_code']]})
        postal_address.save!
      end
      postal_address_party = PartiesPostalAddress.new({:postal_address_type_code=>values[keys['postal_address_type_code']], :city=>values[keys['city']], :address1=>values[keys['address1']], :address2=>values[keys['address2']],
                                                       :party_name=>values[keys['org_name']], :party_type_name=>'ORGANIZATION'})
      postal_address_party.save!
    end
    # end
  end

  def Party.get_contact_method(contact_method_type_code, party_type_name, party_name)
    ContactMethodsParty.find(:first, :select=>"contact_methods_parties.*", :conditions=>"contact_methods_parties.contact_method_type_code='#{contact_method_type_code}' and contact_methods_parties.party_type_name='#{party_type_name}' and contact_methods_parties.party_name='#{party_name}'",
                             :joins=>"join contact_methods c on contact_methods_parties.contact_method_id=c.id")
  end

  def Party.get_party_postal_address(party_name, postal_address_type_code, party_type_name)
    PartiesPostalAddress.find(:first, :select=>"parties_postal_addresses.*",
                              :conditions=>"a.postal_address_type_code='#{postal_address_type_code}' and parties_postal_addresses.party_type_name='#{party_type_name}' and parties_postal_addresses.party_name='#{party_name}'",
                              :joins=>"join postal_addresses a on a.id=parties_postal_addresses.postal_address_id")
  end


end
